# Evalio Design

Evalio Design is an engineering design review and verification platform built with Flutter and Supabase. It structures multi-disciplinary hardware and systems engineering lifecycles into 10 verification stages, tracks Design Readiness Level (DRL) metrics, provides isolated workspaces for checklist items and evidence collection, generates publication-grade PDF audit reports, and runs context-aware AI engineering analysis using Groq LLMs.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                    EVALIO DESIGN                                        │
│                                                                                         │
│  ┌───────────────────────┐   ┌────────────────────────┐   ┌──────────────────────────┐  │
│  │  Portfolio Dashboard  │   │  Design Review Detail  │   │   Engineering Workspace  │  │
│  │  • DRL Readiness Gauge│──>│  • 10 Lifecycle Stages │──>│   • Problem & Scope      │  │
│  │  • Search & Filters   │   │  • Sub-step Checklists │   │   • Roles & Disciplines  │  │
│  │  • Clone / Copy Flow  │   │  • Stakeholder Board   │   │   • Serialized Notes Log │  │
│  │  • Cover Image Upload │   │  • DRL Weight Breakdown│   │   • Private File Storage │  │
│  └───────────────────────┘   └────────────────────────┘   └─────────────┬────────────┘  │
│                                                                         │               │
│  ┌───────────────────────┐   ┌────────────────────────┐                 ▼               │
│  │   PDF Report Engine   │   │    Groq AI Analysis    │      ┌───────────────────────┐  │
│  │  • Executive Summary  │   │  • On-Demand Trigger   │<─────┤   AI Analysis Sheet   │  │
│  │  • DRL Metric Charts  │   │  • Context Parameters  │      │   • Project & Scope   │  │
│  │  • Evidence Hyperlinks│   │  • Multi-Tier Fallback │      │   • Card & Notes Mode │  │
│  │  • Cloud PDF Archive  │   │  • Note Injection Flow │      │   • Direct Clipboard  │  │
│  └───────────────────────┘   └────────────────────────┘      └───────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Technical Stack

| Layer | Component | Version / Specification |
| :--- | :--- | :--- |
| **Framework** | Flutter / Dart | Flutter 3.x • Dart SDK `^3.11.4` |
| **State Management** | Riverpod | `flutter_riverpod: ^2.6.1` • `riverpod_annotation: ^2.6.1` |
| **Routing** | GoRouter | `go_router: ^17.2.3` with custom cubic page transitions |
| **Backend & Database** | Supabase | `supabase_flutter: ^2.9.1` • PostgreSQL 15+ • RLS enabled |
| **Authentication** | Supabase Auth | Email/Password with snake_case profile triggers |
| **Cloud Storage** | Supabase Storage | `images` (public bucket) • `attachments` (private signed URLs) |
| **AI Analysis Engine** | Groq Cloud API | LLaMA 3.3 70B Versatile with LLaMA 3.1 8B Instant fallback |
| **Report Generation** | PDF & Printing | `pdf: ^3.11.2` • `printing: ^5.14.1` (vector layout engine) |
| **Internationalization** | In-House Reactive Provider | English (`en`), Dutch (`nl`), German (`de`) |
| **Design System** | `DashboardDesign` Tokens | Adaptive Light / Dark themes with strict WCAG contrast |

---

## Architecture & Data Flow

Evalio Design follows a feature-first clean architecture:

```
lib/
├── core/                       # Shared infrastructure & utilities
│   ├── database/               # Supabase client, storage handlers, error mappers
│   ├── localization/           # Locale state notifier & translation dictionaries
│   ├── router/                 # GoRouter declaration, route guards, cubic transitions
│   ├── theme/                  # Color palettes, typography, theme mode providers
│   └── utils/                  # Enums, messengers, string helpers
├── features/
│   ├── auth/                   # Login, register, password recovery, session provider
│   ├── dashboard/              # Portfolio summary, review cards, cover upload, PDF archive
│   ├── projects/               # Design review detail screen, DRL breakdown view
│   ├── reviews/                # Review domain entities, repositories, lifecycle clone logic
│   ├── settings/               # User preferences & theme switcher
│   └── workspace/              # Sub-step workspace, notes editor, evidence picker, AI sheet
└── services/                   # Groq API client, vector PDF report generator
```

### Unidirectional Data Flow

```
UI Widgets (Pages / Sheets / Dialogs)
  │
  ▼
Riverpod Providers & State Notifiers (AsyncValue, StateProvider)
  │
  ▼
Domain Repositories (Abstract Interfaces & Entities)
  │
  ▼
Data Repositories (Supabase Implementation)
  │
  ▼
Supabase PostgreSQL & Storage Buckets (Protected by Row Level Security)
```

