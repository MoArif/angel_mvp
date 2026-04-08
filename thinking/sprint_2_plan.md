# Sprint 2: Automated Safety Monitoring (AM-12, AM-13, AM-14)

## Objective
The goal is to move from manual check-ins to **automated reliability**. We will implement the ability for users to set safety schedules and automatically track app activity as a "silent check-in" signal.

## User Review Required
> [!IMPORTANT]
> **Timezone Sync:** Scheduled check-ins depend on the device's timezone. We will ensure the `checkin_schedules` table stays in sync with the user's current timezone captured during onboarding/settings.
> 
> **App Lifecycle:** For silent check-ins (AM-13), we will monitor when the app enters the foreground. This does not require a background service yet, as we are optimizing for "active use" detection first.

## Proposed Changes

### UI Components

#### [NEW] `lib/features/schedules/screens/schedules_screen.dart`
- A screen to list, add, and toggle check-in windows.
- Users can define a Time Range (Start/End).

#### [NEW] `lib/features/schedules/widgets/add_schedule_dialog.dart`
- A dialog using `showTimePicker` to let users define new safety windows.

### State Management & Logic

#### [NEW] `lib/features/schedules/providers/schedules_provider.dart`
- Stream provider for `checkin_schedules`.
- Methods to `addSchedule`, `deleteSchedule`, and `toggleEnabled`.

#### [MODIFY] `lib/main.dart`
- Add an `AppLifecycleObserver` to track when the app comes to the foreground.
- Automatically trigger an `activity_signals` insert of type `app_open`.

### Infrastructure

#### [NEW] `lib/core/services/lifecycle_service.dart`
- A service to handle the `app_open` signal logic separate from the UI.

## Open Questions
1. **Overlap Handling:** Should we allow overlapping check-in schedules, or should the UI block them?
2. **Frequency:** For silent check-ins, should we limit "app_open" signals to once every 5-10 minutes to avoid database bloat?

## Verification Plan

### Automated Testing
- Unit tests for the `schedules_provider` logic (mocking Supabase).

### Manual Verification
1. Add a schedule and verify it appears in the Supabase `checkin_schedules` table.
2. Background the app and foreground it; verify a new `app_open` row appears in `activity_signals`.
3. Toggle a schedule and verify the `enabled` boolean flips in the database.
