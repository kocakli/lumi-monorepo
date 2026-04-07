# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Lumi is a positivity-focused messaging app. Users send and receive anonymous kind messages, filtered by a multi-layer AI moderation pipeline. The primary language is English.

**Firebase Project**: `lumi-tease` (region: `eur3` / Europe)
**Bundle ID**: `com.tease.lumi`

## Monorepo Structure

- `apps/lumi-ios/` — Native iOS app (SwiftUI, WidgetKit)
- `backend/functions/` — Firebase Cloud Functions (TypeScript, ESM)
- `docs/` — PRD, tech stack, project plan

## Backend (Firebase Cloud Functions)

**Stack**: TypeScript (ESM), Node.js 20, Firebase Admin SDK v13 (modular imports), Gemini AI (`@google/genai`), firebase-functions v7

**All backend code lives in a single file**: `backend/functions/src/index.ts` (~1300 lines, no separate modules yet).

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
- `messages` — `text`, `senderId`, `mood`, `status` (pending/approved/rejected/shadowbanned/rate_limited/pending_review/expired), `approvedAt`, `createdAt`
- `users` — `isBanned`, `connectionCode`, `strikes`, `fcmToken`, `notificationPrefs`, `createdAt`
- `users/{uid}/vault/{msgId}` — saved messages subcollection (`text`, `mood`, `savedAt`)
- `connections` — `users[]`, `establishedAt`, keyed by sorted UID pair
- `notifications` — `userId`, `type`, `messageId`, `createdAt`, `read`
- `reports` — `messageId`, `reporterId`, `reason`, `status`, `createdAt`
- `support_tickets` — `userId`, `issueText`, `status`, `createdAt`
- `ratings` — `messageId`, `userId`, `rating` (positive/negative), `createdAt`
- `config/moderation` — runtime-configurable moderation model name (no redeploy needed)

**Cloud Functions (12)**:
- `moderateMessageBatch` — Scheduled (every 15 min). Batch-processes pending messages through pre-filters → Gemini AI moderation. Assigns mood, manages strikes (3 → auto-ban)
- `getMessageFeed` — Callable. Returns batch of approved messages user hasn't rated yet, supports mood filtering
- `getRandomMessage` — Callable. Returns single random approved message (older API)
- `saveToVault` — Callable. Saves to user's vault subcollection, notifies original sender
- `checkConnectionCode` — Callable. Mutual code match with duplicate/self-match protection
- `reportMessage` — Callable. Submits message report
- `generateConnectionCode` — Callable. Creates unique LUMI-XXXX code (no ambiguous chars)
- `submitSupportTicket` — Callable. Creates support ticket
- `rateMessage` — Callable. Swipe rating (positive/negative) with duplicate/self-rating protection, updates message score atomically
- `processReports` — Scheduled (every 15 min). Re-moderates reported messages, auto-shadowbans at 5+ reports
- `sendScheduledNotifications` — Scheduled (hourly). Sends push notifications based on user preferences, timezone, and schedule
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

**Targets**: iOS 17.0+, Swift 5.9

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
- `LumiApp.swift` — Entry point with `AppRouter` (ObservableObject) for navigation. Write screen is a sheet overlay, other screens swap via `currentScreen` enum (`.home`, `.write`, `.receive`, `.settings`, `.vault`)
- Both `AuthService` and `AppRouter` are injected via `.environmentObject()` from `LumiApp`

**Services** (5 singletons):
- `AuthService` — Anonymous Firebase Auth on init, publishes `uid` and `isReady`
- `CloudFunctionService` — Wraps all Firebase callable functions (`europe-west1` region). Defines `LumiMessage` model
- `WidgetDataService` — Shared data for WidgetKit via App Groups (`group.com.tease.lumi`)
- `NotificationService` — FCM token management, notification preference sync, permission handling
- `SensitiveDaysService` — Marks sensitive dates, triggers gentler mood defaults

**ViewModels**: `WriteMessageViewModel`, `VaultViewModel`, `MessageFeedViewModel` (manages swipe stack state: `loadFeed`, `swipeRight/Left`, `saveCurrentMessage`, `reportCurrentMessage`)

**Views**: `ContentView` (home), `ReceiveMessageView` (swipe stack), `WriteMessageView` (compose modal), `VaultView`, `SettingsView`, `ConnectionCodeView`, `ShareMessageView`, `MessageSentView`, `NotificationPermissionView`, `NotificationSettingsView`

**Widget** (`LumiWidget`): Hourly rotating positive messages. Supports systemSmall/Medium/Large and lock screen (accessoryRectangular/accessoryInline). Data shared via App Groups, not Firestore.

**Current state**: Firebase SDK is integrated (Auth, Firestore, Functions, Messaging via SPM). Auth and Cloud Functions networking layer exist. Some views still use mock data. No tests. No linting or CI/CD configured.

## Firestore Security Rules

Rules are in `firestore.rules`. Key constraints to maintain when modifying functions:
- Messages must be created with status `"pending"` — Cloud Functions handle all status transitions
- Users cannot modify their own `isBanned` or `strikes` fields
- Reports and support tickets are write-only from clients (no client reads)
- Connections are read-only from clients (created by Cloud Functions only)
- Composite indexes defined in `firestore.indexes.json` for messages (status+approvedAt, status+mood+approvedAt, senderId+createdAt) and ratings (userId+messageId)
