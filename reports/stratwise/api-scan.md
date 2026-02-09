# 🛡️ API & Endpoint Security Audit — stratwise.ai

**Auditor:** Edward, 0xAudit  
**Date:** 2025-02-09  
**Target:** stratwise.ai (frontend) + api.stratwise.ai (backend API)  
**Stack:** Vite SPA (React) + FastAPI (Python) + Firebase Auth + Cloudflare CDN  

---

## Executive Summary

Обнаружено **3 CRITICAL**, **2 HIGH**, **3 MEDIUM**, **2 LOW** уязвимости. Наиболее критичные: полностью открытый OpenAPI/Swagger, публичный Prometheus metrics endpoint и wildcard CORS с credentials.

---

## 🔴 CRITICAL Findings

### C-01: OpenAPI Specification Publicly Accessible
- **CVSS:** 7.5 (High)
- **Severity:** CRITICAL
- **Endpoint:** `GET https://api.stratwise.ai/openapi.json`
- **Описание:** Полная OpenAPI 3.1.0 спецификация (284KB) доступна без аутентификации. Содержит ВСЕ API endpoints, модели данных, параметры запросов, схемы ответов, включая внутренние admin-эндпоинты (`/api/v1/api-keys/{uuid}/admin`, `/api/v1/metrics/*`, `/api/v1/webhooks/quicknode`).
- **Swagger UI:** `https://api.stratwise.ai/docs` — интерактивная документация
- **ReDoc:** `https://api.stratwise.ai/redoc` — полная документация
- **Impact:** Полная карта API для атакующего. Упрощает поиск уязвимостей, IDOR, privilege escalation.
- **Рекомендация:** Закрыть `/docs`, `/redoc`, `/openapi.json` для production. Использовать `if settings.DEBUG: app.include_router(docs_router)`.

### C-02: Prometheus Metrics Publicly Exposed
- **CVSS:** 7.5 (High)
- **Severity:** CRITICAL
- **Endpoint:** `GET https://api.stratwise.ai/metrics`
- **Описание:** Prometheus metrics endpoint (579KB) доступен без аутентификации. Раскрывает:
  - Все API endpoints и их использование (request counts, latency)
  - Внутренние endpoints не из OpenAPI: `/api/v1/webhooks/quicknode` (950K+ запросов), `/api/v1/metrics/users/with_active_balance`, `/api/v1/metrics/users/active_7d`, `/api/v1/metrics/revenue/commission_balance_total`
  - Объёмы трафика и паттерны использования
  - Информацию о производительности системы
- **Impact:** Reconnaissance goldmine. Позволяет понять масштаб системы, найти скрытые endpoints, спланировать DDoS.
- **Рекомендация:** Закрыть `/metrics` за аутентификацию или VPN. Использовать internal network only.

### C-03: Wildcard CORS with Credentials
- **CVSS:** 8.1 (High)
- **Severity:** CRITICAL
- **Endpoint:** Все API endpoints
- **Описание:** API отвечает `Access-Control-Allow-Origin: <любой origin>` в комбинации с `Access-Control-Allow-Credentials: true`. Проверено с `Origin: https://evil.com` — сервер рефлектит origin.
- **Headers:**
  ```
  access-control-allow-origin: https://evil.com
  access-control-allow-credentials: true
  access-control-allow-methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
  ```
- **Impact:** Позволяет любому вредоносному сайту делать authenticated запросы к API от имени пользователя (если используются cookies). CSRF через cross-origin requests.
- **Рекомендация:** Ограничить `Access-Control-Allow-Origin` до `https://stratwise.ai`. НЕ рефлектить произвольные origins с `credentials: true`.

---

## 🟠 HIGH Findings

### H-01: Invite Code Enumeration (No Rate Limiting)
- **CVSS:** 5.3 (Medium)
- **Severity:** HIGH
- **Endpoint:** `POST /api/v1/auth/validate-invite-code`
- **Описание:** Endpoint доступен без аутентификации и не имеет rate limiting. Возвращает чёткий ответ `{"is_valid":false,"code":"...","error":"Code not found"}`. Позволяет brute-force перебор invite кодов.
- **Impact:** Bypass invite-only registration, unauthorized access to platform.
- **Рекомендация:** Добавить rate limiting (5 req/min). Не раскрывать детали ошибки. Использовать длинные random коды.

