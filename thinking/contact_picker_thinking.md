# Thinking: Native Contact Picker Integration

## 1. Package Selection
I'll use `flutter_contacts`. It's the most flexible package for this.
It allows us to:
- Request permissions for contacts.
- Open the native OS contact picker.
- Parse the returned contact data (Name, Phone).

## 2. Permissions
- **Android:** `READ_CONTACTS` in `AndroidManifest.xml`.
- **iOS:** `NSContactsUsageDescription` in `Info.plist`.

## 3. UI Changes
- In `AddContactBottomSheet`, add a "Pick from Phone" button/icon near the Name/Phone fields.
- On tap:
    - Check for permissions.
    - If granted, open `FlutterContacts.openExternalPick()`.
    - Populate the text controllers with the selected contact's data.

## 4. Implementation Steps
1. Add `flutter_contacts` to `pubspec.yaml`.
2. Update `AndroidManifest.xml`. (User is on Linux/Android focus).
3. Update `AddContactBottomSheet` logic.

## 5. Branch
I am currently on `feature/AM-10-manual-checkin`. Since this is a follow-up to contacts, I'll stay here or rename. Actually, the user wants me to continue. I'll just keep working here but I'll update the `Task` list.
