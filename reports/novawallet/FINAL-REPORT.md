# 🛡️ 0xAudit Security Report: NovaWallet (app.novawallet.org)

**Дата:** 2026-02-09  
**Аудитор:** Edward, 0xAudit  
**Тип цели:** Crypto Wallet (PWA) — HIGH RISK TARGET  
**Версия приложения:** 3.10.1 (prod), API v5.5.1  
**Хостинг:** Cloudflare CDN/WAF, Google Trust Services SSL  
**Область:** app.novawallet.org, api.novawallet.org, novawallet.org, инфраструктура  

---

## Executive Summary

NovaWallet — кастодиальный веб-кошелёк (PWA) для крипто-платежей через PromptPay QR в Таиланде (USDT/KAIA). Аутентификация через OAuth (LINE, Google). Приватные ключи генерируются на сервере, но **передаются клиенту и отображаются в DOM** (`n.wallet.privateKey`).

В ходе аудита обнаружено **28 уникальных находок**, включая **2 критические**, **5 высоких**, **10 средних** и **6 низких/информационных**. Основные риски:

1. **Приватный ключ доступен клиентскому JavaScript** — любая XSS-уязвимость или вредоносное расширение крадёт все средства
2. **Wildcard CORS (`*`)** на всех эндпоинтах — любой сайт может выполнять cross-origin запросы
3. **Отсутствие CSP** — нет защиты от XSS-инъекций
4. **Session replay (Hotjar/Contentsquare/Gleap rrweb)** на странице с приватным ключом — ключи могут записываться и отправляться третьим лицам
5. **Отсутствие 2FA/PIN** для транзакций — компрометация токена = потеря всех средств

**Общая оценка: приложение в текущем состоянии небезопасно для хранения криптовалютных активов.**

---

## Overall Risk Rating

| Метрика | Значение |
|---------|----------|
| **Общий риск** | 🔴 **CRITICAL** |
| Critical | 2 |
| High | 5 |
| Medium | 10 |
| Low | 6 |
| Info | 5 |
| **CVSS максимальный** | 9.8 |

---

## Findings Summary Table

| # | ID | Находка | Severity | CVSS | Источник |
|---|-----|---------|----------|------|----------|
| 1 | CRIT-01 | Приватный ключ в клиентском JS/DOM | 🔴 Critical | 9.8 | OWASP |
| 2 | CRIT-02 | Wildcard CORS (`Access-Control-Allow-Origin: *`) | 🔴 Critical | 9.1 | Web+API+OWASP |
| 3 | HIGH-01 | Отсутствие Content Security Policy (CSP) | 🟠 High | 8.1 | Web+OWASP |
| 4 | HIGH-02 | Токен передаётся через URL-параметры (OAuth callback) | 🟠 High | 7.5 | OWASP |
| 5 | HIGH-03 | Токен хранится в localStorage | 🟠 High | 7.5 | OWASP |
| 6 | HIGH-04 | Клиентский перевод средств без 2FA/PIN | 🟠 High | 7.5 | OWASP |
| 7 | HIGH-05 | Отсутствие SRI на внешних скриптах | 🟠 High | 7.4 | OWASP |
| 8 | MED-01 | Отсутствие X-Frame-Options / frame-ancestors | 🟡 Medium | 5.4 | Web+OWASP |
| 9 | MED-02 | Отсутствие Permissions-Policy | 🟡 Medium | 6.8 | Web |
| 10 | MED-03 | Session replay на крипто-кошельке (Contentsquare + rrweb/Gleap) | 🟡 Medium | 6.5 | Web+API+OWASP |
| 11 | MED-04 | OAuth-only аутентификация без MFA | 🟡 Medium | 5.9 | OWASP |
| 12 | MED-05 | Отсутствие HSTS | 🟡 Medium | 5.9 | Web |
| 13 | MED-06 | Verbose JWT error messages (утечка деталей) | 🟡 Medium | 5.3 | API |
| 14 | MED-07 | Отсутствие rate limiting на API | 🟡 Medium | 5.3 | API |
| 15 | MED-08 | Эндпоинты /wallet/keys, /wallet/seed, /wallet/export доступны | 🟡 Medium | 5.3 | API |
| 16 | MED-09 | Dev-поддомен (dev.novawallet.org) публично доступен | 🟡 Medium | 5.3 | Web+Infra |
| 17 | MED-10 | Большой third-party JS бандл (Gleap, 728KB) | 🟡 Medium | 5.3 | OWASP |
| 18 | MED-11 | Отсутствие SPF-записи | 🟡 Medium | 5.3 | Infra |
| 19 | MED-12 | Отсутствие CAA DNS-записей | 🟡 Medium | 4.3 | Infra |
| 20 | MED-13 | DNSSEC не включён | 🟡 Medium | 4.3 | Infra |
| 21 | LOW-01 | Отсутствие session expiry | 🔵 Low | 3.9 | OWASP |
| 22 | LOW-02 | Service Worker кеширует чувствительные ассеты | 🔵 Low | 3.7 | OWASP |
| 23 | LOW-03 | Admin-эндпоинт обнаруживается (/admin → 401) | 🔵 Low | 3.7 | API |
| 24 | LOW-04 | Отсутствие мониторинга безопасности (CSP report) | 🔵 Low | 3.0 | OWASP |
| 25 | LOW-05 | Cache-Control: public на чувствительных страницах | 🔵 Low | 2.4 | Web |
| 26 | LOW-06 | Множество CA-издателей сертификатов | 🔵 Low | 2.0 | Infra |
| 27 | INFO-01 | OAuth client IDs в redirect URLs | ℹ️ Info | 0.0 | API |
| 28 | INFO-02 | Регистрация protocol handlers (web+nova, web+ethereum) | ℹ️ Info | — | OWASP |

