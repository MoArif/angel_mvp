import 'package:angle_mvp/core/theme/app_theme.dart';
import 'package:angle_mvp/core/widgets/glass_card.dart';
import 'package:angle_mvp/features/contacts/providers/contacts_provider.dart';
import 'package:angle_mvp/features/contacts/widgets/add_contact_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  void _showAddContact(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddContactBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Trusted Contacts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: contactsAsync.when(
            data: (contacts) {
              if (contacts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      const Text(
                        'No contacts yet.',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddContact(context),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ).animate().scale(delay: 200.ms),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: AppColors.accent),
                        ),
                        title: Text(
                          contact['name'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          contact['phone'] + ' • Priority ${contact['priority']}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.surface,
                                title: const Text('Delete Contact?', style: TextStyle(color: Colors.white)),
                                content: const Text('Are you sure you want to remove this contact?', style: TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await ref.read(contactsManagerProvider).deleteContact(contact['id']);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              }
                            }
                          },
                        ),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: index * 100)).slideX(begin: 0.1),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
          ),
        ),
      ),
      floatingActionButton: contactsAsync.maybeWhen(
        data: (contacts) => contacts.isNotEmpty
            ? FloatingActionButton(
                onPressed: () => _showAddContact(context),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}
