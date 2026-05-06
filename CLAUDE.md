# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Lumi is a positivity-focused messaging app. Users send and receive anonymous kind messages, filtered by a multi-layer AI moderation pipeline. The primary language is English.

**Firebase Project**: `lumi-tease` (region: `eur3` / Europe)
**Bundle ID**: `com.tease.lumi`

## Monorepo Structure

- `apps/lumi-ios/` — Native iOS app (SwiftUI, WidgetKit, watchOS companion)
- `apps/lumi-android/` — Android port via Skip Fuse (Swift transpiled to Kotlin); shares Firebase + the Localizable.xcstrings format with iOS
- `backend/functions/` — Firebase Cloud Functions (TypeScript, ESM)
- `docs/` — PRD, tech stack, project plan
- `marketing/app-store-screenshots/` — App Store screenshot assets and GPT-generated per-language marketing imagery (iPhone + iPad, 10 locales)

**Sibling doc**: [`AGENTS.md`](./AGENTS.md) is the Codex/Codex.ai equivalent of this file — same project context, separate audience. Keep meaningful project-architecture changes in sync between the two; both files exist and the team uses both tools. AGENTS.md is intentionally shorter than this file (no design-system or screenshot-mode detail), but the Monorepo Structure, Backend stack/runtime, and platform list should match.

## Backend (Firebase Cloud Functions)

**Stack**: TypeScript (ESM), Node.js 22 (engines), Firebase Admin SDK v13 (modular imports), Gemini AI (`@google/genai`), firebase-functions v7. Runtime was bumped from Node 20 → 22 ahead of the 2026-04-30 Node 20 deprecation; if you change `engines.node`, the next deploy will migrate **all** functions to that runtime.

**All backend code lives in a single file**: `backend/functions/src/index.ts` (~2200 lines, no separate modules yet). Helpers live above the exported handlers; section ordering is moderation helpers → callable handlers → scheduled jobs.

**Install & build**:
```bash
cd backend/functions && npm install
npm run build        # tsc → lib/
npm run build:watch  # tsc --watch (dev mode)
npm run serve        # build + firebase emulators (functions only)
npm run deploy       # firebase deploy --only functions
npm run logs         # firebase functions:log
```

**TypeScript config**:
- `"type": "module"` in package.json — all code is ESM
- `"module": "nodenext"`, `"strict": true`, `"verbatimModuleSyntax": true` — use `import type` for type-only imports
- `"noUncheckedIndexedAccess": true` — handle `undefined` from indexed access
- Uses Firebase Admin v2 modular imports (`firebase-admin/app`, `firebase-admin/firestore`, `firebase-admin/messaging`), NOT `* as admin`
- Uses firebase-functions v2 (`firebase-functions/v2/https`, `firebase-functions/v2/scheduler`)
- Secrets via `defineSecret` from `firebase-functions/params`
- All functions deployed to `europe-west1` region
- Output dir is `lib/` (not `dist/`)

**Secrets**:
- `GEMINI_API_KEY` — set via `firebase functions:secrets:set GEMINI_API_KEY`

**Firestore collections**:
- `messages` — `text`, `senderId`, `mood`, `status` (pending/approved/rejected/shadowbanned/rate_limited/pending_review/expired), `approvedAt`, `createdAt`. Optional `targetUserId` makes the message a private/paired delivery; security rules allow that recipient to read it
- `users` — `isBanned`, `connectionCode`, `strikes`, `fcmToken`, `notificationPrefs`, `createdAt`. Clients cannot mutate `isBanned` or `strikes` (rule-enforced)
- `users/{uid}/vault/{msgId}` — saved messages subcollection (`text`, `mood`, `savedAt`)
- `pair_requests` — `fromUserId`, `toUserId`, `status` (pending/accepted/declined/cancelled). Read-only to participants; only Cloud Functions write
- `connections` — `users[]` (sorted UID pair, used as doc ID), `establishedAt`, `nicknames` (map of uid → label). Clients can update **only** `nicknames` via security rules; the rest is Cloud-Function-managed
- `notifications` — `userId`, `type`, `messageId`, `createdAt`, `read`
- `reports` — `messageId`, `reporterId`, `reason`, `status`, `createdAt` (write-only from clients)
- `support_tickets` — `userId`, `issueText`, `status`, `createdAt` (write-only from clients; rules block client reads entirely)
- `ratings` — `messageId`, `userId`, `rating` (positive/negative), `createdAt`
- `config/moderation` — runtime-configurable moderation model name (no redeploy needed)

