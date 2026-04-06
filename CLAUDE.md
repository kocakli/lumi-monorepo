# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Lumi is a positivity-focused messaging app. Users send and receive anonymous kind messages, filtered by an AI moderation layer. The primary language is English.

**Firebase Project**: `lumi-tease` (region: `eur3` / Europe)
**Bundle ID**: `com.tease.lumi`

## Monorepo Structure

- `apps/lumi-ios/` — Native iOS app (SwiftUI, WidgetKit)
- `backend/functions/` — Firebase Cloud Functions (TypeScript, ESM)
- `docs/` — PRD, tech stack, project plan

## Backend (Firebase Cloud Functions)

**Stack**: TypeScript (ESM), Firebase Admin SDK v2 modular imports, OpenAI API, firebase-functions v7

**All backend code lives in a single file**: `src/index.ts` (no separate modules yet).

**Install & build**:
```bash
cd backend/functions && npm install
npm run build        # tsc → lib/
npm run build:watch  # tsc --watch (dev mode)
npm run serve        # build + firebase emulators (functions only)
npm run deploy       # firebase deploy --only functions
npm run logs         # firebase functions:log
```

**Key details**:
- `package.json` has `"type": "module"` — all code is ESM
- `tsconfig.json`: `"module": "nodenext"`, `"strict": true`, `"verbatimModuleSyntax": true` — use `import type` for type-only imports
- `noUncheckedIndexedAccess` enabled — handle `undefined` from indexed access
- Uses Firebase Admin v2 modular imports (`firebase-admin/app`, `firebase-admin/firestore`), NOT `* as admin`
- Uses firebase-functions v2 (`firebase-functions/v2/firestore`, `firebase-functions/v2/https`, `firebase-functions/v2/scheduler`)
- All functions deployed to `europe-west1` region
- OpenAI API key must be set via `OPENAI_API_KEY` env var (use `firebase functions:secrets:set OPENAI_API_KEY`)
- Output dir is `lib/` (not `dist/`)

**Firestore collections**:
- `messages` — `text`, `senderId`, `mood`, `status` (pending/approved/rejected/shadowbanned/rate_limited/pending_review/expired), `approvedAt`, `createdAt`
- `users` — `isBanned`, `connectionCode`, `strikes`, `createdAt`
- `users/{uid}/vault/{msgId}` — saved messages subcollection
- `connections` — `users[]`, `establishedAt`, keyed by sorted UID pair
- `notifications` — `userId`, `type`, `messageId`, `createdAt`, `read`
- `reports` — `messageId`, `reporterId`, `reason`, `status`, `createdAt`
- `support_tickets` — `userId`, `issueText`, `status`, `createdAt`
- `ratings` — `messageId`, `userId`, `rating` (positive/negative), `createdAt`

**Cloud Functions (10)**:
- `onMessageCreated` — Firestore onCreate trigger. Shadowban check → rate limit (10/hr) → OpenAI moderation → 3-strike auto-ban
- `getRandomMessage` — Callable. Returns random approved message from pool, supports mood filtering, excludes own messages
- `saveToVault` — Callable. Saves to user's vault subcollection, notifies original sender
- `checkConnectionCode` — Callable. Mutual code match with duplicate/self-match protection
- `reportMessage` — Callable. Submits message report
- `generateConnectionCode` — Callable. Creates unique LUMI-XXXX code (no ambiguous chars)
- `submitSupportTicket` — Callable. Creates support ticket
- `rateMessage` — Callable. Swipe rating (positive/negative) with duplicate/self-rating protection, updates message score atomically
- `getMessageFeed` — Callable. Returns batch of approved messages user hasn't rated yet, supports mood filtering
- `cleanupPendingMessages` — Scheduled (daily). Expires stale pending_review messages after 7 days

**Firebase config files** (repo root):
- `firebase.json` — Firestore + Functions config
- `.firebaserc` — project alias (default → lumi-tease)
- `firestore.rules` — Security rules (validated)
- `firestore.indexes.json` — Composite indexes for messages queries

## iOS App (SwiftUI)

**Structure**: `apps/lumi-ios/Lumi/` for main app, `apps/lumi-ios/LumiWidget/` for WidgetKit extension

**Project generation**: Uses XcodeGen via `project.yml`. Generate the Xcode project with:
```bash
cd apps/lumi-ios && xcodegen generate
```
Requires `xcodegen` installed (`brew install xcodegen`). The `.xcodeproj` is gitignored and must be regenerated.

**Targets**: iOS 17.0+, Swift 5.9

**Firebase config**: `GoogleService-Info.plist` is in `apps/lumi-ios/Lumi/`

**Design system** (`LumiTheme.swift`):
- "Zen Garden / Digital Sanctuary" aesthetic — Japanese minimalism with glassmorphism
- Background: warm off-white `#FAF9F6` via `LumiTheme.background`, with aurora gradient overlays (`AuroraBackground`)
- Typography: NotoSerifDisplay (variable font, Light/300 weight) for display text, NotoSerif-Regular for headlines, PlusJakartaSans for body/labels
- Glass effects via `.zenGlass()` modifier (ultraThinMaterial + white overlay + border), with iOS 26 `.glassEffect` progressive enhancement
- Pink-tinted shadows: `rgba(121,80,61,0.06)`
- Corner radii: 12 (small), 20 (medium), 28 (large), 36 (XL), 9999 (full/pill)
- Reusable components: `LumiHeader`, `FloatingBottomBar`, `GlassNavIcon`, `ZenLabel`, `MoodPill`

**Architecture**:
- `LumiApp.swift` — App entry point with `AppRouter` (ObservableObject) for navigation. Write screen is a sheet overlay, other screens swap via `currentScreen` enum
- `Services/AuthService.swift` — Singleton, anonymous Firebase Auth on init, publishes `uid` and `isReady`
- `Services/CloudFunctionService.swift` — Singleton wrapping all Firebase callable functions (`europe-west1` region). Defines `LumiMessage` model
- `Services/WidgetDataService.swift` — Shared data for WidgetKit via App Groups (`group.com.tease.lumi`)
- `ViewModels/` — `WriteMessageViewModel`, `VaultViewModel`, `MessageFeedViewModel`
- Both `AuthService` and `AppRouter` are injected via `.environmentObject()` from `LumiApp`

**Widget** (`LumiWidget`): Hourly rotating positive messages. Supports systemSmall/Medium/Large and lock screen (accessoryRectangular/accessoryInline).

**Current state**: Firebase SDK is integrated (Auth, Firestore, Functions via SPM). Auth and Cloud Functions networking layer exist. Some views still use mock data. No tests.

## Firestore Security Rules

Rules are in `firestore.rules`. Key constraints to maintain when modifying functions:
- Messages must be created with status `"pending"` — Cloud Functions handle all status transitions
- Users cannot modify their own `isBanned` or `strikes` fields
- Reports and support tickets are write-only from clients (no client reads)
- Connections are read-only from clients (created by Cloud Functions only)
- Composite indexes defined in `firestore.indexes.json` for messages (status+approvedAt, status+mood+approvedAt, senderId+createdAt) and ratings (userId+messageId)
