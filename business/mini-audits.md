# 🔒 Mini Security Audits — AI Products
**Date:** 2026-02-09 | **Auditor:** 0xAudit | **Type:** Quick External Scan

---

## 1. Notis.ai — Quick Security Scan

- **URL:** https://notis.ai
- **Overall:** 🟢 Good
- **Stack:** Framer (static site builder), Let's Encrypt SSL, hosted in ap-southeast-1

**Findings:**
- ✅ HSTS enabled (`max-age=31536000`)
- ✅ `X-Content-Type-Options: nosniff` present
- ⚠️ No `Content-Security-Policy` (CSP) header — leaves site open to potential XSS if dynamic content is added
- ⚠️ No `X-Frame-Options` header — site can be embedded in iframes (clickjacking risk)
- ✅ No sensitive files exposed (`.env`, `.git`, `/api/docs`, `/swagger` → all 404)
- ✅ No open CORS policy — `Access-Control-Allow-Origin` not set for arbitrary origins
- ✅ SSL certificate valid (Let's Encrypt, expires 2026-05-05)

**Рекомендация владельцу:** Отличная базовая настройка! Рекомендуем добавить заголовки `Content-Security-Policy` и `X-Frame-Options` для полной защиты от XSS и clickjacking атак. Framer позволяет настроить custom headers в разделе проекта.

---

## 2. ScalerX.ai — Quick Security Scan

- **URL:** https://scalerx.ai
- **Overall:** 🟠 Needs Attention
- **Stack:** WordPress, Cloudflare CDN, GoDaddy SSL, Google Site Kit, ACF, MCP Adapter plugin

**Findings:**
- 🔴 **WP REST API полностью открыт** (`/wp-json/`) — раскрывает полную структуру сайта, endpoints, плагины (Google Site Kit, ACF, MCP Adapter), user endpoints
- 🔴 **`/.env` и `/.git` возвращают 403** (не 404) — подтверждает наличие этих файлов на сервере, потенциальная утечка при ошибке конфигурации
- ⚠️ Нет заголовков `HSTS`, `CSP`, `X-Frame-Options`, `X-Content-Type-Options`
- ⚠️ MCP (Model Context Protocol) endpoint обнаружен (`/wp-json/mcp/`, `/wp-json/gd-mcp/v1/`) — потенциальный вектор атаки
- ⚠️ `wp-site-health` endpoints доступны — раскрывают информацию о здоровье сайта

**Рекомендация владельцу:** Приоритетно: ограничьте доступ к WP REST API (плагин типа Disable REST API или правила в `.htaccess`), измените ответ для `.env`/`.git` с 403 на 404, и добавьте security headers через Cloudflare. MCP endpoint требует особого внимания — убедитесь, что он защищён аутентификацией.

---

## 3. NextDocs.io — Quick Security Scan

- **URL:** https://nextdocs.io (→ redirects to https://www.nextdocs.io)
- **Overall:** 🟡 Moderate
- **Stack:** Vercel (Next.js), Let's Encrypt SSL

**Findings:**
- ✅ HSTS включён (`max-age=63072000` — ~2 года, отлично)
- ✅ SSL сертификат валиден (Let's Encrypt, expires 2026-04-13)
- ⚠️ Нет `Content-Security-Policy` header
- ⚠️ Нет `X-Frame-Options` и `X-Content-Type-Options` headers
- ✅ Все чувствительные пути корректно перенаправляются (301 → www), без утечек
- ✅ Нет открытой CORS policy

**Рекомендация владельцу:** Хорошая базовая конфигурация на Vercel. Добавьте security headers (`CSP`, `X-Frame-Options`, `X-Content-Type-Options`) через `vercel.json` или `next.config.js` — это займёт 5 минут и значительно повысит уровень безопасности.

---

## Summary

| Site | Rating | Critical Issues | Quick Wins |
|------|--------|----------------|------------|
| notis.ai | 🟢 Good | 0 | Add CSP + X-Frame-Options |
| scalerx.ai | 🟠 Needs Attention | 2 (REST API exposure, .env/.git 403) | Restrict WP API, add headers |
| nextdocs.io | 🟡 Moderate | 0 | Add security headers in vercel.json |

---

*This report was generated as a complimentary external security scan by **0xAudit**. It covers only publicly visible attack surface. For a comprehensive security audit including application logic, authentication flows, and API security, [contact us](https://t.me/Yava_Working).*