**Cloud Functions (20)** — all in `europe-west1`:

*Anonymous message flow*:
- `moderateMessageBatch` — Scheduled (every 15 min). Batch-processes pending messages through pre-filters → Gemini AI moderation. Assigns mood, manages strikes (3 → auto-ban)
- `getMessageFeed` — Callable. Returns batch of approved messages user hasn't rated yet, supports mood filtering
- `getRandomMessage` — Callable. Single random approved message (older single-card API; kept for back-compat)
- `rateMessage` — Callable. Swipe rating (positive/negative) with duplicate/self-rating protection, updates message score atomically
- `saveToVault` — Callable. Saves to user's vault subcollection, notifies original sender
- `reportMessage` — Callable. Submits message report
- `processReports` — Scheduled (every 15 min). Re-moderates reported messages, auto-shadowbans at 5+ reports

*Pairing system* (1:1 private messaging between known users):
- `generateConnectionCode` — Callable. Creates unique LUMI-XXXX code (no ambiguous chars)
- `checkConnectionCode` — Callable. Legacy mutual-code matching path (kept; pair-request flow is preferred)
- `sendPairRequest` — Callable. Creates a `pair_requests` doc; pushes FCM notification to recipient
- `respondToPairRequest` — Callable. Accept/decline; on accept, creates `connections` doc keyed by sorted UID pair
- `getPairRequests` — Callable. Lists incoming/outgoing pair requests
- `dissolvePair` — Callable. Tears down a connection
- `getMyPairs` — Callable. Lists active connections
- `updatePairNickname` — Callable. Sets the calling user's nickname for the partner inside `connections.nicknames`
- `sendPairMessage` — Callable. Creates a `messages` doc with `targetUserId` so it's delivered only to the paired user (still goes through moderation pipeline)

*Account & lifecycle*:
- `submitSupportTicket` — Callable. Creates support ticket
- `deleteAccount` — Callable. Account deactivation: wipes user data and Auth record
- `sendScheduledNotifications` — Scheduled (hourly). Sends push notifications based on user preferences, timezone, and schedule (uses `getLocalHour()` helper)
- `cleanupPendingMessages` — Scheduled (daily). Expires stale pending_review messages after 7 days

**Moderation pipeline** (in `moderateMessageBatch`):
1. **Pre-filters** (zero AI cost, instant rejection):
   - `normalizeText()` — Unicode normalization (Turkish dotless ı, accents, fullwidth digits, leet-speak)
   - `checkProfanity()` — 98+ terms (English + Turkish), word-boundary + obfuscation patterns
   - `checkPhoneNumber()` — detects 7+ clustered digits
   - `checkContactInfo()` — URLs, emails, platform names (Instagram, TikTok, etc.)
   - `checkSpam()` — promo keywords, excessive caps (>50%), 5+ repeated chars
2. **Shadowban check** → **Rate limit** (10/hr) → pre-filters → **Gemini AI** (only if pre-filters pass)
3. **Gemini** (`gemini-2.0-flash-lite` default, configurable via `config/moderation` doc): detects language, assigns mood (Playful/Peaceful/Motivating/Romantic), approves or rejects
4. **Strike system**: 3 strikes → permanent ban (`isBanned` on user doc)

**Firebase config files** (repo root):
- `firebase.json` — Firestore + Functions config
- `.firebaserc` — project alias (default → lumi-tease)
- `firestore.rules` — Security rules
- `firestore.indexes.json` — Composite indexes for messages queries

## iOS App (SwiftUI)

**Structure**: `apps/lumi-ios/Lumi/` for main app, `apps/lumi-ios/LumiWidget/` for WidgetKit extension

