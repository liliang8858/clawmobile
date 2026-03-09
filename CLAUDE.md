# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Generate Xcode project from project.yml (required after config changes)
xcodegen generate

# Build
xcodebuild -project ClawMobile.xcodeproj -scheme ClawMobile \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Build (quiet, errors only)
xcodebuild -project ClawMobile.xcodeproj -scheme ClawMobile \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

No test target exists yet. No linter configured. No SPM/CocoaPods dependencies.

## Architecture

SwiftUI + MVVM with `@Observable` (iOS 18+). All ViewModels are `@MainActor @Observable final class` and injected via `.environment()`.

**Service layer:**
- `OpenClawService` — real WebSocket client connecting to a local OpenClaw agent. Discovers agents by scanning localhost ports (18789, 3000, 8080) via `/health`, then connects via WebSocket using a JSON-RPC-style protocol (`type: req/res/event`).
- `MockService` — hardcoded demo data, used when no agent is found.
- `L10n` — localization singleton (Chinese default, English alternative), stored in UserDefaults.

**Data flow:** Views → ViewModels → OpenClawService (WebSocket) → OpenClaw backend. Chat uses streaming events (delta/final/error/aborted). Tool executions can require user approval via `exec.approval.requested` events.

## Key Conventions

**SwiftUI styling:** Use `foregroundStyle(Color.accentColor)` not `.accentColor`. Dark theme is set globally.

**Concurrency:** `SWIFT_STRICT_CONCURRENCY = minimal`. Use `@unchecked Sendable` for structs containing `[String: Any]` (see `AnyCodable`, `ChatEvent`).

**XcodeGen:** `project.yml` is the source of truth. PRODUCT_NAME must not contain spaces. Run `xcodegen generate` after any changes.

**ATS:** Info.plist allows local networking (`NSAllowsLocalNetworking` + `NSAllowsArbitraryLoads`) for localhost agent discovery and WebSocket.

**Gateway token:** Read from `~/.openclaw/openclaw.json` → `gateway.auth.token`. Used as WebSocket auth header.

## Protocol Reference

```
Request:  {"type":"req","id":"uuid","method":"sessions.list","params":{}}
Response: {"type":"res","id":"uuid","ok":true,"payload":{...}}
Event:    {"type":"event","event":"chat.message","payload":{...}}
```

Key methods: `sessions.list`, `chat.send`, `chat.history`, `chat.abort`, `cron.list`, `cron.add`, `cron.run`, `cron.remove`, `exec.approval.resolve`, `agent.identity.get`, `status`.
