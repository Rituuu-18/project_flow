# Evalio Design

Flutter app for engineering **design review** workflows: portfolio dashboard, staged checklists, workspace notes/evidence, stakeholders, and Supabase-backed auth/storage.

Package name in code: `engineering_werk`  
Product name in UI: **Evalio Design**

---

## Table of contents

1. [What it does](#what-it-does)
2. [Stack](#stack)
3. [Prerequisites](#prerequisites)
4. [Quick start](#quick-start)
5. [Environment & secrets](#environment--secrets)
6. [Supabase backend](#supabase-backend)
7. [App architecture](#app-architecture)
8. [Core product flows](#core-product-flows)
9. [Storage (images & evidence)](#storage-images--evidence)
10. [Running on web / mobile](#running-on-web--mobile)
11. [Building an Android APK](#building-an-android-apk)
12. [Testing](#testing)
13. [Migrations reference](#migrations-reference)
14. [Known caveats](#known-caveats)
15. [Project layout](#project-layout)

---

## What it does

- **Auth** — sign up / sign in via Supabase Auth; profiles created by DB trigger
- **Dashboard** — list design reviews, search, create, copy, delete, upload cover images
- **Design review detail** — lifecycle stages/sub-steps, stakeholders, progress
- **Workspace** — per sub-step notes, engineering comments, assignment (stakeholder → discipline), due date, evidence files, activity log
- **Themes** — light/dark via Riverpod

---

## Stack

| Layer | Tech |
|--------|------|
| Client | Flutter 3.x (Dart SDK `^3.11.4`) |
| State | Riverpod |
| Routing | go_router |
| Backend | Supabase (Auth, Postgres, Storage, RLS) |
| Env | `flutter_dotenv` (`.env` asset) |

---

## Prerequisites

- Flutter SDK matching the project (`flutter doctor`)
- A Supabase project with migrations applied (see [Supabase backend](#supabase-backend))
- For Android builds: Android SDK / toolchain
- Optional: Chrome for Flutter web

---

## Quick start

```bash
# 1. Clone and install
git clone <your-repo-url> project_flow
cd project_flow
flutter pub get

# 2. Configure env (see next section)
cp .env.example .env
# Edit .env with your Supabase URL + anon key

# 3. Run (web example)
flutter run -d chrome --web-port=8080

# Or default device
flutter run
```

Sign in (or register) before creating reviews, uploading images, or saving workspaces. Unauthenticated users are sent to `/login`.

**Demo admin (local only — do not commit credentials):** if you created one earlier in this project’s Supabase, use that account. Otherwise register a new user in the app.

---

## Environment & secrets

### Client `.env` (bundled with the app)

Copy from [`.env.example`](.env.example):

```env
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=your_anon_key
```

- Loaded in [`lib/main.dart`](lib/main.dart) via `dotenv.load(fileName: '.env')`
- Listed as a Flutter asset in `pubspec.yaml`
- **Never** put service-role keys or PATs here

### Admin `.env.admin` (local only, gitignored)

Used for ops / gated integration tests — **not** shipped in the APK:

```env
SERVICE_ROLE_SECRET=your_service_role_key
SUPABASE_PERSONAL_ACCESS_TOKEN=your_management_api_token
```

The APK build script ([`scripts/build_apk.sh`](scripts/build_apk.sh)) refuses to build if a service-role secret is present in the client `.env`.

---

## Supabase backend

### Schema (high level)

| Table | Purpose |
|--------|---------|
| `profiles` | User profile (`first_name` / `last_name` from signup metadata) |
| `projects` | Optional project grouping |
| `design_reviews` | Review cards (`image_url`, status, progress, …) |
| `sub_steps` | Checklist items linked to a review + workspace |
| `workspaces` | Notes, attachments, assignee, discipline, due date, activity logs |
| `stakeholders` | People on a review (name + role) |
| `workspace_comments` | Comments on a workspace |

All user data is protected with **RLS** (owner = `created_by` / review ownership). See [`supabase/migrations/20260718000005_rls.sql`](supabase/migrations/20260718000005_rls.sql).

### Applying migrations

Migrations live in [`supabase/migrations/`](supabase/migrations/). Order matters (enums → tables → indexes → triggers → RLS → storage → grants → fixes).

With Supabase CLI (recommended when available):

```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

Or apply SQL via the Supabase SQL editor / Management API for each file in timestamp order.

Project config: [`supabase/config.toml`](supabase/config.toml).

### Profile trigger note

Signup metadata uses **snake_case** (`first_name`, `last_name`). Migration [`20260719180000_fix_profile_trigger_metadata.sql`](supabase/migrations/20260719180000_fix_profile_trigger_metadata.sql) aligns the trigger with the Flutter app.

---

## App architecture

Feature-first layout under `lib/`:

```
lib/
  main.dart
  core/                 # router, theme, supabase, messenger, storage helpers
  features/
    auth/
    dashboard/
    projects/           # design review detail
    reviews/            # domain, repos, providers
    workspace/
    settings/
```

Typical data path:

```
UI (pages/widgets)
  → Riverpod providers / notifiers
    → Repository interface (domain)
      → Supabase*Repository (data)
        → Postgres / Storage (RLS)
```

Important entry points:

| Area | Path |
|------|------|
| Supabase init | [`lib/core/database/supabase_service.dart`](lib/core/database/supabase_service.dart) |
| Error wrapping | [`lib/core/database/supabase_errors.dart`](lib/core/database/supabase_errors.dart) |
| Storage uploads | [`lib/core/database/supabase_storage.dart`](lib/core/database/supabase_storage.dart) |
| Toasts | [`lib/core/utils/app_messenger.dart`](lib/core/utils/app_messenger.dart) |
| Reviews repo | [`lib/features/reviews/data/repositories/supabase_design_review_repository.dart`](lib/features/reviews/data/repositories/supabase_design_review_repository.dart) |
| Workspace repo | [`lib/features/workspace/data/repositories/supabase_workspace_repository.dart`](lib/features/workspace/data/repositories/supabase_workspace_repository.dart) |

---

## Core product flows

### Design reviews

1. Sign in → dashboard
2. Create a review → default lifecycle stages/sub-steps are attached
3. Open a review → update sub-step status, add stakeholders
4. **Copy review** uses [`cloneForCopy`](lib/features/reviews/domain/utils/clone_for_copy.dart): new UUIDs for review, stages, sub-steps, workspaces, and stakeholders (does **not** steal rows from the original; cover image is not copied)

### Stakeholders → workspace assignment

1. Add stakeholders on the **design review** page (name required; role optional)
2. Duplicate names on the same review are rejected (case-insensitive)
3. In a **workspace**, pick a stakeholder from the dropdown (keyed by **id**)
4. Assignee is set to the stakeholder **name**; **discipline** auto-fills from **role** when role is non-empty
5. Empty role does **not** become `"Member"` for discipline

### Workspace saves

- Manual **Save Progress** and automatic activity-log saves go through a **serialized save queue** so rapid changes do not drop activity log entries
- Due date can be set or **Clear**ed

---

## Storage (images & evidence)

### Cover images (dashboard cards)

- Bucket: `images` (public read **only** for `design_review/%` paths)
- Path: `design_review/{reviewId}/{uuid}.{ext}`
- Flow: pick image → upload bytes → store **public URL** on `design_reviews.image_url`
- Re-upload best-effort deletes the previous storage object
- Auth required; max ~5 MB client-side
- Cards still render legacy `data:` base64 URLs if present

Relevant migrations:

- [`20260718000006_storage.sql`](supabase/migrations/20260718000006_storage.sql) — buckets + ACL helper
- [`20260720000001_storage_design_review_images.sql`](supabase/migrations/20260720000001_storage_design_review_images.sql) — `design_review` path ACL + public bucket
- [`20260720000002_scope_public_images.sql`](supabase/migrations/20260720000002_scope_public_images.sql) — public SELECT limited to `design_review/%`

### Workspace evidence

- Bucket: `attachments` (**private**)
- Path: `workspace/{workspaceId}/{uuid}_{filename}`
- Stored in `workspaces.attachments` as durable refs: `storage:attachments:{path}`
- Opening a file creates a **signed URL** (7 days) and launches the browser/external viewer
- Pick uses `FilePicker` with `withData: true` (works on web); max ~20 MB per file

---

## Running on web / mobile

### Web

```bash
flutter run -d chrome --web-port=8080
```

Password-reset / auth redirects may depend on Supabase Auth `site_url` (often `http://localhost:8080` for local web). Adjust in the Supabase dashboard for production domains.

### Android / iOS

- Gallery / photo permissions are declared for cover upload
- Internet permission required for Supabase
- Prefer a release APK via the script below for device testing

---

## Building an Android APK

```bash
# Ensure .env has ONLY URL + anon key
./scripts/build_apk.sh
```

- Output: `build/apk_dist/evalio-design-release-*.apk`
- Uses debug signing unless you configure a release keystore
- Aborts if service-role / PAT-like secrets are found in `.env`

---

## Testing

```bash
# Unit + widget (no live backend required)
flutter test test/unit
flutter test test/widget

# Specific suites used for recent bugfixes
flutter test test/unit/clone_for_copy_test.dart
flutter test test/unit/workspace_data_test.dart
flutter test test/widget/workspace_permissions_test.dart
```

### Integration tests (live Supabase)

Under [`test/integration/`](test/integration/):

- Require `.env` (and often `.env.admin` for cleanup / elevated ops)
- Skip automatically when credentials are missing
- Cover auth, review CRUD, and RLS isolation patterns

Run only when you intend to hit the real project:

```bash
flutter test test/integration
```

---

## Migrations reference

| File | Purpose |
|------|---------|
| `20260718000001_enums.sql` | Enums (status, etc.) |
| `20260718000002_tables.sql` | Core tables |
| `20260718000003_indexes_constraints.sql` | Indexes / constraints |
| `20260718000004_triggers_functions.sql` | `updated_at`, profile trigger (base) |
| `20260718000005_rls.sql` | Row Level Security |
| `20260718000006_storage.sql` | Buckets + `can_access_storage_path` |
| `20260718000007_fk_tweaks.sql` | FK adjustments |
| `20260718000008_grants.sql` | Grants |
| `20260719180000_fix_profile_trigger_metadata.sql` | Profile metadata key fix |
| `20260720000001_storage_design_review_images.sql` | Design-review image paths |
| `20260720000002_scope_public_images.sql` | Narrow public image SELECT |

---

## Known caveats

- **Auth required** for create/copy/delete reviews, image upload, workspace save, evidence upload
- **Email confirmation** settings live in Supabase Auth; autoconfirm may be enabled on the project for easier local testing
- **Copy review** resets stage/sub-step progress to not started and does not copy cover images
- **Evidence** stored before the Storage fix may be plain filenames (not openable); re-upload those files
- **Orphan Storage objects** can remain if delete-after-reupload fails (non-fatal)
- `workspaces.stakeholders` TEXT[] column exists in schema but is unused; assignment reads review stakeholders from the stream
- APK script ships **debug-signed** builds unless you add a release keystore

---

## Project layout

```text
project_flow/
├── lib/                      # Flutter app
├── supabase/
│   ├── config.toml
│   └── migrations/           # Ordered SQL
├── scripts/
│   └── build_apk.sh          # Release APK helper
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/          # Live Supabase (gated)
├── .env.example              # Public client keys template
├── .env                      # Local (gitignored)
├── .env.admin                # Local secrets (gitignored)
├── pubspec.yaml
└── README.md
```

---

## License / publishing

`publish_to: 'none'` — private app package. Add your own license file if you distribute the source.
