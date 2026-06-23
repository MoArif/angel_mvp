# 📱 Smart Check-In Safety App — MVP Implementation Plan (Supabase Edition)

## 🎯 Objective
Build a **reliable, low-friction safety check-in system** that:
- Minimizes user effort via **silent check-ins** (app activity)
- Reduces false alarms via a **confidence score**
- Escalates intelligently to **trusted contacts via SMS/Push**

> [!TIP]
> **MVP Focus:** Speed and reliability. By using Supabase, we eliminate backend boilerplate (FastAPI, Redis, Celery, Docker) and interact directly with the database via the Flutter SDK, moving scheduling and escalation logic into serverless Edge Functions.

---

# 🔷 1. MVP Scope (Strict)

## Core Features
- Manual check-in ("I'm OK")
- Scheduled check-ins (time window based)
- Silent check-ins (based on foreground app opens / active use)
- Confidence score (heuristic)
- Escalation to 1–2 contacts (via SMS through Twilio)
- Push notifications for user warnings (via FCM/Supabase)
- SMS Acknowledgment (Contacts can click a link to cancel the alert)
- Basic permissions onboarding

---

# 🔷 2. Tech Stack

## Frontend (Mobile)
- Flutter (iOS & Android)
- State Management: Riverpod
- Supabase Flutter SDK

## Backend (Serverless)
- **Supabase:**
  - Auth (replaces Firebase Auth)
  - PostgreSQL Database
  - PostgREST API (Auto-generated CRUD)
  - Edge Functions (TypeScript)
  - `pg_cron` & `pg_net` (Database native scheduler & HTTP worker)
