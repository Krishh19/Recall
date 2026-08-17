# Recall Project Status

_Last updated: August 16, 2026_

## Product direction

Recall is a Flutter app for saving links shared from other apps. It will extract
content, summarize it with AI, categorize it, and present saved items as a
readable library instead of a bookmark backlog.

The implementation follows the roadmap and conventions in `CLAUDE.md` and
`bookmark_summarizer_blueprint.md`.

## Completed

### Phase 1.1 — Project foundation

- Created a Flutter project named `recall` for Android and iOS.
- Verified the local toolchain:
  - Flutter `3.47.0`
  - Dart `3.13.0`
- Added the planned application dependencies:
  - `material_3_expressive`
  - `flutter_riverpod` and `riverpod_annotation`
  - `go_router`
  - `drift` and `sqlite3_flutter_libs`
  - `supabase_flutter`
  - `dio`
  - `cached_network_image`
  - `receive_sharing_intent` and `app_links`
  - `flutter_secure_storage`
  - `share_plus`
  - `url_launcher`
  - `flutter_local_notifications`
- Added the planned development dependencies:
  - `riverpod_generator`
  - `drift_dev`
  - `build_runner`
  - `flutter_lints`
- Created the feature-first source structure:
  - `lib/core/providers/`
  - `lib/data/models/`
  - `lib/data/repositories/`
  - `lib/features/onboarding/`
  - `lib/features/home/`
  - `lib/features/detail/`
  - `lib/features/save/`
  - `lib/features/search/`
  - `lib/features/categories/`
  - `lib/features/settings/`
- Wrapped the application in a root Riverpod `ProviderScope`.
- Replaced the generated counter app with `RecallApp` using
  `M3EMaterialApp`.
- Enabled automatic system theming, dynamic colors, and drawing under system
  bars.
- Added a blank `HomeScreen` placeholder without feature logic.
- Replaced the generated counter test with a Recall app-shell smoke test.

### Android build configuration

Current plugin releases required two generated Android configuration changes:

- Set `compileSdk` to Android API 37 because `flutter_secure_storage` and
  `receive_sharing_intent` require it.
- Enabled Java core-library desugaring for `flutter_local_notifications` and
  added `desugar_jdk_libs`.

## Validation completed

The following checks pass:

```text
dart format lib test
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The Android debug APK was generated at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

A simulator launch was not performed because no Android emulator is currently
configured. iOS compilation cannot be performed on this Windows machine.

### Phase 1.2 — Theme setup

- Added `lib/core/theme.dart` with calm library-teal seed color (`#356A67`) and matching `M3EThemeData` for light and dark themes.
- Added `@riverpod` annotated `ThemeController` in `lib/core/providers/theme_controller.dart`.
- Generated Riverpod code with `build_runner`, producing `lib/core/providers/theme_controller.g.dart`.
- Wired `ThemeController` and `AppTheme` into `RecallApp` in `lib/app.dart`.
- Added widget test coverage in `test/widget_test.dart` verifying dynamic theme mode switching.

## Validation completed

The following checks pass:

```text
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

The Android debug APK was generated at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

### Phase 1.3 — Supabase schema + client

- Initialized Supabase CLI configuration in `supabase/config.toml`.
- Created SQL migration `supabase/migrations/20260816000000_create_saved_items.sql` with:
  - `saved_items` table matching blueprint schema.
  - Composite index on `(user_id, created_at desc)`.
  - GIN index on `tags`.
  - Row Level Security (RLS) policies isolating reads, inserts, updates, and deletes to `auth.uid() = user_id`.
- Implemented `lib/core/supabase_client.dart` with `--dart-define` support (`SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`/`SUPABASE_ANON_KEY`) defaulting to project `evtzrvqfaearmpjgqwqd`.
- Generated Riverpod code for `supabaseClientProvider` with `build_runner`.
- Created typed `SavedItem` model in `lib/data/models/saved_item.dart` with `fromJson`, `toJson`, `copyWith`, and value equality.
- Added comprehensive unit tests in `test/data/models/saved_item_test.dart` (all 7 tests passing).

## Validation completed

The following checks pass:

```text
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

The Android debug APK was generated at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

### No-Auth Simplification & Android-First Scope

- Removed authentication requirements per updated specification to streamline the standalone Android app experience:
  - Made `userId` optional in `SavedItem` model.
  - Made `user_id` optional in Supabase schema and set permissive RLS policies.
  - Simplified `GoRouter` to load `HomeScreen` directly at `/`.
  - Removed `SignInScreen`, `SignUpScreen`, and `AuthController`.

### Phase 2.1 — Android Share-intent handling

- Configured Android `MainActivity` with `<intent-filter>` in `android/app/src/main/AndroidManifest.xml` for `android.intent.action.SEND` with `text/plain` mimeType.
- Implemented `UrlExtractor` in `lib/core/utils/url_extractor.dart`:
  - Robust regex URL detection with trailing punctuation removal.
  - Platform detection: `twitter`, `instagram`, `youtube`, `article`.