### H-02: Firebase Configuration Exposed in Frontend Bundle
- **CVSS:** 5.3 (Medium)
- **Severity:** HIGH
- **Endpoint:** `/assets/index-BrVI2RJu.js`
- **Описание:** Firebase конфигурация в JS бандле:
  ```
  apiKey: "AIzaSyDBwQtdwkTdNB6ssp03zdd8t0t9MFBx3P4"
  authDomain: "auth.stratwise.ai"
  projectId: "stratwise-edaae"
  ```
- **Impact:** При неправильных Firebase Security Rules — прямой доступ к Firestore/Storage. Позволяет создание пользователей напрямую через Firebase Auth API.
- **Рекомендация:** Проверить Firebase Security Rules. Ограничить Firebase Auth providers. Включить App Check.

---

## 🟡 MEDIUM Findings

### M-01: Verbose Error Messages (Input Validation Details)
- **CVSS:** 4.3 (Medium)
- **Severity:** MEDIUM
- **Endpoint:** Все POST endpoints
- **Описание:** FastAPI возвращает детальные ошибки валидации Pydantic:
  ```json
  {"detail":[{"type":"missing","loc":["body","email"],"msg":"Field required","input":{}}]}
  {"detail":[{"type":"string_too_short","loc":["body","token"],"msg":"String should have at least 64 characters","input":"fake_token","ctx":{"min_length":64}}]}
  ```
- **Impact:** Раскрывает внутреннюю структуру моделей, типы полей, валидационные правила. Упрощает crafting payloads.
- **Рекомендация:** В production заменить детальные ошибки на generic: `{"error": "Invalid request"}`. Логировать детали server-side.

### M-02: Server Technology Fingerprinting
- **CVSS:** 3.7 (Low)
- **Severity:** MEDIUM
- **Headers:**
  ```
  server: cloudflare
  x-process-time: 0.0006
  x-request-id: 0c251b5e-923c-4407-bb65-d9d92be84cc8
  ```
- **Health endpoint:** `{"status":"healthy","service":"stratwise-auth-api","version":"0.1.0","environment":"production"}`
- **Impact:** Раскрывает: Cloudflare CDN, FastAPI backend, service name, version, environment. `x-process-time` может использоваться для timing attacks.
- **Рекомендация:** Убрать `x-process-time`, service name, version из health endpoint. Минимизировать information leakage.

### M-03: Missing Security Headers on API
- **CVSS:** 4.3 (Medium)
- **Severity:** MEDIUM
- **Описание:** API backend отсутствуют ключевые security headers:
  - ❌ `Strict-Transport-Security` (HSTS)
  - ❌ `Content-Security-Policy`
  - ❌ `X-Frame-Options`
  - ❌ `X-Content-Type-Options`
  - ❌ `Permissions-Policy`
- **Frontend** (stratwise.ai) имеет `x-content-type-options: nosniff` и `referrer-policy`, но также отсутствует HSTS.
- **Рекомендация:** Добавить все security headers. Включить HSTS с `max-age=31536000; includeSubDomains`.

---

## 🟢 LOW Findings

### L-01: Logout Without Authentication
- **CVSS:** 2.1 (Low)
- **Severity:** LOW
- **Endpoint:** `POST /api/v1/auth/logout`
- **Описание:** Endpoint возвращает `200 {"success":true,"message":"Logout successful"}` без аутентификации.
- **Impact:** Минимальный. Но позволяет определить наличие endpoint.
- **Рекомендация:** Требовать аутентификацию для logout или возвращать 401.

### L-02: GTM Tag Manager ID Exposed
- **CVSS:** 1.0 (Informational)
- **Severity:** LOW
- **Описание:** Google Tag Manager ID `GTM-P29T4RP7` в исходном коде. Нормально для frontend, но может быть использован для fingerprinting.
- **Рекомендация:** Информационный. Нет действий.

