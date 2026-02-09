# 🛡️ 0xAudit Security Report: stratwise.ai

**Date:** 2026-02-09  
**Auditor:** Edward, 0xAudit  
**Classification:** CONFIDENTIAL  

---

## Executive Summary

Проведён комплексный аудит безопасности платформы **stratwise.ai** — AI-powered крипто-трейдинговой платформы. Аудит включал сканирование веб-приложения, API, инфраструктуры, OWASP Top 10 анализ и тестирование с аутентификацией.

Обнаружено **5 критических**, **6 высоких**, **10 средних** и **6 низких/информационных** уязвимостей. Наиболее опасные находки:

1. **IDOR** — доступ к торговым ботам и стратегиям других пользователей
2. **Wildcard CORS с credentials** — возможность полного захвата аккаунта через вредоносный сайт
3. **Слабая парольная политика с утечкой PII** — принимаются тривиальные пароли, логин возвращает избыточные данные
4. **Публично доступная OpenAPI/Swagger документация** — полная карта API для атакующего
5. **Публичный Prometheus /metrics** — раскрытие внутренних метрик и скрытых эндпоинтов

**Для финансовой платформы**, управляющей реальными API-ключами бирж и средствами пользователей, текущий уровень безопасности **неприемлем**. Требуется немедленное устранение критических уязвимостей.

---

## Overall Risk Rating

# 🔴 HIGH (Высокий)

| Severity | Count |
|----------|-------|
| 🔴 Critical | 5 |
| 🟠 High | 6 |
| 🟡 Medium | 10 |
| 🟢 Low / ℹ️ Info | 6 |
| **Итого** | **27** |

---

## Findings Summary Table

| # | Finding | Severity | CVSS | Category | Status |
|---|---------|----------|------|----------|--------|
| 1 | IDOR — доступ к ботам и стратегиям других пользователей | 🔴 Critical | 8.6 | Access Control | ❌ Open |
| 2 | Wildcard CORS с credentials (рефлекция любого origin) | 🔴 Critical | 9.1 | Access Control | ❌ Open |
| 3 | Слабая парольная политика + утечка PII при логине | 🔴 Critical | 8.6 | Authentication | ❌ Open |
| 4 | OpenAPI/Swagger/ReDoc публично доступны | 🔴 Critical | 7.5 | Misconfiguration | ❌ Open |
| 5 | Prometheus /metrics публично доступен | 🔴 Critical | 7.5 | Misconfiguration | ❌ Open |
| 6 | Exchange API-ключи раскрыты в ответах API | 🟠 High | 7.5 | Data Exposure | ❌ Open |
| 7 | Отсутствие DMARC записи | 🟠 High | 7.4 | Email Security | ❌ Open |
| 8 | Отсутствие DKIM записей | 🟠 High | 7.4 | Email Security | ❌ Open |
| 9 | Отсутствие критических security headers (CSP, HSTS) | 🟠 High | 7.1 | Misconfiguration | ❌ Open |
| 10 | Source maps доступны + отсутствие SRI | 🟠 High | 6.8 | Integrity | ❌ Open |
| 11 | JWT не инвалидируется после logout | 🟠 High | 6.5 | Session Management | ❌ Open |
| 12 | Transfer token передаётся через URL-параметр | 🟡 Medium | 6.5 | Authentication | ❌ Open |
| 13 | Rate limiting недостаточен (9 попыток до блокировки) | 🟡 Medium | 5.9 | Authentication | ❌ Open |
| 14 | Grafana публично доступна (grafana.stratwise.ai) | 🟡 Medium | 5.3 | Misconfiguration | ❌ Open |
| 15 | Firebase конфигурация раскрыта в JS-бандле | 🟡 Medium | 5.3 | Misconfiguration | ❌ Open |
| 16 | Invite code enumeration (нет rate limiting) | 🟡 Medium | 5.3 | Authentication | ❌ Open |
| 17 | Дублирующиеся/конфликтующие SPF записи | 🟡 Medium | 5.3 | Email Security | ❌ Open |
| 18 | Раскрытие информации через API (version, service name) | 🟡 Medium | 5.3 | Information Disclosure | ❌ Open |
| 19 | JWT использует алгоритм HS256 | 🟡 Medium | 4.7 | Cryptography | ❌ Open |
| 20 | Verbose error messages (детали валидации Pydantic) | 🟡 Medium | 4.3 | Information Disclosure | ❌ Open |
| 21 | Email verification не требуется для финансовых операций | 🟡 Medium | 4.3 | Authentication | ❌ Open |
| 22 | Избыточные данные в ответах API (firebase_uid, derivation_index) | 🟡 Medium | 4.3 | Data Exposure | ❌ Open |
| 23 | QA API публично доступен (qa.api.stratwise.ai) | 🟡 Medium | 4.3 | Misconfiguration | ❌ Open |
| 24 | SPF использует ~all вместо -all | 🟢 Low | 3.7 | Email Security | ❌ Open |
| 25 | X-Frame-Options отсутствует (clickjacking) | 🟢 Low | 4.3 | Headers | ❌ Open |
| 26 | Permissions-Policy отсутствует | 🟢 Low | 3.1 | Headers | ❌ Open |
| 27 | GTM ID, социальные ссылки раскрыты | ℹ️ Info | — | OSINT | ℹ️ Noted |