- Implemented `SavedItemRepository` in `lib/data/repositories/saved_item_repository.dart` with CRUD operations, realtime streams, and safe test fallbacks.
- Implemented `ShareIntentService` in `lib/features/save/share_intent_service.dart`:
  - Handles cold start (`getInitialMedia()`) and runtime share events (`getMediaStream()`).
  - Asynchronously creates `saved_items` database records with `status: 'processing'`.
  - Emits updates to `latestSharedItemProvider` for immediate UI response.
  - Resets share intents after consumption.
- Wired share intent listeners into `RecallApp` in `lib/app.dart`.
- Added unit and widget tests:
  - `test/core/utils/url_extractor_test.dart`
  - `test/features/save/share_intent_service_test.dart`
  - `test/data/models/saved_item_test.dart`
  - `test/widget_test.dart`

### Phase 2.2 — Extraction Edge Functions (Deno/TS)

- Created modular extraction library in `supabase/functions/_shared/extractors.ts`:
  - **Twitter / X**: Uses `publish.x.com/oembed` and parses tweet blockquote text.
  - **Instagram**: Fetches Open Graph tags (`og:title`, `og:description`, `og:image`).
  - **YouTube**: Fetches metadata via oEmbed + zero-config caption track parsing for transcripts.
  - **Articles**: Fetches clean Markdown content via Jina Reader (`r.jina.ai/<url>`).
  - **Domain router**: Automatically directs incoming URLs to the proper platform extractor.
- Created `extract-content` Edge Function in `supabase/functions/extract-content/index.ts` with CORS support.

### Phase 2.3 — Summarization Edge Function (Gemini 2.5 Flash)

- Created `process-item` Edge Function in `supabase/functions/process-item/index.ts`:
  - Truncates extracted content to ~6,000 characters.
  - Invokes Google Gemini 2.5 Flash API with JSON mode (`responseMimeType: application/json`).
  - Enforces strict structured output schema (`summary`, `key_points`, `category`, `tags`, `estimated_read_time_minutes`).
  - Updates `saved_items` table in Supabase (`status = 'done'` or `status = 'failed'`).
- Integrated background invocation in `SavedItemRepository` (`lib/data/repositories/saved_item_repository.dart`) with `triggerProcessing` and `retryItem`.

### Phase 2.4 — Home feed screen with Material 3 Expressive

- Built `HomeScreen` in `lib/features/home/home_screen.dart` with:
  - `M3EAppBar.search` supporting live search filtering by title, summary, and tags.
  - Horizontal `CategoryFilterRow` with `M3EChip(type: M3EChipType.filter)` for the 10 core categories.
  - Expressive `FeedItemTile` with `M3EListItem` supporting `processing` (with progress indicator), `failed` (tap to retry), and `done` states.
  - Swipe-to-archive interaction with `DismissDirection.endToStart` without hard deletion.
  - `FeedEmptyState` when library or filtered categories are empty.
- Created `selectedCategoryProvider` and `savedItemsFeedProvider` in `lib/features/home/home_providers.dart`.
- Added comprehensive widget tests in `test/features/home/home_screen_test.dart`.

### Phase 2.5 — Item detail screen with Material 3 Expressive

- Built `DetailScreen` in `lib/features/detail/detail_screen.dart` with:
  - `M3EAppBar.top` with share and delete actions.
  - Media banner with `CachedNetworkImage` and smooth error/placeholder handling.
  - Header with title, platform, category assist chip, and hashtag suggestion chips.
  - `M3ECard` for the AI-generated 1-2 sentence core summary.
  - Bulleted Key Points list with brand-colored indicators.
  - Scrollable raw extracted text/transcript container.
  - Floating bottom `M3EToolbar.floating` docked with:
    - Open in external browser (`url_launcher`).
    - Toggle favorite (synced to Supabase).
    - Toggle archive / read status (synced to Supabase).
- Created `itemDetailProvider` in `lib/features/detail/detail_providers.dart`.
- Added `/detail/:id` route in `lib/core/router.dart`.
- Added comprehensive unit and widget tests in `test/features/detail/detail_screen_test.dart`.

### Phase 2.6 — Save confirmation bottom sheet with Material 3 Expressive

- Built `SaveConfirmationSheet` in `lib/features/save/widgets/save_confirmation_sheet.dart`:
  - `M3EBottomSheet` with drag handle and close button for instant dismissibility.
  - "Saved to Recall" header badge with checkmark.
  - Title/URL preview.
  - Dynamic reactive state via `itemDetailProvider(itemId)`:
    - **Processing**: Displays `M3EProgressIndicator.circularWavy()` with `"Summarizing…"`.
    - **Done**: Transitions to detected category `M3EChip` and a `"View Details"` button navigating to `/detail/:id`.
    - **Failed**: Displays failure warning with inline `"Retry"` button.