---

## Critical Findings

### CRIT-01: Приватный ключ доступен клиентскому JavaScript

| Параметр | Значение |
|----------|----------|
| **CVSS** | 9.8 (Critical) |
| **Категория OWASP** | A02: Cryptographic Failures |
| **Воздействие** | Полная компрометация всех кошельков пользователей |

**Описание:**  
Приватный ключ кошелька доступен через объект `n.wallet.privateKey` и отрисовывается в DOM на странице `/profile/settings/pkey`. Любая XSS-уязвимость, вредоносное расширение браузера, скомпрометированная JS-зависимость или session replay инструмент может извлечь приватные ключи.

**PoC (из pkey-AWLDCZKO.js):**
```javascript
// Приватный ключ в input:
<input type=${p?"password":"text"} readonly value=${n.wallet.privateKey} />
// Копирование в буфер:
d.copy(n.wallet.privateKey)
```

**Рекомендация:**
- Никогда не передавать raw private keys в DOM браузера
- Использовать HSM или secure enclave для хранения ключей
- Если экспорт ключа необходим — требовать 2FA + rate limiting + шифрование
- Рассмотреть полностью кастодиальную модель, где ключи не покидают сервер

---

### CRIT-02: Wildcard CORS на всех эндпоинтах

| Параметр | Значение |
|----------|----------|
| **CVSS** | 9.1 (Critical) |
| **Категория OWASP** | A01: Broken Access Control |
| **Затронуто** | app.novawallet.org, api.novawallet.org |

**Описание:**  
Все ответы сервера содержат `Access-Control-Allow-Origin: *` с `Access-Control-Allow-Methods: GET,HEAD,PUT,POST,DELETE,PATCH`. Любой вредоносный сайт может выполнять cross-origin запросы к API кошелька.

**PoC:**
```bash
curl -sI -H "Origin: https://evil.com" https://api.novawallet.org/wallet/balance
# → access-control-allow-origin: *
# → access-control-allow-methods: GET,HEAD,PUT,POST,DELETE,PATCH
```

**Рекомендация:**
- Заменить `*` на явный allowlist: `https://app.novawallet.org`
- Добавить `Vary: Origin`
- Реализовать серверную валидацию Origin

---

## High Findings

### HIGH-01: Отсутствие Content Security Policy (CSP)

**CVSS:** 8.1 | **OWASP:** A03 (Injection)