---

## ✅ Positive Findings

| Check | Result |
|-------|--------|
| Rate Limiting on Login | ✅ 429 после первого запроса (агрессивный rate limit) |
| Auth on Protected Endpoints | ✅ Все protected endpoints возвращают 403 |
| Webhook Signature Validation | ✅ QuickNode webhook требует signature headers |
| Delete User Auth | ✅ Требует аутентификацию |
| Path Traversal | ✅ Не уязвим (SPA catch-all) |
| SQL Injection | ✅ Не уязвим на проверенных endpoints |
| GraphQL | ❌ Не найден (не используется) |
| Source Maps | ✅ Не найдены |
| .env / .git | ✅ Не доступны на API backend |

---

## Architecture Notes

- **Frontend:** Vite React SPA на stratwise.ai. Catch-all routing — все пути возвращают index.html (200). Hosted on Cloudflare Pages.
- **Backend:** FastAPI (Python) на api.stratwise.ai. Behind Cloudflare proxy.
- **Auth:** Firebase Authentication + custom JWT token exchange
- **Manifest:** PWA manifest доступен (`/manifest.json`)
- **robots.txt:** Кастомный с AI content signals

---

## API Endpoint Map (from OpenAPI)

| Method | Endpoint | Auth Required |
|--------|----------|:---:|
| POST | /api/v1/auth/register | ✅ Firebase |
| POST | /api/v1/auth/login | ❌ |
| POST | /api/v1/auth/social | ✅ Firebase |
| POST | /api/v1/auth/refresh | 🔑 Cookie |
| POST | /api/v1/auth/logout | ❌ |
| POST | /api/v1/auth/verify-email | ✅ |
| POST | /api/v1/auth/validate-invite-code | ❌ |
| POST | /api/v1/auth/exchange-token | ❌ (token in body) |
| GET | /api/v1/users/me | ✅ |
| DELETE | /api/v1/users/me | ✅ |
| PATCH | /api/v1/users/profile | ✅ |
| POST/GET | /api/v1/api-keys/ | ✅ |
| GET | /api/v1/api-keys/{id}/admin | ✅ |
| POST/GET | /api/v1/bots/ | ✅ |
| POST/GET | /api/v1/deals/ | ✅ |
| POST/GET | /api/v1/orders/ | ✅ |
| GET | /api/v1/dashboard/* | ✅ |
| GET | /api/v1/notifications | ✅ |
| GET | /api/v1/billing/* | ✅ |
| GET | /api/v1/metrics/* | ✅ |
| POST | /api/v1/webhooks/quicknode | 🔑 Signature |
| GET | /health | ❌ |
| GET | /metrics | ❌ ⚠️ |
| GET | /docs | ❌ ⚠️ |
| GET | /redoc | ❌ ⚠️ |
| GET | /openapi.json | ❌ ⚠️ |

---

## Summary & Priority Actions

| # | Finding | Severity | CVSS | Fix Priority |
|---|---------|----------|------|:---:|
| C-01 | OpenAPI/Swagger Publicly Accessible | CRITICAL | 7.5 | 🔴 Immediate |
| C-02 | Prometheus Metrics Exposed | CRITICAL | 7.5 | 🔴 Immediate |
| C-03 | Wildcard CORS with Credentials | CRITICAL | 8.1 | 🔴 Immediate |
| H-01 | Invite Code Enumeration | HIGH | 5.3 | 🟠 This week |
| H-02 | Firebase Config Exposed | HIGH | 5.3 | 🟠 This week |
| M-01 | Verbose Error Messages | MEDIUM | 4.3 | 🟡 This sprint |
| M-02 | Server Fingerprinting | MEDIUM | 3.7 | 🟡 This sprint |
| M-03 | Missing Security Headers | MEDIUM | 4.3 | 🟡 This sprint |
| L-01 | Logout Without Auth | LOW | 2.1 | 🟢 Backlog |
| L-02 | GTM ID Exposed | LOW | 1.0 | 🟢 Informational |

---

*Report generated by 0xAudit automated security scanner. Manual verification recommended for all findings.*
