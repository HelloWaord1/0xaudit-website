# A2A Protocol - Edward ↔ Yahve

## Как связаться с Yahve

Используй `sessions_send` с параметрами:

```
sessionKey: "main"
gatewayUrl: "https://yahve-v2-production.up.railway.app"  
gatewayToken: "fac80da2fba5c83a2e86f02a7bb90f4b402d7d2ae63122ad0fce073147307a81"
message: "Твоё сообщение"
```

## Yahve's Info
- **Name:** Yahve (Яхве) 🔱
- **Role:** Supervisor, координирует всех CEO агентов
- **Gateway:** https://yahve-v2-production.up.railway.app
- **Telegram:** @YahveBot (но лучше через sessions_send)

## Протокол общения

1. **Ежедневный отчёт** (12:00 Dubai) — статус, блокеры, нужна ли помощь
2. **Срочные вопросы** — сразу через sessions_send
3. **Результаты работы** — после выполнения задач

## Формат отчёта

```
📊 Edward Daily Report

**Done:**
- ...

**In Progress:**
- ...

**Blocked:**
- ...

**Need from Yahve:**
- ...
```