Заголовок CSP полностью отсутствует. В контексте крипто-кошелька с приватными ключами в DOM это означает нулевую защиту от XSS. Внедрённый скрипт может извлечь `n.wallet.privateKey`, токен из localStorage и все данные кошелька.

**Рекомендация:** `Content-Security-Policy: default-src 'self'; script-src 'self'; connect-src 'self' https://api.novawallet.org; frame-ancestors 'none'`

### HIGH-02: Токен передаётся через URL-параметры

**CVSS:** 7.5 | **OWASP:** A01

OAuth callback передаёт токен через `?token=...` → `window.location.search`. Токен утекает через Referer, историю браузера, логи серверов и аналитику.

**Evidence:** `var s=p.get("token"); s&&window.opener?.postMessage({token:s},location.origin)`

**Рекомендация:** Использовать HTTP-only cookies или POST-based token exchange.

### HIGH-03: Токен хранится в localStorage

**CVSS:** 7.5 | **OWASP:** A02

`localStorage.setItem("token",t)` — доступен любому JS на том же origin. В сочетании с отсутствием CSP и наличием third-party скриптов (Contentsquare, Gleap) — высокий риск кражи.

**Рекомендация:** HTTP-only, Secure, SameSite cookies.

### HIGH-04: Клиентский перевод средств без 2FA/PIN

**CVSS:** 7.5 | **OWASP:** A04 (Insecure Design)

Трансферы выполняются через `k.wallet.transfer(address, assetId, amount)` без дополнительной верификации. Компрометация сессии = потеря всех средств.

**Рекомендация:** Обязательный PIN/2FA для каждого перевода, серверный approval flow, лимиты и velocity checks.

### HIGH-05: Отсутствие SRI на внешних скриптах

**CVSS:** 7.4 | **OWASP:** A08 (Software & Data Integrity)

Contentsquare загружается без `integrity` атрибута: `<script src=https://t.contentsquare.net/uxa/ccc1e9d22f8f3.js></script>`. Компрометация CDN = исполнение произвольного кода в контексте кошелька.

**Рекомендация:** SRI на все скрипты. Self-hosting для критичных зависимостей.

---

## Medium Findings

| ID | Находка | CVSS | Рекомендация |
|----|---------|------|-------------|
| MED-01 | Нет X-Frame-Options → clickjacking | 5.4 | `X-Frame-Options: DENY` + CSP `frame-ancestors 'none'` |
| MED-02 | Нет Permissions-Policy → доступ к clipboard/camera | 6.8 | `Permissions-Policy: camera=(), clipboard-read=()` |
| MED-03 | Session replay (Contentsquare + rrweb/Gleap) записывает ввод ключей | 6.5 | **Немедленно удалить** все session replay с кошелька |
| MED-04 | OAuth-only без MFA | 5.9 | Обязательный 2FA для доступа к кошельку |
| MED-05 | Нет HSTS → MITM downgrade | 5.9 | `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload` |
| MED-06 | Verbose JWT errors раскрывают структуру токенов | 5.3 | Возвращать generic `"Unauthorized"` |
| MED-07 | Нет rate limiting на API (20 req → 0 блокировок) | 5.3 | Cloudflare Rate Limiting, 60 req/min/IP |
| MED-08 | Эндпоинты /wallet/keys, /wallet/seed, /wallet/export | 5.3 | Доп. аутентификация, rate limit 3 req/hour, audit log |
| MED-09 | dev.novawallet.org публично доступен | 5.3 | VPN/IP allowlist |
| MED-10 | Gleap bundle 728KB с rrweb → surface attack | 5.3 | Удалить или изолировать |
| MED-11 | Нет SPF записи → email spoofing | 5.3 | `v=spf1 include:_spf.protonmail.ch ~all` |
| MED-12 | Нет CAA DNS записей → любой CA может выпустить сертификат | 4.3 | Добавить CAA записи |
| MED-13 | DNSSEC не включён → DNS hijacking | 4.3 | Включить DNSSEC через Cloudflare |

---

## Low / Info

