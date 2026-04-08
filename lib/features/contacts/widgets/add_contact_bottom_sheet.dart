import 'package:angle_mvp/core/theme/app_theme.dart';
import 'package:angle_mvp/features/contacts/providers/contacts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddContactBottomSheet extends ConsumerStatefulWidget {
  const AddContactBottomSheet({super.key});

  @override
  ConsumerState<AddContactBottomSheet> createState() => _AddContactBottomSheetState();
}

class _AddContactBottomSheetState extends ConsumerState<AddContactBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  int _priority = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        // Fetch full contact details as openExternalPick only returns ID/DisplayName usually
        final fullContact = await FlutterContacts.getContact(contact.id);
        if (fullContact != null && mounted) {
          setState(() {
            _nameController.text = fullContact.displayName;
            if (fullContact.phones.isNotEmpty) {
              // Get the first phone number, removing non-numeric chars except +
              _phoneController.text = fullContact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
            }
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission denied')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(contactsManagerProvider).addContact(
        _nameController.text,
        _phoneController.text,
        _priority,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add contact: $e'), backgroundColor: Colors.redAccent),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Trusted Contact',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  onPressed: _pickContact,
                  icon: const Icon(Icons.contact_page_outlined, color: AppColors.accent),
                  tooltip: 'Pick from phone',
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person, color: Colors.white70),
              ),
              validator: (v) => v!.isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone, color: Colors.white70),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Phone required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text('Priority Level', style: TextStyle(color: Colors.white70)),
                ),
                DropdownButton<int>(
                  value: _priority,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Priority 1 (SMS First)')),
                    DropdownMenuItem(value: 2, child: Text('Priority 2 (Backup)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _priority = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