- **Twilio**: SMS API (For notifying contacts who don't have the app)
- **Firebase Cloud Messaging (FCM)**: Push notifications to the User.

---

# 🔷 3. System Architecture

```mermaid
graph TD
    A[Flutter App] <-->|Supabase SDK| B[Supabase APIs & Auth]
    B <--> C[(PostgreSQL Database)]
    D[pg_cron Scheduler] -->|Every 5 mins| E[Escalation Edge Function]
    E <--> C
    E -->|If Alert Needed| F[Twilio API]
    F -->|SMS| G[Trusted Contact]
    E -->|If Warning Needed| H[FCM]
    H -->|Push Notification| A
    G -->|Clicks HTTP Link| I[Webhook Edge Function]
    I -->|Acknowledge Alert| C
```

---

# 🔷 4. Detailed Implementation - AM-6: Supabase Setup

## SQL Schema & RLS Policies

```sql
-- 1. Profiles (Sync with Auth)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  name text,
  phone text,
  timezone text,
  push_token text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Trigger for profile creation
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name)
  values (new.id, new.raw_user_meta_data->>'name');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 3. Core Tables
create table public.contacts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  name text not null,
  phone text not null,
  priority integer check (priority in (1, 2)) not null
);

create table public.checkin_schedules (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  start_time time not null,
  end_time time not null,
  timezone text not null,
  enabled boolean default true not null
);

create table public.checkin_events (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  scheduled_time timestamp with time zone not null,
  status text check (status in ('pending', 'completed', 'missed', 'escalating')) default 'pending' not null,
  confidence_score float default 0.0,
  created_at timestamp with time zone default now()
);

create table public.activity_signals (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  type text check (type in ('app_open', 'manual_checkin')) not null,
  created_at timestamp with time zone default now()
);

create table public.alerts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  checkin_event_id uuid references public.checkin_events(id) on delete cascade not null,
  contact_id uuid references public.contacts(id) on delete cascade not null,
  status text check (status in ('sent', 'acknowledged')) default 'sent' not null,
  acknowledgement_token uuid default gen_random_uuid() not null,
  created_at timestamp with time zone default now()
);

-- 4. Enable RLS
alter table public.profiles enable row level security;
alter table public.contacts enable row level security;
alter table public.checkin_schedules enable row level security;
alter table public.checkin_events enable row level security;
alter table public.activity_signals enable row level security;
alter table public.alerts enable row level security;

-- 5. RLS Policies
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

create policy "Users can manage own contacts" on public.contacts for all using (auth.uid() = user_id);
create policy "Users can manage own schedules" on public.checkin_schedules for all using (auth.uid() = user_id);
create policy "Users can view own events" on public.checkin_events for select using (auth.uid() = user_id);
create policy "Users can insert own signals" on public.activity_signals for insert with check (auth.uid() = user_id);
create policy "Users can view own alerts" on public.alerts for select using (auth.uid() = user_id);
```

---

# 🔷 5. Unified Build Plan (3-4 Weeks)

## Week 1: Foundation & Supabase Setup [COMPLETED]
- [x] Initialize Flutter project with Riverpod & routing.
- [x] **[AM-6]** Set up Supabase project, create tables, and write Row Level Security (RLS) policies.
- [x] **[AM-7]** Implement Supabase Auth (Sign up / Login) in Flutter.

## Week 2: Core UX & SDK Integration [COMPLETED]
- [x] Build Onboarding UI and Permissions request flow.
- [x] Build Contacts management UI & database integration.
- [x] Build Dashboard UI and "Manual Check-in" logic.
- [x] Implement AppLifecycle tracking to record "App Open" events to Supabase.

## Week 3: Background Logic (Edge Functions)
- Write the `pg_cron` database job to schedule tick events.
- Write the `escalation-worker` Typescript Edge function.
- Integrate Twilio API into Edge Function.
- Write the `alert-webhook` Edge Function to generate the public HTML acknowledgment page.

## Week 4: Polish & Testing
- Integrate Firebase Cloud Messaging via Supabase Edge integrations.
- Exhaustive timezone testing.

---

# 🔷 6. Detailed Implementation - AM-7: Supabase Auth

## Objective
Implement core authentication using the Supabase Flutter SDK and Riverpod for state management.

## Proposed Changes

### [Component] Lib (`/lib`)

#### [MODIFY] [main.dart](file:///home/mofassir/PycharmProjects/angelMVP/angle_mvp/lib/main.dart)
Initialize the Supabase SDK with the local URL and anon key.

### [Component] Features (`/lib/features`)

#### [NEW] `auth/providers/auth_provider.dart`
Create a Riverpod provider to manage the user session and auth state.
```dart
final supabaseAuthProvider = StreamProvider((ref) => Supabase.instance.client.auth.onAuthStateChange);
```

#### [NEW] `auth/screens/login_screen.dart`
A modern, premium login screen with:
- Email/Password input validation.
- Loading states for the "Login" button.
- Error feedback using Snackerbars.

#### [NEW] `auth/screens/signup_screen.dart`
Registration screen with:
- Name, Email, Password inputs.
- Passwords confirmation logic.

### [Component] Core (`/lib/core`)

#### [MODIFY] `router/router_provider.dart` (or `main.dart`)
Implement an `AuthGuard` using GoRouter to:
- Redirect unauthenticated users to `/login`.
- Redirect authenticated users from `/login` to `/dashboard`.

## Open Questions

- **Local Development Credentials**: Since you're running Supabase in Docker, the URL should typically be `http://localhost:8000`. I will retrieve the `ANON_KEY` from the `.env` file in the `angel_mvp_subabase` directory.
- **Styling Preference**: Should I use a specific design language (e.g., Material 3 with custom colors) for the Auth screens? (I'll aim for a "premium, trust-focused" look by default).

## Verification Plan

### Automated Tests
- Integration test for `Supabase.instance.client.auth.signInWithPassword`.
- Unit test for the `AuthProvider` state transitions.

### Manual Verification
- Visual check of Login/Signup screens.
- Test successful signup check if `profiles` row is created.
- Test login with valid/invalid credentials.

---

# 🧠 Core Principle

This is not an AI product. This is a **trust product**.

- Reliability > Intelligence  
- Simplicity > Features  
- Consistency > Cleverness

---

# 🔷 7. Feature Refinement & Polish

## Objective
Refine the currently implemented MVP features (Authentication and Dashboard) to ensure robust form validation, scalable component separation, and flawless user experience before building the next features.

## User Review Required
> [!IMPORTANT]
> The current dashboard uses monolithic UI and placeholder statistics. Moving forward, we'll extract these into functional placeholder components to prepare for backend data (shimmers, pull-to-refresh). Please review the refinement tasks below and approve the plan to proceed.

## Proposed Changes

### [Component] Authentication (`/lib/features/auth`)
#### [MODIFY] `screens/login_screen.dart`
#### [MODIFY] `screens/signup_screen.dart`
- Implement `Form` with client-side validation logic (e.g. Email parsing, password lengths).
- Add `FocusNode` handling so user can use the "Next" button comfortably on keyboards.

### [Component] Auth Provider
#### [MODIFY] `providers/auth_provider.dart`
- Capture specific `AuthException` to return user-friendly, localized error messages instead of raw string traces.

### [Component] Dashboard (`/lib/features/dashboard`)
#### [MODIFY] `screens/dashboard_screen.dart`
#### [NEW] `widgets/user_header.dart` (or similarly separated out components)
#### [NEW] `widgets/stat_metrics.dart`
- Decompose the monolith dashboard code into highly maintainable, isolated smaller widgets.
- Implement pull-to-refresh `RefreshIndicator` and shimmer loading placeholders.

## Open Questions

- **Dashboard Layout Strategy**: Currently, it's a fixed scroll view. Should we create dummy functions for refreshing this view so it operates identically to the final integration? (I plan to attach a dummy Future delayed return to the refresh action).

## Verification Plan

### Manual Verification
- Testing invalid login combinations triggers accurate red Snackbars.
- Keyboards cleanly move from Email to Password field when tapping "next".
- The dashboard visually looks identical or enhanced but its code is clearly decoupled.

---

# 🔷 8. Sprint 1: Base Feature Implementations (AM-8, AM-9, AM-10)

## Objective
Implement Onboarding Flow (Timezone & Permissions), Contacts Management, and the Core Dashboard Manual Check-in logic. This sprint completes the foundational front-end mechanisms required before escalating background tasks.

## User Review Required
> [!IMPORTANT]
> In Onboarding, since FCM is not formally wired yet, is it acceptable to mock the push token logically, but legitimately retrieve and save the true device timezone to the `profiles` table in Supabase? Also, please approve the `Task` checklist.

## Proposed Changes

### [Component] Onboarding (`/lib/features/onboarding`)
#### [NEW] `screens/onboarding_screen.dart`
- Create a UI to prompt users for Push Notification permissions (using `permission_handler`) and detect device timezone (using `flutter_timezone`).
- Supabase Integration: Update the `timezone` and `push_token` fields in the `profiles` schema.
#### [MODIFY] `router/router_provider.dart`
- Route interceptor: If a logged-in user has a null `timezone` in their profile, securely redirect them to `/onboarding`.

### [Component] Settings (`/lib/features/settings`)
#### [NEW] `screens/contacts_screen.dart`
- Manage trusted friends. Form interface connecting directly to the `contacts` table in Supabase via Streams.
- Allows addition of trusted contact (Name, Phone number).

### [Component] Dashboard Logic (`/lib/features/dashboard`)
#### [MODIFY] `screens/dashboard_screen.dart`
- Wire up the "I'm OK!" manual check-in button (an aesthetic, prominent action button).
- When pressed, insert a record into `activity_signals` table with `type = 'manual_checkin'`.
- Visually indicate success via SnackBar and animation.

## Open Questions
- **Contact limits**: Currently the database schema (`contacts`) just has priorities but no strict cap. Do we restrict the user to a maximum of 2 trusted contacts on the client side?

## Verification Plan
### API Checks
- Verify newly inserted rows into `activity_signals` and `contacts` in Supabase.
### Manual Verification
- Simulate signup -> verify redirection intercepts immediately to `/onboarding`.
- Ensure timezone detected matches local timezone strings (e.g. `America/Los_Angeles`).

---

# 🔷 9. Sprint 2: Automated Safety Monitoring (AM-12, AM-13, AM-14) [CURRENT]

## Objective
Establish the background logic and automated safety loops (silent monitoring + timed check-in windows) and connect them to real escalation routes (Twilio SMS and Webhooks).

## Completed Components
- **AM-12: Scheduled Check-ins**
  - CRUD operations on `checkin_schedules` table in Supabase.
  - Interactive UI for listing, adding, and toggling schedules.
- **AM-13: Silent Check-ins**
  - Lifecycle tracking to capture app foreground transitions.
  - Auto-inserts `app_open` signal with a 5-minute rate limit.
- **AM-9: Contacts Management (Enhanced)**
  - Native contact picking integrated in bottom sheet.

## Proposed Changes (Next Steps)

### [Component] Database Scheduler & Functions (`/supabase-project`)

#### [NEW] `volumes/functions/escalation-worker/index.ts`
TypeScript Edge function running on Deno:
- Periodically checks for active schedules.
- Identifies if a user has missed their check-in window.
- Computes confidence metric using recent `activity_signals` (`manual_checkin`, `app_open`).
- Integrates with Twilio API to dispatch automated warning SMS text alerts to Emergency Contacts.

#### [NEW] `volumes/functions/alert-webhook/index.ts`
TypeScript Edge function to serve the acknowledgment landing page:
- Renders a clean HTML interface.
- Emergency contacts click the link containing a unique token, which executes a DB mutation marking the alert as `acknowledged`.

#### [MODIFY] `volumes/db/init/data.sql` (or schema migration)
Database cron job execution commands:
- Register the `escalation-worker` call frequency (every 5 minutes) via `pg_cron`.
- Set up notification trigger templates.

#### [MODIFY] `.env`
Add integration environment keys:
- Twilio Account SID, Auth Token, Messaging Service SID.
- Firebase FCM service account keys.

## Open Questions
- **Twilio Account Access:** Do we have sandboxed credentials to verify the SMS delivery loop locally, or should we use placeholder test keys first?
- **FCM integration:** Is push notification delivery required locally inside the Docker dev environment, or is physical device verification (APNs/FCM) scheduled for staging/production environments?

## Verification Plan
### Automated Tests
- Test cases for checking timezone window overlapping.
- Mock tests for the Twilio/Edge Function endpoint payloads.
### Manual Verification
- Simulate missing a check-in window -> verify the `escalation-worker` triggers.
- Trigger SMS delivery and click the webhook link to verify the state transitions from `sent` to `acknowledged`.