| ID | Находка | CVSS | Рекомендация |
|----|---------|------|-------------|
| LOW-01 | Нет session expiry, токен бессрочный | 3.9 | Token rotation, idle timeout |
| LOW-02 | SW кеширует чувствительные JS | 3.7 | Исключить из кеша |
| LOW-03 | /admin обнаруживается (401 vs 404) | 3.7 | Отвечать 404, вынести на отдельный домен |
| LOW-04 | Нет CSP report-uri | 3.0 | Настроить CSP reporting |
| LOW-05 | Cache-Control: public | 2.4 | `private, no-store` |
| LOW-06 | 3 разных CA (Google, Let's Encrypt, GoDaddy) | 2.0 | Консолидировать |
| INFO-01 | OAuth client IDs в URL | 0.0 | Проверить redirect URI validation |
| INFO-02 | Protocol handlers web+nova, web+ethereum | — | Валидировать input |
| INFO-03 | DMARC reporting на default GoDaddy адрес | — | Настроить мониторинг |
| INFO-04 | .env защищён WAF (429) | ✅ | Позитивная находка |
| INFO-05 | Origin IP не утекает через DNS/MX | ✅ | Позитивная находка |

---

## Crypto-Specific Risks

| Риск | Статус | Критичность | Описание |
|------|--------|-------------|----------|
| **Кража приватных ключей через XSS** | 🔴 CRITICAL | 9.8 | Ключ в DOM + нет CSP = полная компрометация |
| **Запись ключей session replay** | 🔴 CRITICAL | Высокий | Hotjar/Contentsquare/Gleap rrweb записывают страницу pkey |
| **Cross-origin кража данных** | 🔴 CRITICAL | 9.1 | CORS `*` на финансовом API |
| **Supply chain атака через CDN** | 🟠 HIGH | 7.4 | Нет SRI, внешние скрипты |
| **Переводы без подтверждения** | 🟠 HIGH | 7.5 | Нет 2FA/PIN, client-side transfer |
| **Clipboard hijacking** | 🟡 MEDIUM | — | Нет Permissions-Policy |
| **DNS hijacking → фишинг** | 🟡 MEDIUM | 4.3 | Нет DNSSEC, нет CAA |
| **Email spoofing → фишинг** | 🟡 MEDIUM | 5.3 | Нет SPF |
| **Кража seed phrase через API** | 🟡 MEDIUM | 5.3 | /wallet/seed эндпоинт существует |

### Архитектура ключей (обнаружена)
```
OAuth (LINE/Google) → JWT Token → localStorage
JWT Token → API → Wallet Object (включая privateKey)
Transfer → k.wallet.transfer(addr, asset, amount) — client-side
Private Key → отображается на /profile/settings/pkey в DOM
/wallet/keys, /wallet/seed, /wallet/export — API эндпоинты (требуют JWT)
```

**Вывод:** Архитектура «custodial wallet с client-side exposure ключей» сочетает худшие стороны обоих подходов: сервер хранит ключи (единая точка отказа), но при этом передаёт их клиенту (расширенная поверхность атаки).

---

## Recommendations

### 🔴 P0 — Немедленно (сегодня)

| # | Действие | Усилия |
|---|----------|--------|
| 1 | **Удалить session replay** (Contentsquare, Gleap/rrweb) с кошелька | Низкие |
| 2 | **Исправить CORS** — restrict to `https://app.novawallet.org` | Низкие |
| 3 | **Внедрить CSP** с strict policy | Средние |
| 4 | **Убрать приватный ключ из DOM** — редизайн экспорта ключей | Средние |

### 🟠 P1 — Эта неделя

| # | Действие | Усилия |
|---|----------|--------|
| 5 | Перенести токен в HTTP-only cookies | Средние |
| 6 | Добавить SRI на все скрипты | Низкие |
| 7 | Внедрить 2FA/PIN для транзакций | Средние |
| 8 | Добавить security headers (HSTS, X-Frame-Options, Permissions-Policy, COOP, CORP) | Низкие |
| 9 | Исправить verbose JWT errors | Низкие |
| 10 | Внедрить rate limiting | Низкие |

### 🟡 P2 — Этот спринт (2 недели)

| # | Действие | Усилия |
|---|----------|--------|
| 11 | Серверный transaction signing с approval workflow | Высокие |
| 12 | Session expiry + token rotation | Средние |
| 13 | Добавить SPF запись | Низкие |
| 14 | Включить DNSSEC + CAA записи | Низкие |
| 15 | Закрыть dev.novawallet.org за VPN | Низкие |
| 16 | Скрыть /admin (404 вместо 401) | Низкие |

### 🔵 P3 — Этот месяц

| # | Действие | Усилия |
|---|----------|--------|
| 17 | Полный редизайн key management (HSM/enclave) | Высокие |
| 18 | CSP violation reporting | Низкие |
| 19 | Консолидация CA | Низкие |
| 20 | Аудит внутренних API эндпоинтов (authenticated) | Высокие |

---

## Technology Stack

| Компонент | Технология |
|-----------|-----------|
| Frontend | PWA/SPA, Vanilla JS, Web Components, module-based |
| Backend API | REST API v5.5.1, JWT auth |
| CDN/WAF | Cloudflare |
| TLS | TLSv1.3, ECDSA-SHA256, Google Trust Services (WE1) |
| Хостинг origin | Firebase Hosting / Google Cloud (по сертификатам) |
| OAuth | LINE (client: 2007849543), Google |
| Аналитика | Contentsquare/Hotjar UXA |
| Feedback SDK | Gleap (с rrweb session replay, 728KB) |
| Маркетинг-сайт | Tilda CMS (novawallet.org) |
| Документация | GitBook/Next.js (docs.novawallet.org) |
| Крипто-сети | BSC, KAIA (Klaytn) — EVM chains |
| Fiat on-ramp | buy.onramper.dev |
| Домен | GoDaddy, DNS через Cloudflare |
| Email | ProtonMail (по TXT записям) |

---

## Scope & Methodology

### Область аудита
- **Frontend:** app.novawallet.org (PWA/SPA)
- **API:** api.novawallet.org (REST, unauthenticated probing)
- **Инфраструктура:** DNS, SSL/TLS, Cloudflare, поддомены, email security
- **OWASP:** Top 10 + crypto-specific assessment
- **Маркетинг:** novawallet.org (Tilda)

### Методология
1. **Reconnaissance:** DNS enumeration, subdomain discovery (crt.sh, brute-force), WHOIS, Certificate Transparency
2. **Web Application Scan:** Security headers, CORS policy, CSP analysis, third-party scripts, technology fingerprinting
3. **API Discovery:** Endpoint enumeration, auth flow analysis, error message analysis, rate limiting test
4. **Infrastructure:** Cloudflare bypass attempts, email security (SPF/DKIM/DMARC), DNSSEC, CAA, cloud misconfigs (S3)
5. **OWASP Assessment:** Top 10 categories, source code analysis (client-side JS), crypto-specific checks
6. **Crypto-Specific:** Key management architecture, transaction flow, wallet design analysis

### Ограничения
- **Black-box** аудит — без доступа к серверному коду и аутентифицированным эндпоинтам
- Сканирование портов (nmap) невозможно из-за ограничений sandbox
- Эксплуатация уязвимостей не проводилась
- OSINT ограничен (Brave API недоступен)
- Authenticated API testing не проводился

---

## Positive Security Controls

- ✅ Cloudflare WAF/DDoS protection
- ✅ TLSv1.3 с сильными шифрами
- ✅ `X-Content-Type-Options: nosniff`
- ✅ `Referrer-Policy: strict-origin-when-cross-origin`
- ✅ DMARC `p=reject` (strongest policy)
- ✅ WHOIS privacy + все EPP locks
- ✅ Origin IP не утекает
- ✅ .env защищён WAF (429)
- ✅ Нет открытых blockchain RPC портов
- ✅ Нет утечек S3 бакетов
- ✅ robots.txt блокирует AI-краулеры

---

*Отчёт подготовлен Edward @ 0xAudit | 2026-02-09*  
*Тип: External black-box assessment | Эксплуатация не проводилась*