**Project generation**: Uses XcodeGen via `project.yml`. The `.xcodeproj` is gitignored and must be regenerated:
```bash
cd apps/lumi-ios && xcodegen generate
```
Requires `xcodegen` installed (`brew install xcodegen`).

**Targets** (defined in `project.yml`):
- `Lumi` — main iOS app, iOS 17.0+, Swift 5.9, bundle `com.tease.lumi`
- `LumiWidgetExtension` — WidgetKit extension for `Lumi`, App Group `group.com.tease.lumi`
- `LumiWatch` — watchOS 10.0+ companion app, bundle `com.tease.lumi.watchkitapp`, App Group `group.com.tease.lumi.watch`. Companion-only (`WKRunsIndependentlyOfCompanionApp: false`); no direct Firestore access — receives data from the phone via WatchConnectivity
- `LumiWatchComplication` — watchOS WidgetKit app-extension embedded in `LumiWatch`, bundle `com.tease.lumi.watchkitapp.widget`
- All four targets share `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`; bumping the build means editing all four blocks in `project.yml`

**SPM dependencies**: firebase-ios-sdk v11 (Auth, Firestore, Functions, Messaging), lottie-ios v4

**Firebase config**: `GoogleService-Info.plist` is in `apps/lumi-ios/Lumi/`

**Design system** (`LumiTheme.swift`):
- "Zen Garden / Digital Sanctuary" aesthetic — Japanese minimalism with glassmorphism
- Background: warm off-white `#FAF9F6`, with aurora gradient overlays (`AuroraBackground`)
- Typography: NotoSerifDisplay (Light/300) for display, NotoSerif-Regular for headlines, PlusJakartaSans for body
- Glass effects via `.zenGlass()` modifier (ultraThinMaterial + white overlay + border), with iOS 26 `.glassEffect` progressive enhancement
- Corner radii: 12 (small), 20 (medium), 28 (large), 36 (XL), 9999 (pill)
- Reusable components: `LumiHeader`, `FloatingBottomBar`, `GlassNavIcon`, `ZenLabel`, `MoodPill`

**Architecture**:
- `LumiApp.swift` — Entry point with `AppRouter` (ObservableObject) for navigation. Write screen is a sheet overlay, other screens swap via `currentScreen` enum (`.home`, `.write`, `.receive`, `.settings`, `.vault`, plus pair screens)
- `AppDelegate.swift` — Handles APNs registration, FCM token handoff, and incoming notification routing (set via `@UIApplicationDelegateAdaptor` in `LumiApp`)
- `AuthService`, `AppRouter`, and pair state are injected via `.environmentObject()` from `LumiApp`

**Services** (6 singletons in `Lumi/Services/`):
- `AuthService` — Anonymous Firebase Auth on init, publishes `uid` and `isReady`
- `CloudFunctionService` — Wraps all Firebase callable functions (`europe-west1` region). Defines `LumiMessage` model and pair-related types
- `WidgetDataService` — Shared data for WidgetKit via App Groups (`group.com.tease.lumi`)
- `NotificationService` — FCM token management, notification preference sync, permission handling
- `SensitiveDaysService` — Marks sensitive dates, triggers gentler mood defaults
- `WatchConnectivityService` — One-way iPhone → Apple Watch handoff via WCSession; pushes the latest received message and sensitive-day flags to the watch (the watch has no Firebase SDK)

**ViewModels** (`Lumi/ViewModels/`): `WriteMessageViewModel`, `VaultViewModel`, `MessageFeedViewModel` (manages swipe stack: `loadFeed`, `swipeRight/Left`, `saveCurrentMessage`, `reportCurrentMessage`), `PairingViewModel` (pair requests + active pairs + nicknames)

**Views** (`Lumi/Views/`): `ContentView` (home), `ReceiveMessageView` (swipe stack), `WriteMessageView` (compose modal), `VaultView`, `SettingsView`, `ConnectionCodeView`, `ShareMessageView`, `MessageSentView`, `NotificationPermissionView`, `NotificationSettingsView`, plus pairing UI: `PairsListView`, `PairMessageBanner`, `PairRequestBanner`, `PairingSuccessAnimation`

