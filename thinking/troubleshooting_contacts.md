# Troubleshooting: MissingPluginException for flutter_contacts

## 1. Analysis
The error `MissingPluginException` almost always means that the native Android/iOS code for a new plugin was added (`flutter_contacts`), but the app was hot-reloaded or hot-restarted instead of being **fully stopped and rebuilt**. Native changes (like adding a plugin or changing permissions in AndroidManifest) cannot be applied without a full build.

## 2. Proposed Fix
- Run `flutter clean`.
- Run `flutter pub get`.
- Instruct the user to **fully stop** the app on their device/emulator and run `flutter run` again.

## 3. Alternative Check
If the clean/rebuild doesn't work, I'll check if the package version `2.0.2` is required for the user's specific Flutter version. But generally, the rebuild is the primary fix.