---

## Core Features

### 1. Portfolio Dashboard (`/`)
- **Review Registry**: Displays active, pending, and completed engineering design reviews.
- **Search & Filter**: Real-time title search and stage/status filtering.
- **DRL Gauge**: Visual radial gauge summarizing portfolio readiness across active reviews.
- **Review Duplication (`cloneForCopy`)**: Clones an existing review into an independent copy with freshly minted UUIDs across all stages, sub-steps, workspaces, and stakeholders, leaving the original review unchanged.
- **Cover Image Management**: Uploads cover images directly to the public `images` bucket (`design_review/{reviewId}/{uuid}.{ext}`).

### 2. Design Review Detail (`/project/:id`)
- **10 Lifecycle Stages**: Tracks structured checklists from early requirements through production release.
- **Stage Progress Tracking**: Sub-step state machine (`notStarted`, `inProgress`, `completed`, `blocked`).
- **Stakeholder Registry**: Manages internal team members and external reviewers. Rejects case-insensitive duplicate names within the same review.
- **Access Guarding**: Reviews owned by admin or distinct accounts restrict modification permissions for unprivileged users.

### 3. Engineering Workspace (`/workspace/:id`)
- **Detailed Sub-Step Scope**: Displays problem statements, scope boundaries (`Scope In` / `Scope Out`), and stage guidelines.
- **Discipline Auto-Assignment**: Selecting an assigned stakeholder automatically fills the engineering discipline based on their assigned role.
- **Serialized Save Queue**: Prevents race conditions during rapid text changes. Notes and activity log entries are committed sequentially through a FIFO queue.
- **Evidence Management**: Uploads technical diagrams, test data, and documents to the private `attachments` bucket (`workspace/{workspaceId}/{uuid}_{filename}`). Opening attachments generates a short-lived 7-day signed URL.
- **Activity Log**: Timestamped audit trail tracking status transitions, assignees, and uploaded files.

### 4. On-Demand AI Engineering Analysis
- **Explicit Trigger**: Opening the AI Analysis modal does not invoke external APIs automatically. An explicit **"Analyze with AI"** trigger prevents accidental token usage.
- **Pre-Analysis Context Verification**: Explicitly presents the evaluation context before running the analysis:
  - **Project Name** with fallback logic.
  - **Description & Scope** cascading across: Item Description → Problem Statement → Default Stage Guidelines → Standard Verification Criteria.
  - **Metadata Badges**: Stage name, checklist item, discipline, priority (with dynamic color indicators), and assignee.
- **Multi-Tier Model Resilience**:
  - Primary model: `llama-3.3-70b-versatile` (deep technical evaluation).
  - Automatic fallback: `llama-3.1-8b-instant` (triggered if rate-limited on HTTP 429 or service unavailable on HTTP 503).
- **Dual Presentation Modes**:
  - **Formatted Cards**: Compact sections highlighting `KEY CHECKS`, `KEY RISKS`, `NEXT ACTIONS`, and `EVIDENCE REQUIREMENTS`.
  - **Notes Preview**: Pre-formatted Markdown ready for immediate insertion.
- **Workspace Integration**: One-click actions to either overwrite or append AI findings directly into the workspace notes editor.

### 5. Design Readiness Level (DRL) Engine (`/project/:id/drl`)
- **Mathematical Model**: Allocates 100.00% total weight across all 10 engineering lifecycle stages.
- **Binary Completion Contribution**: Only sub-steps marked with status `StageStatus.completed` contribute their weight to the total DRL percentage.
- **Stage Distribution**:

| Stage | Canonical Name | Sub-Steps | Stage Weight (%) |
| :---: | :--- | :---: | :---: |
| 1 | **Requirements** | 10 | 15.00% |
| 2 | **Concept** | 10 | 8.00% |
| 3 | **Preliminary Design** | 12 | 12.00% |
| 4 | **Detailed Design** | 13 | 16.00% |
| 5 | **Simulation (FEA, CFD...)** | 8 | 9.00% |
| 6 | **Prototype** | 8 | 8.00% |
| 7 | **Testing Validation** | 11 | 12.00% |
| 8 | **Manufacturing Readiness** | 8 | 8.00% |
| 9 | **Final Release** | 7 | 7.00% |
| 10 | **Continuous Improvement** | 5 | 5.00% |
| **Total** | | **92 Sub-Steps** | **100.00%** |