**Resources**: `splash.mp4` (launch video), `paper-plane.lottie` / `paper-plane.json` (send animation), bundled in `Lumi/` and shared into the widget target via `project.yml`

**Widget** (`LumiWidget/LumiWidget.swift`): Hourly rotating positive messages. Supports systemSmall/Medium/Large and lock screen (accessoryRectangular/accessoryInline). Data shared via App Groups (`group.com.tease.lumi`), not Firestore.

**watchOS companion** (`LumiWatch/`, `LumiWatchComplication/`): Sibling source dirs to `Lumi/`, declared as their own targets in `project.yml`. The watch is companion-only — no Firebase SDK, no Firestore reads. State arrives from the phone via `WatchConnectivityService` (`WCSession`): the latest received message and sensitive-day flags are pushed each time the phone updates them. The complication target is a WidgetKit app-extension embedded in `LumiWatch` (`embed: true`) and shares its own App Group `group.com.tease.lumi.watch`. Both targets pull fonts from `Lumi/Fonts` via the `project.yml` resource buildPhase rather than duplicating the font files.

**Build / version**: `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` are set in `project.yml` (currently 1.0.0 / build 20). All four targets (Lumi, LumiWidgetExtension, LumiWatch, LumiWatchComplication) carry the same version; bumping the build requires editing all four blocks in `project.yml` and re-running `xcodegen generate`.

**Localization**: App ships with 10 languages (see commit `b360e68e`). Localization files live under `Lumi/Resources/`.

**Screenshot mode** (`Lumi/ScreenshotMode.swift`): DEBUG-only launch-argument hook used by the App Store screenshot pipeline. Launch flags: `-LumiScreenshotMode`, `-LumiScreen <home|receive|vault|settings|connection|share>`, `-LumiLanguage <locale>`. When enabled, the splash is bypassed and `LumiApp` swaps in a fixed screen with hard-coded localized sample data (across all 10 languages) instead of the live router-driven flow. Used for generating the assets in `marketing/app-store-screenshots/`. Production builds compile this out (`#if DEBUG`).

**Current state**: Auth, Firestore, Functions, Messaging integrated via SPM. Pairing system, push notifications (with scheduled hourly job), account deactivation, ambient audio, and the watchOS companion all ship in build 20. Build 20 also denormalizes a `senderDisplayName` onto each paired message doc (recipient's nickname for the sender, falling back to the sender's LUMI-XXXX connection code) so paired messages always carry a sender attribution — both in the swipe-stack pair badge and in the live `PairMessageBanner` overlay. Backend runs on Node 22 with 20 functions deployed in `europe-west1`. No tests. No linting or CI/CD configured.

## Android App (Skip Fuse)