---

## Critical Findings

### CRIT-01: IDOR — Доступ к торговым ботам и стратегиям других пользователей

| Параметр | Значение |
|----------|----------|
| **CVSS 3.1** | 8.6 (AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:N/A:N) |
| **CWE** | CWE-639: Authorization Bypass Through User-Controlled Key |
| **OWASP** | A01 Broken Access Control |
| **Эндпоинт** | `GET /api/v1/bots/`, `GET /api/v1/bots/{bot_id}/configs/active` |

**Описание:**  
Эндпоинт `/api/v1/bots/` возвращает ботов **ВСЕХ пользователей** платформы, а не только текущего. Любой аутентифицированный пользователь может получить полную информацию о чужих торговых стратегиях.

**PoC:**
```
GET /api/v1/bots/ (авторизован как user 3dadaf2c-...)
→ Возвращает бот 9d5c7962-... принадлежащий user d943368c-... (ЧУЖОЙ пользователь)
→ Доступны: trading pair, exchange, investment amounts, ML model configs, stop-loss, take-profit, grid settings
```

**Импакт:** Прямая утечка конкурентной/финансовой информации. На торговой платформе это критически опасно — атакующий может скопировать стратегии или использовать информацию для market manipulation.

**Рекомендация:**
- Добавить `WHERE user_id = current_user.id` во все запросы к ботам
- Внедрить row-level security на уровне БД
- Провести аудит ВСЕХ эндпоинтов на аналогичные IDOR

---

### CRIT-02: Wildcard CORS с Credentials — Захват аккаунта

| Параметр | Значение |
|----------|----------|
| **CVSS 3.1** | 9.1 (AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N) |
| **CWE** | CWE-942: Permissive Cross-domain Policy with Untrusted Domains |
| **OWASP** | A01 Broken Access Control |
| **Эндпоинт** | Все API endpoints (api.stratwise.ai) |

**Описание:**  
API рефлектит **любой** Origin в заголовке `Access-Control-Allow-Origin` в комбинации с `Access-Control-Allow-Credentials: true`. Это позволяет вредоносному сайту делать аутентифицированные запросы от имени пользователя.

**PoC:**
```bash
curl -H "Origin: https://evil.com" https://api.stratwise.ai/api/v1/users/me
# Response headers:
#   access-control-allow-origin: https://evil.com
#   access-control-allow-credentials: true
#   access-control-allow-methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
```

**Импакт:** Атакующий создаёт фишинговую страницу, которая тихо читает данные пользователя: портфель, API-ключи бирж, торговые стратегии, балансы. В сочетании с IDOR — доступ ко ВСЕЙ платформе.

**Рекомендация:**
- Whitelist конкретных origins: `https://stratwise.ai`, `https://app.stratwise.ai`
- Никогда не рефлектить произвольные origins с `credentials: true`
- Добавить CSRF-токены для мутирующих операций

