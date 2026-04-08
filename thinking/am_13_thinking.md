# Thinking Process: AM-13 Silent Check-ins & Lint Fixes

## 1. Timezone Lint Fix
The `flutter_timezone` package version seems to return an object (or the lint thinks so) even though the variable is typed as `String`. I will remove the explicit `String` type and use `toString()` to ensure compatibility.

## 2. AM-13 Implementation
- **Goal:** Detect when the user opens the app (moves to foreground) and mark it as a "Silent Check-in".
- **Logic:** Listen to `WidgetsBindingObserver.didChangeAppLifecycleState`.
- **Throttling:** Don't send a signal more than once every 5 minutes. This prevents database spam if the user toggles many apps.
- **Storage:** Use a local timestamp in the service to manage the cooldown.

## 3. main.dart Integration
- Wrap the main app or a top-level provider with the observer.
- Since we use Riverpod, I'll create an `AppLifecycleProvider` that initializes the listener.
