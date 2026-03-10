# Claw Mobile

**Your AI Agent Control Center**

[中文文档](README.md)

Claw Mobile is the iOS client for the [OpenClaw](https://github.com/openclaw/openclaw) ecosystem. It provides remote management, control, and monitoring of AI Agents from your phone. Not just a chat tool — it's a mobile operating system for AI Agents.

> AI Agent = Digital Worker, Chat = Command Line, Claw Mobile = GUI

## Screenshots

| Connect | Sessions | Chat |
|:---:|:---:|:---:|
| ![Connect](docs/screen/start.png) | ![Sessions](docs/screen/index.png) | ![Chat](docs/screen/session.png) |

| Tasks | Memory | Settings |
|:---:|:---:|:---:|
| ![Tasks](docs/screen/task.png) | ![Memory](docs/screen/memory.png) | ![Settings](docs/screen/settings.png) |

## Features

| Module | Description |
|--------|-------------|
| **Agent Connect** | Auto-discover local agents or connect via token |
| **Session Chat** | Multi-session management with streaming responses and tool call visualization |
| **Tool Approval** | Approve or deny dangerous operations (shell commands, file deletions, etc.) |
| **Task Automation** | Create, view, and manage scheduled automation tasks (cron jobs) |
| **Memory Management** | Browse Agent's long-term memory (facts, preferences, knowledge) |
| **Bilingual Support** | Chinese (default) and English, switchable in settings |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | SwiftUI |
| Architecture | MVVM + @Observable |
| Real-time Communication | WebSocket |
| Local Storage | UserDefaults |
| Minimum Target | iOS 18.0 |
| Build Tool | XcodeGen |

## Getting Started

### Prerequisites

- macOS 15+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A running [OpenClaw](https://github.com/openclaw/openclaw) agent on localhost

### Build & Run

```bash
# 1. Clone the project
git clone <repo-url> && cd clawmobile

# 2. Generate Xcode project
xcodegen generate

# 3. Build
xcodebuild -project ClawMobile.xcodeproj \
  -scheme ClawMobile \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build

# 4. Install on simulator
xcrun simctl install booted \
  ~/Library/Developer/Xcode/DerivedData/ClawMobile-*/Build/Products/Debug-iphonesimulator/ClawMobile.app

# 5. Launch
xcrun simctl launch booted com.openclaw.ClawMobile
```

Or open `ClawMobile.xcodeproj` in Xcode and hit Run.

## Project Structure

```
clawmobile/
├── readme.md                          # Chinese README
├── README_EN.md                       # English README (this file)
├── project.yml                        # XcodeGen project config
├── docs/
│   ├── screen/                        # App screenshots
│   ├── PRD.md                         # Product requirements
│   ├── TECHNICAL_DESIGN.md            # Technical design
│   └── RESEARCH.md                    # Research & analysis
└── ClawMobile/
    ├── ClawMobileApp.swift            # App entry point
    ├── Models/                        # Data models
    ├── ViewModels/                    # View models (MVVM)
    ├── Views/                         # UI views
    ├── Services/
    │   ├── OpenClawService.swift      # WebSocket client
    │   └── L10n.swift                 # Localization
    └── Assets.xcassets/
```

## Roadmap

| Phase | Content | Status |
|-------|---------|--------|
| **MVP** | Agent connection, session chat, streaming, tool logs, task list, i18n | Done |
| **V1.0** | WebSocket integration, auto-discovery, cron management, memory browsing | Done |
| **V1.1** | Local cache (SQLite), push notifications | Planned |
| **V2** | Voice agent control | Planned |
| **V3** | Multi-agent collaboration | Planned |
| **V4** | Agent / Skill marketplace | Planned |

## Documentation

| Document | Description |
|----------|-------------|
| [Product Requirements](docs/PRD.md) | Product definition, user scenarios, feature modules |
| [Technical Design](docs/TECHNICAL_DESIGN.md) | System architecture, API design, data models |
| [Research](docs/RESEARCH.md) | OpenClaw architecture analysis, market research |

## License

MIT
