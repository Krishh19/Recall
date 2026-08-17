# AI IDE Prompt Guide — Building Recall

Copy-pasteable prompts for Codex, Cursor, Windsurf, or any AI IDE, scoped to one feature at a time and matching the tech stack and roadmap from the blueprint doc. Paste Section 1 once as standing project context; work through Section 2 in order, reviewing the output before moving to the next prompt.

## Contents
1. [Project context — paste once](#1-project-context--paste-once)
2. [Prompts by phase](#2-prompts-by-phase)
3. [Tips for working with an AI IDE on this build](#3-tips-for-working-with-an-ai-ide-on-this-build)

---

## 1. Project context — paste once

Save this as `AGENTS.md` (Codex) or `.cursorrules` (Cursor) so every prompt after it inherits the context without you re-explaining the stack each time.

```
You're helping me build Recall, a Flutter app. Users share links (X/Twitter
posts, Instagram posts, YouTube videos, articles) into the app from other
apps; it extracts the content, summarizes it with AI, and auto-categorizes
it, so saved links don't just pile up unread.

Tech stack:
- Flutter 3.44+, Dart 3.12
- State management: Riverpod, code-gen style (@riverpod annotation) — not
  legacy StateNotifier/ChangeNotifier unless I ask for it specifically
- Navigation: go_router
- UI: material_3_expressive (^1.0.7) — use M3E* widgets (M3EButton, M3ECard,
  M3EChip, M3EAppBar, M3EBottomSheet, etc.) wrapped in M3EMaterialApp. Fall
  back to plain Flutter widgets only when M3E has no equivalent.
- Local cache: drift (SQLite)
- Backend: Supabase — Postgres, Auth, Edge Functions (Deno/TS), Realtime —
  via supabase_flutter
- Networking: dio
- Share intent: receive_sharing_intent + app_links
- Images: cached_network_image

Database — Postgres table `saved_items`:
  id uuid primary key default gen_random_uuid()
  user_id uuid references auth.users not null
  url text not null
  platform text not null            -- twitter | instagram | youtube | article
  title text
  thumbnail_url text
  raw_content text
  summary text
  key_points jsonb
  category text
  tags text[]
  status text default 'processing'  -- processing | done | failed
  is_read boolean default false
  is_favorite boolean default false
  created_at timestamptz default now()

AI summarization contract — every save calls one AI endpoint and expects
exactly this JSON back, nothing else:
  {
    "summary": "1-2 plain-language sentences",
    "key_points": ["point 1", "point 2", "point 3"],
    "category": "one of: Technology, Business, Health, Education,
                  Entertainment, News, Food, Finance, Other",
    "tags": ["3-6 lowercase keywords"],
    "estimated_read_time_minutes": 2
  }

Conventions:
- Feature-first folders: lib/core (theme, router, providers), lib/features/
  {onboarding,home,detail,save,search,categories,settings}, lib/data
  (models, repositories)
- Doc comment on every public class/function
- Prefer composition over inheritance for widgets
- When I ask for a feature: give me a short plan (bullet points) before
  writing code, not after
```

## 2. Prompts by phase

### Phase 1 — Foundation

**2.1 Scaffold the project**
```
Scaffold a new Flutter project called Recall. Set up:
- pubspec.yaml with: material_3_expressive, flutter_riverpod,
  riverpod_generator + riverpod_annotation, go_router, drift +
  sqlite3_flutter_libs (+ drift_dev as dev dep), supabase_flutter, dio,
  cached_network_image, receive_sharing_intent, app_links,
  flutter_secure_storage, share_plus, url_launcher,
  flutter_local_notifications, build_runner as dev dependency
- The feature-first folder structure described in the project context
- analysis_options.yaml with flutter_lints
- main.dart wrapping the app in M3EMaterialApp (autoTheming: true,
  dynamicColoring: true) with a placeholder home screen

Don't write feature logic yet — just get this running on a simulator with a
blank screen.
```

**2.2 Theme setup**
```
Set up the M3E theme in lib/core/theme.dart: M3EThemeData.light(seedColor:)
and a matching dark variant. Pick a seed color that fits a calm, focused
"save and read later" app and tell me your one-line reasoning before you
implement it. Wire it into M3EMaterialApp. Add a small Riverpod
ThemeController so a settings screen can later override system theme mode.
```

**2.3 Supabase schema + client**
```
Write the Supabase setup:
1. A SQL migration creating saved_items exactly as specified in the project
   context, plus an index on (user_id, created_at desc) and a GIN index on
   tags
2. Row Level Security policies so a user can only read/write their own rows
3. lib/core/supabase_client.dart initializing Supabase with env-based
   URL/anon key — tell me whether you're using flutter_dotenv or
   --dart-define and why before you pick one
4. A typed SavedItem model matching the table with fromJson/toJson
```

**2.4 Auth**
```
Implement auth with Supabase Auth: email/password, Google sign-in, and
Apple sign-in (required on iOS since we also offer Google — App Store
rule). Add a Riverpod AuthController exposing the current session as a
stream, and route guarding in go_router that redirects to /sign-in when
there's no session, except for the sign-in/sign-up routes themselves.
```

### Phase 2 — Core save pipeline

**2.5 Share-intent handling**
```
Implement the share-intent entry point: use receive_sharing_intent to
listen for shared text/URLs on both cold start (getInitialMedia) and while
running (getMediaStream). Extract the URL from the shared text robustly
(there's often extra text around it). On Android, add the right intent
filters to AndroidManifest.xml. On iOS, tell me exactly what to click and
name in Xcode to add the Share Extension target — I'll do that part myself.

When a URL comes in: insert a saved_items row with status 'processing'
immediately, then show the save-confirmation bottom sheet — don't block the
UI on processing finishing.
```

**2.6 Extraction Edge Functions**
```
Write Supabase Edge Functions (Deno/TS) for content extraction. Each
follows this contract: accept a URL, return { title, raw_content,
thumbnail_url } or throw a typed error.

1. Twitter/X: call publish.x.com/oembed?url=... and parse the tweet text
   out of the returned HTML
2. Instagram: fetch the post URL and parse Open Graph tags (og:title,
   og:description, og:image)
3. YouTube: call the YouTube Data API v3 for metadata, plus a transcript
   source — ask me whether to use an unofficial library or a managed
   transcript API before you pick one
4. Generic article: call Jina Reader (prefix r.jina.ai/ to the URL) and
   return the markdown

Add a router function that inspects the saved URL's domain and calls the
right one of these.
```

**2.7 Summarization Edge Function**
```
Write a Supabase Edge Function that takes extracted content, calls [name
your chosen AI API] with the exact prompt contract from the project
context, parses the JSON response, and updates the saved_items row
(status → 'done' plus summary/key_points/category/tags) — or sets status →
'failed' with a short reason if anything throws. Cap content sent to the
model at ~6000 characters. Trigger this function automatically on insert
into saved_items via a database webhook.
```

**2.8 Home feed screen**
```
Build the home feed screen with material_3_expressive:
- M3EAppBar.search for the title + expanding search
- A row of M3EChip (type: filter) for the fixed category list, "All"
  selected by default
- The feed as M3EDismissibleColumn so swiping archives an item (call an
  archive method — never hard-delete on swipe)
- Each row as M3EListItem: headline = title, supportingText = summary,
  leading = platform icon, trailing = category M3EChip
- status: 'processing' rows show a subtle skeleton instead of the summary
- status: 'failed' rows show "Couldn't process — tap to retry"

Wire it to a Riverpod provider streaming saved_items for the current user
from Supabase, ordered by created_at desc, filtered by selected category.
```

**2.9 Item detail screen**
```
Build the item detail screen: M3EAppBar.top, hero thumbnail, M3ECard for
the summary, M3EChip row for category + tags, key points as a bulleted
list, and a floating M3EToolbar docked at the bottom with three actions:
open original (url_launcher), toggle favorite, archive. Wire favorite and
archive to update the saved_items row.
```

**2.10 Save confirmation sheet**
```
Build the M3EBottomSheet shown right after a share-intent completes:
"Saved to Recall" with a checkmark, then M3EProgressIndicator.circularWavy()
and "Summarizing…" while status is 'processing', switching to the detected
category as an M3EChip once the Riverpod stream reports status 'done'. The
sheet must be dismissible immediately without cancelling background
processing.
```

### Phase 3 — Polish

**2.11 Search**
```
Implement the search screen with M3ESearchAnchor.bar: as the user types,
query saved_items where title/summary match (ilike) or tags contain the
term, debounced ~300ms, rendering results with the same M3EListItem row
used on Home.
```

**2.12 Retry / failure handling**
```
Add a retry path: tapping a status: 'failed' item re-triggers the
extraction + summarization function chain and sets status back to
'processing'. If retry fails twice in a row, show a snackbar suggesting the
user check the original link.
```

**2.13 Notifications digest**
```
Add a weekly digest local notification with flutter_local_notifications:
user-configurable day/time (store in a settings table or
shared_preferences), showing the count of unread saved_items from the past
7 days. Tapping it opens Home filtered to unread.
```

**2.14 Tests**
```
Write widget tests for the Home feed (renders items, category chips filter
correctly, swipe archives) and unit tests for the extraction router logic
that picks a function based on URL domain.
```

## 3. Tips for working with an AI IDE on this build

- **One feature per prompt, reviewed before the next one.** The prompts above are already scoped this way on purpose — resist batching three of them together. A wrong assumption in the extraction router quietly breaks every screen built on top of it.
- **Paste the doc's actual section as context, not a summary of it.** For the extraction prompts especially, paste the real Content Extraction Strategy section rather than describing it from memory — the exact endpoints and caveats matter.
- **Ask for the plan before the code** wherever there's more than one reasonable approach (the auth env-var choice, which transcript source to use) — redirecting a plan is cheap, redirecting finished code isn't.
- **Give it the schema verbatim.** Copy-paste the SQL and the JSON prompt contract exactly rather than re-describing them from memory — a quietly renamed field or a slightly different category list breaks the pipeline in ways that are annoying to trace later.
- **Keep the context file current.** Update Section 1 as you make real decisions (which transcript API you actually picked, your real seed color) — that's what keeps prompts 2.6 onward short instead of re-explaining the stack every time.