- Wired share intent event triggers in `HomeScreen` to automatically display `SaveConfirmationSheet` upon link arrival.
- Added comprehensive unit and widget tests in `test/features/save/save_confirmation_sheet_test.dart`.

### Phase 3.1 — Search screen with Material 3 Expressive SearchAnchor

- Built `SearchScreen` in `lib/features/search/search_screen.dart` with:
  - `M3ESearchAnchor.bar` supporting live search query input and clear button.
  - Query filtering matches against title, summary, and tags.
  - Expressive empty search state and no-matches state.
  - Result list formatted with `FeedItemTile` navigating to `/detail/:id`.
- Created `searchQueryProvider` and `searchResultsProvider` in `lib/features/search/search_providers.dart`.
- Added `/search` route in `lib/core/router.dart`.
- Added comprehensive unit and widget tests in `test/features/search/search_screen_test.dart`.

### Phase 3.2 — Retry and failure handling

- Built `RetryTracker` in `lib/features/save/retry_tracker.dart`:
  - Retains consecutive retry counts per item ID.
  - Automatically surfaces helpful guidance `SnackBar` on 2 or more consecutive failures prompting the user to check if the original link is accessible and provides a direct "Open Link" action button.
  - Integrates smoothly with `FeedItemTile`, `DetailScreen`, and `SaveConfirmationSheet`.
- Added comprehensive unit and widget tests in `test/features/save/retry_tracker_test.dart`.

### Phase 3.4 — Tests & Verification (Prompt 2.14)

- Created extraction domain router unit tests in `test/core/extraction/extraction_router_test.dart`:
  - Twitter / X domain matching (`x.com`, `twitter.com`, `t.co`, case insensitivity).
  - Instagram domain matching (`instagram.com/p/`, `instagram.com/reel/`, `instagr.am`).
  - YouTube domain matching (`youtube.com/watch`, `youtu.be`, `youtube.com/shorts`, `m.youtube.com`).
  - Generic article domain matching (blogs, news sites, Substack, Medium, fallbacks).
- Created comprehensive Home feed widget test suite in `test/features/home/home_feed_flow_test.dart`:
  - Feed rendering across all item states (`done` with summary and chips, `processing` with skeleton/indicator, `failed` with retry action).
  - Category chip filter interaction (filtering to specific category like "Technology" and resetting with "All").
  - Unread toggle filter chip interaction (filtering out read/archived items).
  - Dismissible swipe-to-archive (triggering `toggleRead` without hard deleting).
  - Tap-to-retry on failed items (triggering background re-processing on repository).

### Backend & AI Deployment (Live & Verified)

- **`extract-content` Edge Function**: Deployed and active on Supabase project `evtzrvqfaearmpjgqwqd`. Tested live extraction for articles and YouTube.
- **`process-item` Edge Function**: Deployed and active on Supabase project `evtzrvqfaearmpjgqwqd`. Configured with `GEMINI_API_KEY` secret and tested live AI summarization (`gemini-2.5-flash`).
- **Postgres Auto-Processing Webhook (`pg_net`)**: Migration `20260816000001_auto_process_webhook.sql` applied to automatically trigger background extraction and summarization on row insertion.

## Validation completed

The following checks pass:

```text
dart format lib test
flutter analyze
flutter test
```

All 57 unit and widget tests across the entire application pass with 0 analyze warnings or errors.

## Phase 3 Roadmap Status

- [x] 3.1 Search screen (Prompt 2.11)
- [x] 3.2 Retry / failure handling (Prompt 2.12)
- [x] 3.3 Notifications digest (Prompt 2.13)
- [x] 3.4 Integration & End-to-end tests (Prompt 2.14)
- [x] Supabase Edge Functions & Webhook Deployment

### Phase 3 — Polish (Complete)

- [x] 3.1 Search titles, summaries, and tags with debounce
- [x] 3.2 Retry failed extraction and summarization
- [x] 3.3 Weekly digest notifications
- [x] 3.4 Home feed widget tests and extraction-router unit tests

### Later roadmap from the blueprint

- [ ] Add Twitter/X extraction through the public oEmbed endpoint
- [ ] Add Instagram extraction through Open Graph metadata
- [ ] Add Drift-backed offline caching and synchronization
- [ ] Add semantic search with Supabase `pgvector`
- [ ] Evaluate a production AI model based on reliability and cost
- [ ] Add widgets, quick actions, and possible paid-tier limits

## Known notes

- `sqlite3_flutter_libs` currently resolves to a package release marked `+eol`.
  It remains installed because it is explicitly required by the current project
  plan, but the Drift integration milestone should verify the recommended
  native-assets replacement before database implementation.
- The workspace is not currently initialized as a Git repository.
- No Android Virtual Device is configured on this machine.