---

### CRIT-03: Слабая парольная политика + Утечка PII при логине

| Параметр | Значение |
|----------|----------|
| **CVSS 3.1** | 8.6 (AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N) |
| **CWE** | CWE-521, CWE-200 |
| **OWASP** | A07 Identification and Authentication Failures |
| **Эндпоинт** | `POST /api/v1/auth/login` |

**Описание:**  
Логин принимает тривиальные пароли (например, «test»). Ответ содержит избыточные PII: полное имя, email, user ID, план подписки, дату создания аккаунта, transfer_token для создания сессии на app.stratwise.ai.

**PoC:**
```json
// POST /api/v1/auth/login с паролем "test"
{
  "transfer_token": "bb5d090...bae284a",
  "redirect_url": "https://app.stratwise.ai/auth?token=...",
  "user": {
    "id": "6e01adc0-...",
    "email": "test@test.com",
    "first_name": "Daniil",
    "last_name": "Goryunov",
    "plan": {"name": "free"},
    "role": "user"
  }
}
```

**Рекомендация:**
- Минимум 8 символов с требованиями к сложности
- Возвращать в ответе логина только токен
- Перенести данные пользователя в `/me` endpoint
- Внедрить блокировку после N неудачных попыток

---

### CRIT-04: OpenAPI/Swagger/ReDoc публично доступны

| Параметр | Значение |
|----------|----------|
| **CVSS 3.1** | 7.5 (AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N) |
| **CWE** | CWE-200 |
| **Эндпоинт** | `/docs`, `/redoc`, `/openapi.json` |

**Описание:**  
Полная OpenAPI 3.1.0 спецификация (284KB) доступна без аутентификации. Содержит ВСЕ эндпоинты, модели данных, параметры, включая внутренние admin-эндпоинты (`/api/v1/api-keys/{uuid}/admin`, `/api/v1/metrics/*`, `/api/v1/webhooks/quicknode`).

**Рекомендация:**
```python
# В production:
app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None)
```

---

### CRIT-05: Prometheus /metrics публично доступен

| Параметр | Значение |
|----------|----------|
| **CVSS 3.1** | 7.5 (AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N) |
| **CWE** | CWE-200 |
| **Эндпоинт** | `GET https://api.stratwise.ai/metrics` |

**Описание:**  
Prometheus metrics (579KB) доступны без аутентификации. Раскрывают все API endpoints и их использование, скрытые endpoints (`/api/v1/webhooks/quicknode` — 950K+ запросов), объёмы трафика, метрики производительности.

**Рекомендация:**
- Закрыть `/metrics` за аутентификацию или VPN
- Использовать internal network only для scraping

---

## High Findings

### HIGH-01: Exchange API-ключи раскрыты в ответах API

| Параметр | Значение |
|----------|----------|
| **CVSS** | 7.5 | **CWE** | CWE-200 |
| **Эндпоинт** | `GET /api/v1/api-keys/` |

Полные public API-ключи Binance и Bybit возвращаются в ответах. В сочетании с CORS-уязвимостью — атакующий может похитить ключи через вредоносный сайт.

**Рекомендация:** Маскировать ключи (показывать последние 4 символа). Возвращать только ID/имя ключа.

---

### HIGH-02: Отсутствие DMARC записи

| **CVSS** | 7.4 | **Категория** | Email Security |

Отсутствие DMARC позволяет отправлять поддельные письма от @stratwise.ai без отклонения. Угроза фишинга пользователей.

**Рекомендация:** `_dmarc.stratwise.ai TXT "v=DMARC1; p=reject; rua=mailto:dmarc@stratwise.ai; pct=100"`

---

### HIGH-03: Отсутствие DKIM записей

| **CVSS** | 7.4 | **Категория** | Email Security |

Нет DKIM-подписи. Подлинность писем не может быть верифицирована.

**Рекомендация:** Настроить DKIM через Namecheap PrivateEmail и опубликовать ключи в DNS.

