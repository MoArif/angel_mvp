# 📱 Smart Check-In Safety App — MVP Implementation Plan

## 🎯 Objective
Build a **reliable, low-friction safety check-in system** that:
- Minimizes user effort via **silent check-ins**
- Reduces false alarms via a **confidence score**
- Escalates intelligently to **trusted contacts**

---

# 🔷 1. MVP Scope (Strict)

## Core Features
- Manual check-in ("I'm OK")
- Scheduled check-ins (time window based)
- Silent check-ins (basic activity signals)
- Confidence score (heuristic)
- Escalation to 1–2 contacts
- Push notifications (user + contacts)
- Basic onboarding

---

# 🔷 2. Tech Stack

## Frontend
- Flutter
- State Management: Riverpod

## Backend
- FastAPI (Python)
- PostgreSQL
- Redis (for background jobs)
- Celery (scheduler/worker)

## External Services
- Firebase Auth (authentication)
- Firebase Cloud Messaging (push notifications)

---

# 🔷 3. System Architecture

```
Flutter App
    ↓
FastAPI Backend
    ↓
PostgreSQL Database
    ↓
Celery Worker (Scheduler)
    ↓
Firebase Cloud Messaging (Notifications)
```

---

# 🔷 4. Data Models

## User
```sql
User {
  id (uuid)
  name
  email
  phone
  timezone
  created_at
}
```

## Contact
```sql
Contact {
  id
  user_id
  name
  phone_or_email
  priority (1 or 2)
  verified (bool)
}
```

## CheckInSchedule
```sql
CheckInSchedule {
  id
  user_id
  start_time
  end_time
  frequency (daily)
  enabled (bool)
}
```

## CheckInEvent
```sql
CheckInEvent {
  id
  user_id
  scheduled_time
  status (pending, completed, missed)
  confidence_score (float)
  created_at
}
```

## ActivitySignal
```sql
ActivitySignal {
  id
  user_id
  type (app_open, movement, manual_checkin, heartbeat)
  timestamp
}
```

## Alert
```sql
Alert {
  id
  user_id
  checkin_event_id
  status (pending, sent, acknowledged)
  escalation_level (0,1,2)
  created_at
}
```

---

# 🔷 5. Backend API Design

## Auth
```
POST /auth/login
```

## User
```
GET /user
POST /user
```

## Contacts
```
POST /contacts
GET /contacts
DELETE /contacts/{id}
```

## Check-ins
```
POST /checkin/manual
GET /checkin/today
```

## Activity
```
POST /activity
```

## Alerts
```
GET /alerts
POST /alerts/acknowledge
```

---

# 🔷 6. Core Backend Logic

## 6.1 Confidence Score (Heuristic)

```python
def compute_confidence(user_id):
    signals = get_recent_signals(user_id, last_hours=6)

    score = 0.0

    if has_signal(signals, "manual_checkin"):
        return 1.0

    if has_signal(signals, "app_open", within_hours=2):
        score += 0.5

    if has_signal(signals, "movement", within_hours=4):
        score += 0.3

    if is_night_time(user_id):
        score += 0.2

    return min(score, 1.0)
```

---

## 6.2 Silent Check-In

```python
if confidence_score > 0.7:
    mark_checkin_completed(event_id)
```

---

## 6.3 Scheduler (Celery)

Runs every 5 minutes:

```python
for user in active_users:
    if in_checkin_window(user):
        event = get_or_create_event(user)

        score = compute_confidence(user.id)

        if score > 0.7:
            mark_completed(event)
        elif is_past_window(event):
            trigger_escalation(event)
```

---

## 6.4 Escalation Logic

```python
if missed_checkin:
    wait(grace_period=30_minutes)

    if no_new_activity:
        notify_user()

    if still_no_response:
        notify_contact(priority=1)

    if still_no_response:
        notify_contact(priority=2)
```

---

# 🔷 7. Flutter App Architecture

## Folder Structure

```
lib/
 ├── core/
 │   ├── services/
 │   ├── utils/
 │
 ├── features/
 │   ├── auth/
 │   ├── onboarding/
 │   ├── checkin/
 │   ├── contacts/
 │   ├── alerts/
 │
 ├── shared/
 │   ├── models/
 │   ├── widgets/
 │
 └── main.dart
```

---

## State Management (Riverpod Providers)

- authProvider
- userProvider
- checkinProvider
- activityProvider
- alertProvider

---

# 🔷 8. Key Screens

## Onboarding
- Enter name
- Add 1 contact
- Set check-in time window

## Home Screen
- Status indicator (“You’re good 👍”)
- Confidence score (progress bar)
- “I’m OK” button

## Contacts Screen
- Add/remove contacts

## Alerts Screen
- Alert history

---

# 🔷 9. Activity Tracking (Flutter)

## App Lifecycle Detection

```dart
class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sendActivity("app_open");
    }
  }
}
```

---

## Background Heartbeat

Use:
- workmanager (Android)
- background_fetch (iOS)

```dart
sendActivity("heartbeat");
```

---

## Manual Check-In

```dart
onPressed: () {
  api.post("/checkin/manual");
}
```

---

# 🔷 10. Notifications (FCM)

## Types

1. Reminder  
   “Haven’t heard from you—tap to check in”

2. Escalation Warning  
   “We may notify your contact soon”

3. Contact Alert  
   “No response from [User]”

---

# 🔷 11. User Flow

```
User opens app
    ↓
System shows confidence status
    ↓
User optionally taps "I'm OK"
    ↓
Background system monitors activity
    ↓
Missed check-in → escalation flow
```

---

# 🔷 12. Deployment

## Backend
- Dockerize FastAPI
- Deploy to Fly.io or AWS

## Database
- Managed PostgreSQL (Supabase or RDS)

## Redis
- Required for Celery

## Firebase
- Auth + Push Notifications

---

# 🔷 13. Build Plan (4 Weeks)

## Week 1
- Backend setup (FastAPI)
- Database schema
- Firebase Auth

## Week 2
- Flutter UI (basic screens)
- Manual check-in flow
- Contacts

## Week 3
- Activity tracking
- Confidence scoring
- Scheduler (Celery)

## Week 4
- Notifications (FCM)
- Escalation logic
- Testing edge cases

---

# 🔷 14. Critical Constraints

## DO
- Prioritize reliability
- Minimize false alerts
- Ensure notifications always work

## DO NOT
- Add machine learning
- Overcomplicate UI
- Add too many signals

---

# 🔷 15. Success Criteria (MVP)

- User onboarding < 2 minutes
- Manual + silent check-ins working
- Missed check-ins trigger escalation correctly
- Contacts reliably receive alerts
- Low false positive rate

---

# 🧠 Core Principle

This is not an AI product.

This is a **trust product**.

- Reliability > Intelligence  
- Simplicity > Features  
- Consistency > Cleverness