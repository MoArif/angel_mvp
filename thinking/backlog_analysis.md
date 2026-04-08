# Backlog Analysis & Sprint 2 Proposal

## Completed (Sprint 1)
- AM-8: Onboarding UI & Permissions
- AM-9: Contacts Management
- AM-10: Dashboard Logic (Manual Check-ins)

## Backlog (High Priority)
- AM-12: Scheduled check-ins UI (Setting up windows)
- AM-13: Silent check-ins (Tracking app foreground/activity)
- AM-14: Escalation Edge Function (The "Brain" on Supabase)
- AM-15: Twilio Integration (SMS delivery)
- AM-16: Firebase Cloud Messaging (Push notifications)

## Proposed Sprint 2: The Logic Engine
Objective: Connect the UI actions to actual background safety logic.

1. **AM-12: Scheduled Check-ins**
   - Build UI for users to define "Safety Windows" (e.g., 9 PM to 11 PM).
   - Sync these windows to the database.

2. **AM-13: Silent Check-ins**
   - Implement background/foreground lifecycle listeners.
   - Send `app_open` or `activity` signals to Supabase automatically.

3. **AM-14: Logic Foundation**
   - Prepare the `pg_cron` or Edge Function hooks to monitor these signals.