### 6. Publication-Grade PDF Report Engine (`services/pdf_report_service.dart`)
- Generates vector-rendered technical documentation suitable for regulatory compliance and customer review meetings.
- **Document Structure**:
  1. **Cover Page**: Project title, review status, creation date, company logo, and high-resolution cover image.
  2. **Executive Summary**: DRL radial gauge, stage completion status matrix, and stakeholder directory.
  3. **Technical Stage Audit**: Sub-step criteria, discipline, assignee, problem statement, scope definition, and engineering comments.
  4. **Workspace Notes & Logs**: Full notes text formatting and activity audit trail.
  5. **Evidence Annex**: File list with active signed hyperlinks allowing reviewers to download original technical artifacts directly from the PDF.
- **PDF Storage Screen (`/pdfs`)**: Browser interface listing generated project reports stored in Supabase Storage.

---

## Database Architecture (Supabase / PostgreSQL)

### Entity-Relationship Structure

```
profiles
  └── id (UUID, PK, references auth.users)
        │
        ├── design_reviews (created_by)
        │     ├── stakeholders (review_id)
        │     └── sub_steps (review_id)
        │           └── workspaces (sub_step_id)
        │                 └── workspace_comments (workspace_id)
```

### Table Definitions

| Table | Primary Key | Foreign Keys / References | Description |
| :--- | :--- | :--- | :--- |
| `profiles` | `id` | `auth.users(id)` | User profile populated via signup trigger (`first_name`, `last_name`, `email`). |
| `projects` | `id` | `created_by -> profiles(id)` | Grouping construct for related design reviews. |
| `design_reviews` | `id` | `project_id -> projects(id)`, `created_by -> profiles(id)` | Review metadata, DRL score, progress, and cover image URL. |
| `sub_steps` | `id` | `review_id -> design_reviews(id)` | Checklist entries linked to specific lifecycle stages. |
| `workspaces` | `id` | `sub_step_id -> sub_steps(id)` | Technical documentation: notes, evidence URLs, problem statements, discipline, due dates. |
| `stakeholders` | `id` | `review_id -> design_reviews(id)` | Personnel assigned to review milestones (name and functional role). |
| `workspace_comments` | `id` | `workspace_id -> workspaces(id)`, `user_id -> profiles(id)` | Collaboration feed for engineering notes and review feedback. |

### Storage Buckets & Access Control

| Bucket Name | Access Level | Path Pattern | Policy / Security |
| :--- | :--- | :--- | :--- |
| `images` | Public read on path | `design_review/{reviewId}/{uuid}.{ext}` | Public `SELECT` restricted exclusively to `design_review/%`. Authenticated `INSERT`/`UPDATE` requires review ownership. |
| `attachments` | Private (Signed URLs) | `workspace/{workspaceId}/{uuid}_{filename}` | Direct public access blocked. Access requires a 7-day HMAC signed URL issued to authenticated reviewers. |

### Database Migrations Reference

Migrations are located under `supabase/migrations/` and must execute in chronological sequence:

1. `20260718000001_enums.sql` — PostgreSQL custom enums (`review_status`, `stage_status`, `priority_level`).
2. `20260718000002_tables.sql` — Relational tables definition.
3. `20260718000003_indexes_constraints.sql` — Indexes on review IDs, workspace foreign keys, and unique constraints.
4. `20260718000004_triggers_functions.sql` — Automated `updated_at` timestamps and user registration profile handlers.
5. `20260718000005_rls.sql` — Row Level Security policies enforcing review and workspace ownership.
6. `20260718000006_storage.sql` — Storage bucket creation and access policy helpers (`can_access_storage_path`).
7. `20260718000007_fk_tweaks.sql` — Foreign key cascading rules.
8. `20260718000008_grants.sql` — Service-role and authenticated role privileges.
9. `20260719180000_fix_profile_trigger_metadata.sql` — Aligns user metadata reading with snake_case naming (`first_name`, `last_name`).
10. `20260720000001_storage_design_review_images.sql` — Configures `design_review` path prefixes in Storage.
11. `20260720000002_scope_public_images.sql` — Hardens `images` bucket to only permit public reads on the `design_review/` subfolder.

---

## Configuration & Environment Variables

### Client Configuration (`.env`)
Bundled into the Flutter application via `flutter_dotenv` (declared in `pubspec.yaml` assets).

```env
# Supabase Project Connection
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...

# Groq API Key for AI Engineering Analysis (Optional)
GROQ_API_KEY=gsk_...
```

> [!NOTE]
> Never place service-role keys or management tokens in `.env`. This file is compiled directly into the client binary.

### Administrative Configuration (`.env.admin`)
Local development and automated integration testing only. **Never committed to version control and excluded from binary assets.**