---

### HIGH-04: Отсутствие критических Security Headers

| **CVSS** | 7.1 | **OWASP** | A05 Security Misconfiguration |

Отсутствуют на фронтенде и API: `Content-Security-Policy`, `Strict-Transport-Security`, `X-Frame-Options`, `Permissions-Policy`. Для финансовой платформы — высокий риск XSS, clickjacking, downgrade-атак.

**Рекомендация:**
```
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
Content-Security-Policy: default-src 'self'; script-src 'self' https://www.googletagmanager.com https://s3.tradingview.com; ...
X-Frame-Options: DENY
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

---

### HIGH-05: Source Maps доступны + отсутствие SRI

| **CVSS** | 6.8 | **OWASP** | A08 Software & Data Integrity |

Source maps (`/assets/index-BrVI2RJu.js.map`) доступны в production — раскрывают полный исходный код. Скрипты загружаются без SRI-хешей.

**Рекомендация:** Удалить source maps из production. Добавить `integrity="sha384-..."` ко всем `<script>` тегам.

---

### HIGH-06: JWT не инвалидируется после logout

| **CVSS** | 6.5 | **CWE** | CWE-613 |

После вызова `/api/v1/auth/logout` токен остаётся валидным до истечения TTL (15 мин). Украденные токены невозможно отозвать.

**Рекомендация:** Redis-based blacklist по JTI. Или переход на opaque session tokens.

---

## Medium Findings

| # | Finding | CVSS | Рекомендация |
|---|---------|------|-------------|
| 12 | Transfer token в URL-параметре | 6.5 | Использовать POST-based обмен токенов |
| 13 | Rate limiting — 9 попыток до блока | 5.9 | Снизить до 3-5, добавить CAPTCHA, exponential backoff |
| 14 | Grafana публично доступна | 5.3 | Закрыть за VPN, обновить nginx |
| 15 | Firebase config в JS-бандле | 5.3 | Аудит Firebase Security Rules, включить App Check |
| 16 | Invite code enumeration | 5.3 | Rate limiting 5 req/min, длинные random коды |
| 17 | Дублирующиеся SPF записи | 5.3 | Объединить: `v=spf1 include:_spf.firebasemail.com include:spf.privateemail.com ~all` |
| 18 | API info disclosure (version, service) | 5.3 | Убрать version, service name из health endpoint и `x-process-time` |
| 19 | JWT HS256 | 4.7 | Перейти на RS256/ES256 |
| 20 | Verbose Pydantic errors | 4.3 | Generic errors в production |
| 21 | Email verification не требуется | 4.3 | Обязательная верификация для финансовых операций |
| 22 | Избыточные данные в ответах | 4.3 | Response DTOs без internal fields |
| 23 | QA API публично доступен | 4.3 | Закрыть за VPN или удалить DNS |

---

## Low / Info

| # | Finding | CVSS | Примечание |
|---|---------|------|-----------|
| 24 | SPF soft fail (~all) | 3.7 | Изменить на `-all` после верификации отправителей |
| 25 | X-Frame-Options отсутствует | 4.3 | Покрывается CSP `frame-ancestors` |
| 26 | Permissions-Policy отсутствует | 3.1 | Добавить в рамках security headers |
| 27 | GTM ID / social links exposed | — | Информационное, стандартная практика |
| — | Logout без аутентификации | 2.1 | Минимальный импакт |
| — | No cookies на SPA (JWT в storage) | — | Учитывать при XSS-защите (CSP) |

---

## Recommendations — Приоритезированный план фиксов

### 🔴 P0 — Немедленно (24 часа)
1. **Исправить IDOR на /bots/** — добавить фильтрацию по user_id
2. **Исправить CORS** — whitelist origins, убрать рефлекцию с credentials
3. **Закрыть /docs, /redoc, /openapi.json, /metrics** в production

### 🟠 P1 — Срочно (48 часов)
4. **Маскировать API-ключи бирж** в ответах
5. **Реализовать инвалидацию JWT** при logout (Redis blacklist)
6. **Усилить парольную политику** (мин. 8 символов, complexity)
7. **Минимизировать данные в ответе логина** (только токен)

### 🟡 P2 — В этом спринте (1 неделя)
8. **Добавить security headers** (CSP, HSTS, X-Frame-Options, Permissions-Policy)
9. **Удалить source maps** из production, добавить SRI
10. **Настроить DMARC и DKIM**
11. **Объединить SPF записи**
12. **Закрыть Grafana и QA API** за VPN

### 🟢 P3 — В этом месяце
13. Усилить rate limiting (3-5 попыток, CAPTCHA, MFA)
14. Перейти на RS256/ES256 для JWT
15. Обязательная email verification
16. Аудит Firebase Security Rules
17. Внедрить response DTOs
18. Убрать info disclosure из health endpoint

---

## Technology Stack

| Компонент | Технология |
|-----------|-----------|
| **Frontend** | React SPA (Vite build), Cloudflare CDN |
| **Backend API** | Python FastAPI на api.stratwise.ai |
| **Auth** | Firebase Auth + custom email auth + JWT (HS256) |
| **Database** | PostgreSQL |
| **CDN/WAF** | Cloudflare |
| **SSL** | Google Trust Services (ECDSA P-256), TLS 1.2/1.3 |
| **Hosting** | Firebase Hosting (stratwise-edaae) |
| **Monitoring** | Grafana (grafana.stratwise.ai), Prometheus |
| **Charts** | TradingView |
| **Analytics** | Google Tag Manager (GTM-P29T4RP7) |
| **Email** | Namecheap PrivateEmail |
| **DNS** | Cloudflare |
| **App** | app.stratwise.ai (Cloudflare Workers) |

---

## Scope & Methodology

### Scope
| Target | Тип |
|--------|-----|
| stratwise.ai | Frontend (SPA) |
| api.stratwise.ai | Backend API |
| app.stratwise.ai | Application |
| auth.stratwise.ai | Auth domain |
| grafana.stratwise.ai | Monitoring |
| qa.api.stratwise.ai | QA environment |
| DNS, Email, Infrastructure | Supporting services |

### Методология
- **Web Application Scan** — анализ фронтенда, заголовков безопасности, субдоменов, открытых портов
- **API Security Scan** — анализ всех эндпоинтов из OpenAPI, тестирование аутентификации, CORS, rate limiting
- **Infrastructure Scan** — DNS enumeration, email security (SPF/DKIM/DMARC), cloud misconfiguration, WHOIS
- **OWASP Top 10 & OSINT** — проверка по OWASP Top 10 2021, OSINT-разведка, technology fingerprinting
- **Authenticated Testing** — тестирование с реальным аккаунтом: IDOR, session management, JWT analysis, data exposure

### Инструменты
- cURL, nmap (ограниченный), crt.sh, DNS enumeration
- Ручное тестирование API endpoints
- JWT decode & analysis
- CORS testing with custom origins

### Ограничения
- Black-box + grey-box (предоставлен тестовый аккаунт с admin-ролью)
- Нет доступа к исходному коду серверной части
- Destructive тесты не проводились (только read-операции)
- nmap ограничен sandbox-окружением

---

## Позитивные находки ✅

| Проверка | Результат |
|----------|----------|
| TLS 1.2+ only (1.0/1.1 отклоняются) | ✅ |
| Input validation (Pydantic/FastAPI) | ✅ |
| SSL сертификат (auto-renew) | ✅ |
| Rate limiting на логине (есть, хоть и слабый) | ✅ |
| Cloudflare WAF/DDoS | ✅ |
| X-Content-Type-Options: nosniff | ✅ |
| Referrer-Policy: strict-origin-when-cross-origin | ✅ |
| Webhook signature validation | ✅ |
| SQL Injection — не обнаружена | ✅ |
| Path Traversal — не уязвим | ✅ |
| .env / .git — не доступны | ✅ |

---

*Отчёт подготовлен Edward @ 0xAudit | 2026-02-09*  
*Classification: CONFIDENTIAL — только для команды Stratwise*
