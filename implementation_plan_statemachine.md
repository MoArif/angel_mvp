# Escalation State Machine Implementation Plan

This plan details replacing the simplistic check-in event statuses with a formal state machine to support the complete alert lifecycle, with dual-layer safety constraints (database-level triggers + application-level TypeScript validation), conservative migrations, and a transition audit log for observability.

## User Review Required

> [!IMPORTANT]
> The database migrations modify the existing `public.checkin_events` table and rewrite active/historical records matching `completed`, `missed`, and `escalating`. Please review the migration strategy below before executing, especially for production or staging environments.

> [!WARNING]
> Because we are transitioning existing state constraints, any direct client SDK updates that set `status` to `completed` or `missed` will fail once the new check constraints and database-level trigger are active. The Flutter app client will need to transition to calling endpoints/RPCs that move events to `resolved`.

## Open Questions

There are no unresolved open questions. The state machine transitions, metadata, and database enforcement are fully aligned with the requirements.

---

## Proposed Changes

### Database Layer

#### [MODIFY] [data.sql](file:///home/mofassir/PycharmProjects/angelMVP/supabase-project/volumes/db/init/data.sql)
We will add the migration and structure definition to `data.sql` so fresh local containers boot up with the new schema, triggers, and state machine definitions.

We will write SQL steps to:
1. Create the `resolution_type_enum` type:
   ```sql
   create type public.resolution_type_enum as enum (
     'on_time',
     'after_warning',
     'after_contact_alert',
     'contact_confirmed',
     'manual_override',
     'legacy_migration'
   );
   ```
2. Modify `public.checkin_events` table:
   - Drop the old status check constraint if it exists.
   - Add `resolution_type` column referencing `public.resolution_type_enum`.
   - Update `status` to be check-constrained by: `('pending', 'warning_sent', 'user_contacted', 'contact_alerted', 'acknowledged', 'resolved')`.
3. Migrate existing data conservatively:
   - Update status `completed` ──> `resolved` (with `resolution_type = 'on_time'`).
   - Update status `escalating` ──> `contact_alerted` (with `resolution_type = 'legacy_migration'`).
   - Update status `missed` ──> `resolved` (with `resolution_type = 'legacy_migration'`).
4. Create the `checkin_state_transitions` audit table:
   ```sql
   create table public.checkin_state_transitions (
     id uuid default gen_random_uuid() primary key,
     checkin_event_id uuid references public.checkin_events(id) on delete cascade not null,
     from_state text not null,
     to_state text not null,
     reason text,
     created_at timestamptz default now() not null
   );
   ```
5. Implement the database trigger validation function `public.enforce_checkin_event_transitions()`:
   - Validates that transition from `OLD.status` to `NEW.status` is one of the allowed transitions:
     - `pending` ──> `warning_sent`, `user_contacted`, `resolved`
     - `warning_sent` ──> `user_contacted`, `contact_alerted`, `resolved`
     - `user_contacted` ──> `contact_alerted`, `resolved`
     - `contact_alerted` ──> `acknowledged`, `resolved`
     - `acknowledged` ──> `resolved`
     - Keep `OLD.status = NEW.status` allowed (no change).
   - If invalid, throws an error: `raise exception 'Invalid check-in event status transition from % to %', OLD.status, NEW.status;`.
   - On valid transition, inserts an audit log row into `checkin_state_transitions`.
6. Attach trigger `before update on public.checkin_events for each row execute function public.enforce_checkin_event_transitions()`.

---

### Application Layer (Deno / Edge Functions)

#### [NEW] [state_transitions.ts](file:///home/mofassir/PycharmProjects/angelMVP/supabase-project/volumes/functions/escalation-worker/state_transitions.ts)
A Deno-compatible TypeScript helper implementing:
- Type safety for check-in statuses (`CheckinStatus`) and resolution types.
- An `isValidTransition(from: CheckinStatus, to: CheckinStatus): boolean` function.
- A `validateTransitionOrThrow(from: CheckinStatus, to: CheckinStatus): void` function.

#### [NEW] [state_transitions_test.ts](file:///home/mofassir/PycharmProjects/angelMVP/supabase-project/volumes/functions/escalation-worker/state_transitions_test.ts)
Deno unit tests covering:
- Valid transition paths (e.g. `pending` ──> `warning_sent`, `warning_sent` ──> `resolved`).
- Invalid transition paths (e.g. `resolved` ──> `pending`, `acknowledged` ──> `warning_sent`), asserting they throw validation errors.

---

## Verification Plan

### Automated Tests
Run Deno's built-in testing tool locally to assert that all transition checks work as expected:
```bash
deno test supabase-project/volumes/functions/escalation-worker/state_transitions_test.ts
```

### Manual Verification
1. Start/restart Supabase local development:
   ```bash
   supabase db reset
   ```
2. Manually test state transitions by executing SQL updates via Supabase DB console or psql:
   - Valid change: Assert that changing an event from `pending` to `warning_sent` succeeds and adds a row in `checkin_state_transitions`.
   - Invalid change: Assert that changing an event from `resolved` back to `pending` fails with the custom PG trigger error.