```env
SERVICE_ROLE_SECRET=eyJhbGciOi...
SUPABASE_PERSONAL_ACCESS_TOKEN=sbp_...
```

---

## Local Development & Execution

### Prerequisites
- Flutter SDK `^3.11.4` (channel stable)
- Google Chrome (for web target)
- Supabase Project or local Supabase CLI instance

### 1. Web Application (Chrome)
Run the application on a fixed port to support stable Supabase Auth redirects:

```bash
# Fetch package dependencies
flutter pub get

# Launch on Chrome
flutter run -d chrome --web-port=8080
```

### 2. Desktop Application (macOS)
```bash
flutter run -d macos
```

### 3. Production Android APK
Evalio Design includes an automated build script (`scripts/build_apk.sh`) that verifies security hygiene before compilation:

```bash
chmod +x scripts/build_apk.sh
./scripts/build_apk.sh
```

- **Validation Gate**: The script checks `.env` and aborts if service-role secrets or personal access tokens are detected.
- **Output**: Generates APK under `build/apk_dist/evalio-design-release-YYYYMMDD_HHMMSS.apk`.

---

## Verification & Testing

The project maintains comprehensive test coverage across unit, widget, and live integration layers:

```bash
# Run all unit and widget tests (No backend required)
flutter test test/unit/ test/ai_analysis_sheet_test.dart test/groq_service_test.dart test/widget/

# Run targeted test suites
flutter test test/ai_analysis_sheet_test.dart          # AI Analysis sheet pre-analysis & trigger
flutter test test/groq_service_test.dart                # Groq API service & model fallback
flutter test test/unit/pdf_report_service_test.dart    # PDF document generation & hyperlinks
flutter test test/unit/clone_for_copy_test.dart        # Review deep clone logic
flutter test test/widget/workspace_permissions_test.dart # Role access & permissions

# Run integration tests against a live Supabase backend (Requires .env and .env.admin)
flutter test test/integration/

# Static code analysis
flutter analyze lib/
```

---

## Project Directory Tree

```text
project_flow/
├── android/                    # Android host runner & manifests
├── assets/                     # App branding, vector icons, fallback graphics
│   ├── ed-logo.png
│   ├── evalio_logo.png
│   └── pump-housing.png
├── ios/                        # iOS host configuration
├── lib/
│   ├── core/                   # Shared database, router, localization, theme
│   ├── features/
│   │   ├── auth/               # User authentication & session routing
│   │   ├── dashboard/          # Review cards, gauges, stats, cover uploads
│   │   ├── projects/           # Lifecycle checklists & DRL scoring
│   │   ├── reviews/            # Domain models, repositories, deep copy logic
│   │   ├── settings/           # Localization & theme toggles
│   │   └── workspace/          # Engineering workspace & AI analysis modal
│   ├── services/
│   │   ├── groq_service.dart   # Groq Cloud LLM client & model fallback
│   │   └── pdf_report_service.dart # Publication-grade vector PDF generator
│   └── main.dart               # App entrypoint & Supabase initialization
├── macos/                      # macOS desktop runner
├── scripts/
│   └── build_apk.sh            # Safe Android release build pipeline
├── supabase/
│   ├── config.toml             # Local Supabase configuration
│   └── migrations/             # Timestamped SQL database migrations
├── test/
│   ├── ai_analysis_sheet_test.dart # AI modal widget tests
│   ├── groq_service_test.dart      # Groq client unit tests
│   ├── integration/                # Live Supabase auth & RLS tests
│   ├── unit/                       # Entity, PDF, and clone logic tests
│   └── widget/                     # Dashboard, workspace, router tests
├── web/                        # Web assembly runner, manifest, and icons
├── .env.example                # Template for environment configuration
├── pubspec.yaml                # Package manifest & asset registrations
└── README.md                   # System documentation
```

---

## Operational Notes & Troubleshooting

- **Supabase Auth Redirects**: In development, ensure the Supabase Auth Redirect URLs contain `http://localhost:8080/` (or the corresponding production domain).
- **Offline / Missing Groq Key**: If `GROQ_API_KEY` is not present in `.env`, the workspace gracefully presents a setup guide card instructing the user to configure their key without crashing or freezing the UI.
- **Large Evidence Files**: The attachment picker enforces an in-memory threshold of ~20 MB per file to ensure stability on memory-constrained mobile environments.
- **Copy Review Scope**: Copying a review duplicates all checklists and structural workspaces, but resets stage statuses to `notStarted` and clears cover images to maintain a clean revision history.
