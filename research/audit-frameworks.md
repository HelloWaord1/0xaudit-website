# 🔍 Security Audit Frameworks & Tools Research

> **Date:** 2026-02-09 | **Author:** 0xAudit (Edward) | **Purpose:** Integration candidates for multi-agent automated audit platform

---

## 📊 Priority Legend

- 🔴 **CRITICAL** — Must integrate, core of automation pipeline
- 🟠 **HIGH** — Strong value, integrate soon
- 🟡 **MEDIUM** — Useful, integrate when needed
- 🟢 **LOW** — Nice to have

---

## 1. 🌐 Web Application Security

| Tool | GitHub | Stars | Install | CLI/API | Priority | Description |
|------|--------|-------|---------|---------|----------|-------------|
| **Nuclei** | [projectdiscovery/nuclei](https://github.com/projectdiscovery/nuclei) | ~22k+ | `go install` / binary | ✅ CLI, YAML templates, CI/CD | 🔴 | Fast YAML-based vuln scanner; 9000+ community templates; supports HTTP/DNS/TCP/SSL |
| **ZAP (Zaproxy)** | [zaproxy/zaproxy](https://github.com/zaproxy/zaproxy) | ~14.7k | Docker, apt, snap | ✅ REST API, CLI, headless | 🔴 | OWASP flagship DAST scanner; active/passive scan, spidering, auth handling |
| **Nikto** | [sullo/nikto](https://github.com/sullo/nikto) | ~8k+ | apt, perl | ✅ CLI | 🟡 | Classic web server scanner; 6700+ checks; fast but noisy |
| **Wapiti** | [wapiti-scanner/wapiti](https://github.com/wapiti-scanner/wapiti) | ~3k+ | pip | ✅ CLI | 🟡 | Black-box web app scanner; XSS, SQLi, SSRF, XXE detection |
| **Lynis** | [CISOfy/lynis](https://github.com/CISOfy/lynis) | ~13k+ | apt, brew | ✅ CLI, CI/CD | 🟠 | System/server security auditing; HIPAA/ISO27001/PCI DSS compliance |
| **DeepAudit** | [lintsinghua/DeepAudit](https://github.com/lintsinghua/DeepAudit) | ~3k+ | Docker, Python | ✅ Web UI, CLI | 🟠 | **Multi-agent AI code audit system**; auto PoC verification; found 48 CVEs; supports Ollama |

### 🆕 Новое 2025-2026:
- **DeepAudit** — мультиагентная AI система для аудита кода (аналог нашей концепции!)
- **Nuclei** продолжает доминировать, 9000+ шаблонов community

---

## 2. 🔌 API Security

| Tool | GitHub | Stars | Install | CLI/API | Priority | Description |
|------|--------|-------|---------|---------|----------|-------------|
| **Kiterunner** | [assetnote/kiterunner](https://github.com/assetnote/kiterunner) | ~3k+ | Go binary | ✅ CLI | 🟠 | API endpoint discovery using OpenAPI/Swagger wordlists; context-aware brute-force |
| **graphw00f** | [dolevf/graphw00f](https://github.com/dolevf/graphw00f) | ~1k+ | Python | ✅ CLI | 🟠 | GraphQL server engine fingerprinting |
| **Clairvoyance** | [nikitastupin/clairvoyance](https://github.com/nikitastupin/clairvoyance) | ~1k+ | pip | ✅ CLI | 🟠 | Obtains GraphQL schema even with introspection disabled |
| **RESTler** | [microsoft/restler-fuzzer](https://github.com/microsoft/restler-fuzzer) | ~2.5k+ | dotnet | ✅ CLI | 🟠 | Stateful REST API fuzzer from Microsoft Research; auto-generates tests from Swagger/OpenAPI |
| **Cherrybomb** | [blst-security/cherrybomb](https://github.com/blst-security/cherrybomb) | ~1k+ | Rust binary | ✅ CLI | 🟡 | OpenAPI spec validator + API security scanner |
| **InQL** | [doyensec/inql](https://github.com/doyensec/inql) | ~1.5k+ | pip | ✅ CLI + Burp extension | 🟡 | GraphQL security testing toolkit; schema extraction, query generation |

---

## 3. 📜 Smart Contract Audit

| Tool | GitHub | Stars | Install | CLI/API | Priority | Description |
|------|--------|-------|---------|---------|----------|-------------|
| **Slither** | [crytic/slither](https://github.com/crytic/slither) | ~5.5k+ | pip (`slither-analyzer`) | ✅ CLI, Python API | 🔴 | Static analyzer for Solidity/Vyper; 90+ detectors; low false positives; CI/CD ready |
| **Mythril** | [ConsenSysDiligence/mythril](https://github.com/ConsenSysDiligence/mythril) | ~4k+ | pip, Docker | ✅ CLI | 🔴 | Symbolic execution for EVM bytecode; detects reentrancy, overflow, access control |
| **Foundry (Forge)** | [foundry-rs/foundry](https://github.com/foundry-rs/foundry) | ~8.5k+ | `curl -L https://foundry.paradigm.xyz \| bash` | ✅ CLI | 🔴 | Blazing fast Solidity toolkit; fuzz testing, fork testing, invariant testing |
| **Echidna** | [crytic/echidna](https://github.com/crytic/echidna) | ~2.7k+ | Binary, Docker | ✅ CLI | 🟠 | Property-based fuzzer for Ethereum contracts; grammar-based campaigns |
| **Aderyn** | [Cyfrin/aderyn](https://github.com/Cyfrin/aderyn) | ~1k+ | Rust/cargo | ✅ CLI | 🟠 | Rust-based Solidity static analyzer; fast; built by Cyfrin team |
| **Semgrep Smart Contracts** | [Decurity/semgrep-smart-contracts](https://github.com/Decurity/semgrep-smart-contracts) | ~800+ | pip (semgrep) | ✅ CLI | 🟠 | Semgrep rules based on real DeFi exploits (reentrancy, oracle manipulation, etc.) |
| **Halmos** | [a16z/halmos](https://github.com/a16z/halmos) | ~1k+ | pip | ✅ CLI | 🟡 | Symbolic testing for Foundry projects; formal verification |
| **Wake** | [Ackee-Blockchain/wake](https://github.com/Ackee-Blockchain/wake) | ~500+ | pip | ✅ CLI, Python API | 🟡 | Solidity dev/testing framework with vulnerability detectors |
| **4naly3er** | [Picodes/4naly3er](https://github.com/Picodes/4naly3er) | ~400+ | Node.js | ✅ CLI | 🟡 | Automated Solidity analysis for audit contests (gas, low/medium findings) |

### 🆕 Тренды 2025-2026:
- **Aderyn** (Cyfrin) — быстрый Rust-based аналог Slither
- **Halmos** (a16z) — формальная верификация через символьное тестирование
- **Foundry fuzz/invariant** — стандарт индустрии для тестирования

---

## 4. 🏗️ Infrastructure & Cloud Security

| Tool | GitHub | Stars | Install | CLI/API | Priority | Description |
|------|--------|-------|---------|---------|----------|-------------|
| **Nuclei** | (см. выше) | ~22k+ | Go | ✅ | 🔴 | Универсальный сканер, включая infra |
| **Prowler** | [prowler-cloud/prowler](https://github.com/prowler-cloud/prowler) | ~11k+ | pip, Docker | ✅ CLI, CI/CD | 🟠 | Cloud security for AWS/Azure/GCP/K8s; сотни проверок compliance |
| **ScoutSuite** | [nccgroup/ScoutSuite](https://github.com/nccgroup/ScoutSuite) | ~6.5k+ | pip, Docker | ✅ CLI | 🟠 | Multi-cloud security auditing (AWS/Azure/GCP/Oracle); HTML report |
| **Trivy** | [aquasecurity/trivy](https://github.com/aquasecurity/trivy) | ~24k+ | apt, brew, binary | ✅ CLI, CI/CD | 🟠 | Container/IaC/SBOM vulnerability scanner; supports Docker, K8s, Terraform |
| **CloudSploit** | [aquasecurity/cloudsploit](https://github.com/aquasecurity/cloudsploit) | ~3k+ | npm | ✅ CLI | 🟡 | Cloud security config monitoring for AWS/Azure/GCP |
| **Checkov** | [bridgecrewio/checkov](https://github.com/bridgecrewio/checkov) | ~7k+ | pip | ✅ CLI, CI/CD | 🟡 | IaC static analysis (Terraform, CloudFormation, K8s, Docker) |

---

## 5. 🤖 AI/ML Security

| Tool | GitHub | Stars | Install | CLI/API | Priority | Description |
|------|--------|-------|---------|---------|----------|-------------|
| **Garak** | [NVIDIA/garak](https://github.com/NVIDIA/garak) | ~2.5k+ | pip | ✅ CLI, Python API | 🔴 | **LLM vulnerability scanner** by NVIDIA; probes for injection, jailbreaks, hallucination, data leakage |
| **PyRIT** | [Azure/PyRIT](https://github.com/Azure/PyRIT) | ~2k+ | pip | ✅ Python API | 🟠 | Microsoft's Python Risk Identification Toolkit for generative AI red-teaming |
| **Rebuff** | [protectai/rebuff](https://github.com/protectai/rebuff) | ~1k+ | pip | ✅ API | 🟡 | Prompt injection detection framework; self-hardening |
| **LLM Guard** | [protectai/llm-guard](https://github.com/protectai/llm-guard) | ~1k+ | pip | ✅ API, CLI | 🟡 | Input/output guardrails for LLM apps; prompt injection, toxicity, PII detection |
| **Vigil** | [deadbits/vigil-llm](https://github.com/deadbits/vigil-llm) | ~500+ | pip | ✅ API | 🟡 | LLM prompt injection detection; embedding similarity + heuristics |

### 🆕 Горячая тема 2025-2026:
- **Garak** — стандарт для LLM red-teaming, активно развивается NVIDIA
- **PyRIT** — Microsoft's framework, отличная интеграция с Azure
- AI security аудит — **новый сервис для 0xAudit!**

---

## 6. 🎯 Automated Pentest Frameworks

| Tool | GitHub | Stars | Install | CLI/API | Priority | Description |
|------|--------|-------|---------|---------|----------|-------------|
| **PentestGPT** | [GreyDGL/PentestGPT](https://github.com/GreyDGL/PentestGPT) | ~7.5k+ | Docker, Make | ✅ CLI (agentic) | 🔴 | **AI-powered autonomous pentest agent**; uses Claude/GPT; session persistence; Docker-first |
| **AutoRecon** | [Tib3rius/AutoRecon](https://github.com/Tib3rius/AutoRecon) | ~5k+ | pip | ✅ CLI | 🟠 | Automated network recon; runs nmap, enum4linux, nikto, etc. in parallel |
| **Scan4all** | [GhostTroops/scan4all](https://github.com/GhostTroops/scan4all) | ~5k+ | Go binary | ✅ CLI | 🟡 | 15000+ PoCs; 23 password crackers; 7000+ web fingerprints; all-in-one scanner |
| **Osmedeus** | [j3ssie/osmedeus](https://github.com/j3ssie/osmedeus) | ~5k+ | Go | ✅ CLI, workflow engine | 🟠 | Automated recon/vuln scanning workflow framework; distributed scanning |

---

## 7. 📝 Reporting & Vulnerability Management

| Tool | GitHub | Stars | Install | CLI/API | Priority | Description |
|------|--------|-------|---------|---------|----------|-------------|
| **DefectDojo** | [DefectDojo/django-DefectDojo](https://github.com/DefectDojo/django-DefectDojo) | ~3.7k+ | Docker, pip | ✅ REST API | 🔴 | **Vulnerability management platform**; imports from 150+ scanners; dedup, tracking, reporting |
| **Faraday** | [infobyte/faraday](https://github.com/infobyte/faraday) | ~5k+ | Docker, pip | ✅ REST API | 🟠 | Collaborative pentest/vuln management platform; imports from many tools |
| **Dradis** | [dradis/dradis-ce](https://github.com/dradis/dradis-ce) | ~500+ | Ruby | ✅ API | 🟡 | Security reporting and collaboration framework |
| **PlexTrac** (commercial) | — | — | SaaS | API | 🟡 | Pentest reporting platform (reference only) |
| **Ghostwriter** | [GhostManager/Ghostwriter](https://github.com/GhostManager/Ghostwriter) | ~1k+ | Docker | ✅ API | 🟡 | Pentest report writing & campaign management |
| **CVSS Calculator** | [nickthecook/cvss](https://github.com/nickthecook/cvss) | ~100+ | gem/npm variants | ✅ CLI/lib | 🟡 | CVSS v3/v4 score calculation |

---

## 🏆 Рекомендуемый Stack для 0xAudit

### Tier 1 — Core (Интегрировать первыми)

| Категория | Инструмент | Почему |
|-----------|-----------|--------|
| **Web Scanning** | Nuclei | Универсальный, YAML-шаблоны, CI/CD, 9000+ проверок |
| **Web DAST** | ZAP | REST API, headless, полный DAST |
| **Smart Contract** | Slither | Python API, 90+ детекторов, CI/CD |
| **Smart Contract** | Mythril | Символьное выполнение, дополняет Slither |
| **Smart Contract** | Foundry (Forge) | Фаззинг, инвариантное тестирование |
| **AI/LLM** | Garak | LLM red-teaming, pip install |
| **Pentest** | PentestGPT | AI-агент для пентеста, аналогичная архитектура |
| **Reporting** | DefectDojo | REST API, импорт из 150+ сканеров, деdup |

### Tier 2 — Расширение

| Категория | Инструмент | Почему |
|-----------|-----------|--------|
| **Cloud** | Prowler | AWS/Azure/GCP compliance |
| **Cloud** | Trivy | Контейнеры, IaC, SBOM |
| **API** | Kiterunner | API endpoint discovery |
| **API** | Clairvoyance | GraphQL без introspection |
| **Smart Contract** | Echidna | Продвинутый фаззинг |
| **Smart Contract** | Aderyn | Быстрый Rust analyzer |
| **Recon** | AutoRecon / Osmedeus | Автоматизация разведки |

### Tier 3 — Дополнительно

| Категория | Инструмент | Почему |
|-----------|-----------|--------|
| **AI** | PyRIT, LLM Guard | AI security расширение |
| **Cloud** | ScoutSuite, Checkov | IaC/cloud |
| **Web** | DeepAudit | Мультиагентный AI аудит (изучить архитектуру!) |
| **Reporting** | Faraday, Ghostwriter | Альтернативы DefectDojo |

---

## 🔗 Интеграционная Архитектура

```
┌─────────────────────────────────────────────┐
│           0xAudit Multi-Agent Hub           │
│         (Orchestrator / Edward)             │
├─────────────┬───────────┬───────────────────┤
│  Web Agent  │ SC Agent  │  Infra Agent      │
│  ┌────────┐ │ ┌───────┐ │ ┌──────────┐      │
│  │ Nuclei │ │ │Slither│ │ │ Prowler  │      │
│  │ ZAP    │ │ │Mythril│ │ │ Trivy    │      │
│  │Kiterun.│ │ │Foundry│ │ │ScoutSuite│      │
│  └────────┘ │ │Echidna│ │ └──────────┘      │
│             │ │Aderyn │ │                   │
│             │ └───────┘ │                   │
├─────────────┼───────────┼───────────────────┤
│  AI Agent   │ Pentest   │  Report Agent     │
│  ┌────────┐ │ ┌───────┐ │ ┌──────────┐      │
│  │ Garak  │ │ │Pentest│ │ │DefectDojo│      │
│  │ PyRIT  │ │ │  GPT  │ │ │ CVSS Calc│      │
│  │LLMGuard│ │ │AutoRec│ │ │ Markdown │      │
│  └────────┘ │ └───────┘ │ └──────────┘      │
└─────────────┴───────────┴───────────────────┘
```

---

## 📌 Next Steps

1. **Установить Tier 1 инструменты** на сервер 0xAudit
2. **Создать wrapper-скрипты** для каждого инструмента (единый JSON output)
3. **Интегрировать DefectDojo** как центральный хаб отчётности
4. **Изучить архитектуру DeepAudit** — они решают похожую задачу мультиагентного аудита
5. **Добавить AI Security** как новый сервис (Garak + PyRIT)
6. **Создать Nuclei custom templates** для специфичных клиентских проверок

---

*Исследование актуально на 2026-02-09. Stars приблизительные, основаны на данных GitHub.*
