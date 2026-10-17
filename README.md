<p align="center">
  <b>█▀▀ █▀█ █▀▀ █░█ █▄░█</b>&nbsp;&nbsp;<a href="https://t.me/+oLvLfkydwG8xMWFi">💬 Telegram community</a>
</p>

# openglm

> **GLM console agent** — a themed OpenCode mod that puts GLM-5.3 Flash (Free) into your terminal, matrix-style, with commands, a baked splash animation, skills and zero cost.

Run OpenCode in a phosphor-green **matrix/phosphor** terminal theme with a tuned **GLM persona**, ready-made commands and a free default model. No API keys, no bills — GLM-5.3-flash-free runs on OpenCode's free tier.

**English quickstart at the bottom. 🇬🇧**

---

## Что это

Мод-пак для [OpenCode](https://opencode.ai): тема, персона-агент, команды, бренд-анимация и дефолтная бесплатная модель. После установки твой терминал выглядит как CRT-консоль из «Матрицы», а код пишет GLM.

| Компонент | Что делает |
|---|---|
| 🎨 Тема `openglm` | Полный V2-шаблон: фосфорно-зелёный на чёрном, свои diff/синтаксис/markdown-цвета |
| 🎬 Бренд-анимация | Вшитый ASCII-сплэш при запуске + живая полоска над полем ввода чата + команда `/gif` |
| 🤖 Агент `glm` | Персона: прямой стиль, без воды, отвечает на языке пользователя, код — артефактами |
| ⚡ Команды | `/glm` — активировать персону, `/deep` — глубокое планирование перед кодом, `/skills` — обзор скиллов, `/tg` — открыть наш Telegram |
| 🥷 Команда `claudecode` | Welcome-экран в стиле Claude Code: `/opus` `/sonnet` `/haiku` `/fable` переключают модели одним вводом |
| 🧠 Дефолт-модель | `opencode/glm-5.3-flash-free#low` — бесплатно, быстро, логин в OpenCode один раз |
| 💬 Сообщество | [Telegram-чат](https://t.me/+oLvLfkydwG8xMWFi) — открывается раз в день при запуске консоли и после установки |

## Установка (Windows, одна строка — ничего ставить не нужно)

Установка — это **одна команда** в PowerShell. Скрипт сам скачает и мод, и движок OpenCode (один portable-exe), и настроит всё:

```powershell
powershell -c "irm https://raw.githubusercontent.com/dmitryrublev04-cpu/openglm/main/install.ps1 | iex"
```

После этого — **новое окно терминала** и:

```
openglm
```

Первый запуск: `/login` (бесплатная учётка OpenCode) — и GLM работает бесплатно.

Никаких установщиков приложений: движок — один `opencode.exe` в `~\.opencode\bin\`, конфиги — текстовые файлы в `~\.config\opencode\`. Удалить всё = удалить эти две папки.

## Как это работает

1. **Bootstrap.** `install.ps1` скачивает мод (если его нет рядом), portable-движок OpenCode с официального GitHub Releases (версия запинована для безопасности) и зависимости бренд-плагина (один zip из Releases этого репо).
2. **Конфиги.** Пишутся `~\.config\opencode\cli.json` (тема, комфорт, регистрация плагина) и `opencode.json` (модель, права).
3. **Плагин `openglm-brand`** грузится OpenCode CLI при старте TUI: рисует вшитый ASCII-сплэш, живую полоску над полем ввода и команду `/gif`. Кадры запечены в код — без настроек и внешних запросов.
4. **Лаунчер `openglm`** (в `~\openglm\bin`, добавляется в PATH) находит движок и запускает TUI; раз в день открывает Telegram-сообщество.
5. **Модель.** Дефолт — `opencode/glm-5.3-flash-free#low` (вариант `#low` = быстрые ответы). Free-тариф OpenCode гейтится на уровне клиента: залогинься один раз через `/login`.

### Если видишь «Retrying… Upstream request failed»

Это волны нагрузки на бесплатный эндпоинт, не твоя сеть. Ретраи почти всегда пробивают (просто медленнее). Запасной ход: переключись в `/models` на `opencode/deepseek-v4.1-flash-free` — тот же бесплатный тир, тот же логин — и вернись на GLM через час-другой.

## Безопасность: что мод делает и чего не делает

- **Никаких секретов.** В репо и конфигах нет ключей, токенов и телеметрии — проверь `install.ps1`, это ~200 читаемых строк.
- **HTTPS-only + TLS 1.2.** Все загрузки идут по HTTPS с GitHub; движок скачивается с **запинованной версии** релиза (`v2.0.31`), а не безлимитного `latest`.
- **Права агента** включают автозапуск команд ради скорости, но с предохранителями: чтение `.env` — спросит, `format` и `shutdown` — запрещены, `rmdir /s` — спросит.
- **Плагин** не ходит в сеть и не исполняет ничего внешнего — только рисует текстовые кадры.
- Скрипт **не требует администратора** и ничего не пишет вне `~\.opencode`, `~\.config\opencode`, `~\openglm`.

## Кастомизация

**Скиллы.** OpenCode читает скиллы из `~/.config/opencode/skills` и `.opencode/skills` проекта — общий формат [agentskills.io](https://agentskills.io). Кладёшь папку с `SKILL.md` — скилл доступен. Пример:

```bash
npx skills add hardikpandya/stop-slop          # пишет без ИИ-штампов
npx skills add coreyhaines31/marketingskills   # 50 маркетинговых
```

Точечное отключение скилла: `metadata: { opencode/autoinvoke: false }` в его `SKILL.md`.

**Тема.** Правь `~/.config/opencode/themes/openglm.json` — hues, tokens, states: [docs](https://opencode.ai/v2/docs/themes/). Хочешь другой вайб (amber, vercel) — меняй палитру в блоке `dark.hue`.

**Модель.** `"model"` в `~/.config/opencode/opencode.json` или переключай на лету через `/models`. Любой провайдер (llm7, локальный ollama, LM Studio) — [docs/providers](https://opencode.ai/v2/docs/providers/).

**Агент.** Тон персоны — `~/.config/opencode/agent/glm.md`. Temperature, разрешения инструментов — там же, [docs/agents](https://opencode.ai/v2/docs/agents/).

**Анимация (для контрибьюторов).** Кадры генерируются из GIF/Videos утилитой `tools/bake-gif.mjs` (node + `npm i omggif ffmpeg-static`), результат кладётся в `opencode/plugins/openglm-brand/src/frames.ts`.

## Что внутри репо

```
openglm/
├── install.ps1                          # установщик Windows (bootstrap)
├── bin/openglm.cmd                      # лаунчер (команда openglm)
├── opencode/
│   ├── themes/openglm.json              # matrix/phosphor тема
│   ├── agent/glm.md                     # персона GLM
│   ├── commands/                        # glm, deep, skills, tg
│   └── plugins/openglm-brand/           # TUI-плагин: сплэш, полоска, /gif
├── tools/bake-gif.mjs                   # генератор кадров анимации
└── LICENSE
```

Зависимости плагина (`node_modules`) не хранятся в репо — они скачиваются один раз из [Releases](../../releases) как `openglm-brand-deps.zip`.

## Honest disclaimer

- **GLM-5.3** — модель Z.ai. Мод не «внутри себя» её не содержит, а дергает через OpenCode: free-тариф, лимиты на человека применяются UPSTREAM.
- Не аффилирован с OpenCode и Z.ai. Тема, персона и плагин — MIT.
- Telegram в моде открывается **раз в сутки** (маркер-файл `.tg-last`), а не на каждый запуск — мы уважаем нервы пользователей.

---

## 🇬🇧 English

**openglm** is a theme + persona + commands + brand-animation mod for [OpenCode](https://opencode.ai). After installing, your terminal gets a matrix/phosphor look and GLM-5.3 Flash Free as the default model (free via OpenCode's free tier). Community: [Telegram](https://t.me/+oLvLfkydwG8xMWFi).

```powershell
powershell -c "irm https://raw.githubusercontent.com/dmitryrublev04-cpu/openglm/main/install.ps1 | iex"
openglm
```

First run: `/login` once (free OpenCode account). Commands: `/glm` (persona), `/deep` (plan-first mode), `/skills` (list skills), `/tg` (open Telegram), `/gif` (replay the splash animation). If the free endpoint hiccups with `Retrying…`, switch to `opencode/deepseek-v4.1-flash-free` in `/models` — same free tier.

The installer is ~200 readable lines: HTTPS-only with TLS 1.2, a pinned engine release, no admin rights, no secrets, no telemetry. Customize the theme in `~/.config/opencode/themes/openglm.json`, the persona in `agent/glm.md`, the model in `opencode.json`.

MIT © keep the phosphor green.