`apps/lumi-android/` is a [Skip Fuse](https://skip.tools) cross-compile target: Swift sources in `Sources/LumiAndroid/` (29 files) are transpiled to Kotlin by the `skipstone` SwiftPM plugin and packaged into an Android APK by Gradle. **Bundle ID `com.tease.lumi`** (matches iOS); **Android package `lumi.android`**. The codebase is a parallel adaptation of the iOS app, **not shared code** — Skip-bridged APIs (`SkipFuseUI`, `SkipFirebase*`) take the place of UIKit/Firebase imports, and iOS-only features are gated with `#if !os(Android)`.

**Layout**:
- `Skip.env` — single source of truth for product name, bundle ID, version, and Android package; read by both `Darwin/LumiAndroid.xcconfig` and `Android/settings.gradle.kts`. Currently `MARKETING_VERSION 1.0.0` / `CURRENT_PROJECT_VERSION 2`. **Bump versions here, not in `build.gradle.kts`** — Gradle reads from `Skip.env`.
- `Package.swift` — Swift 6.1 manifest. Depends on `skip` 1.8.13+, `skip-fuse-ui`, `skip-firebase` (Core/Auth/Firestore/Functions/Messaging), and `skip-motion`. Uses `swiftLanguageMode(.v5)` to keep `[String: Any]` Firestore payloads compatible with the iOS app's Swift 5.9 strict-concurrency posture.
- `Sources/LumiAndroid/` — `App/`, `Views/`, `ViewModels/`, `Services/`, `Theme/`, `Models/`, `Resources/`. Mirrors the iOS app's layout. Services include `AuthService`, `CloudFunctionService`, `NotificationService`, `SensitiveDaysService`, `WidgetDataService` (no `WatchConnectivityService` — Android has no Apple Watch path).
- `Android/app/build.gradle.kts` — Gradle build, namespace `lumi.android`, applies `com.google.gms.google-services`. Release signing pulls from `Android/app/keystore.properties` and throws `GradleException` if missing.
- `Android/app/src/main/kotlin/Main.kt` — `AndroidAppMain` (Application — creates the `lumi.message` notification channel with the bundled custom sound) plus `MainActivity` (ComponentActivity, Compose root, FCM registration, screenshot-mode capture from intent extras). Edge-to-edge system bars and dark-theme detection are handled here.
- `Android/fastlane/metadata/android/` — Play Store metadata. Title "Lumi - Letters in the Wind", short + full descriptions, 10 locales (en-US, tr-TR, fr-FR, de-DE, es-ES, ja-JP, it-IT, ko-KR, pt-BR, zh-Hans).
- `Sources/LumiAndroid/Resources/Localizable.xcstrings` — same `.xcstrings` format as the iOS app, ~10 locales × ~141 keys. **This is a separate file from the iOS Localizable.xcstrings — keep terminology in sync manually when adding strings.**
- `Sources/LumiAndroid/ScreenshotMode.swift` — mirrors the iOS pattern: toggled via `UserDefaults("LumiScreenshotMode")` or intent extras (`-LumiScreenshotMode`, `-LumiScreen`, `-LumiLanguage`); same hardcoded sample data shape across 10 languages, used to drive Play Store screenshot generation.

**Build commands**:
```bash
cd apps/lumi-android
skip app launch --android   # full pipeline: compile Swift → transpile to Kotlin → Gradle build → adb install → launch
```
End-to-end takes ~57s on a warm cache. Requires the `skip` CLI installed (see [skip.tools](https://skip.tools)) and a connected device or emulator. The build emits `libLumiAndroid.so` plus the SkipFirebase native `.so` libraries into the APK.

**Status**: Faz 11 (compile + first device boot) is complete — confirmed running on Galaxy Z Flip 4 (Android 16 / API 36) with the full Firebase stack reachable. Faz 12 (Play Console upload) is the next milestone. No CI; no automated tests.

**Constraints when working here**:
- Don't blindly bump `skip` or `skip-firebase` versions in `Package.swift` without re-running a full device build — the Kotlin transpilation surface is sensitive to upstream API changes, and `Package.resolved` is checked in for that reason.
- Don't commit `.build/`, `Android/build/`, or `Project.xcworkspace/xcuserdata/`.
- The iOS app and the Android app are intentionally independent codebases. Don't try to introduce a shared Swift module yet — Skip's bridging requires the source to live inside `Sources/LumiAndroid/` for the transpiler to see it.

## Firestore Security Rules

Rules are in `firestore.rules`. Key constraints to maintain when modifying functions:
- Messages must be created with status `"pending"` and `senderId == auth.uid`, `text` ≤ 200 chars — Cloud Functions handle all status transitions
- Optional `targetUserId` is allowed at creation; readers see a message only if `status == 'approved'` (and, for paired messages, they're the recipient)
- Users cannot modify their own `isBanned` or `strikes` fields
- `pair_requests` are entirely Cloud-Function-managed; participants can read but not write
- `connections` updates from clients are restricted to the `nicknames` field via `affectedKeys().hasOnly(['nicknames'])`
- Reports and support tickets are write-only from clients (no client reads)
- Default-deny fallback (`match /{document=**}`) ensures no collection is accidentally exposed
- Composite indexes defined in `firestore.indexes.json` for messages (status+approvedAt, status+mood+approvedAt, senderId+createdAt) and ratings (userId+messageId)
