# Plan: Native Contact Picker Integration

## Objective
Allow users to select trusted contacts directly from their phone's contact list instead of manual entry.

## Proposed Changes

### Configuration
- **Android:** Add `<uses-permission android:name="android.permission.READ_CONTACTS" />` to `AndroidManifest.xml`.

### UI: AddContactBottomSheet
- Add a "Pick from Phone" button next to the "Name" or "Phone Number" field.
- Convert the fields to use `TextEditingController` for programmatic updates.
- Logic:
    1. Request permission using `flutter_contacts`.
    2. Open the native picker using `FlutterContacts.openExternalPick()`.
    3. Extract the primary name and first phone number.
    4. Populate the controllers.

## Verification
- Run the app on an Android emulator/device.
- Click "Pick from Phone".
- Grant permission.
- Select a contact with a valid phone number.
- Verify name and phone are auto-filled in the form.
