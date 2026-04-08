import 'package:angle_mvp/core/providers/supabase_provider.dart';
import 'package:angle_mvp/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stream of user contacts ordered by priority
final contactsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(authSessionProvider).value;

  if (session == null) {
    yield [];
    return;
  }

  yield* client
      .from('contacts')
      .stream(primaryKey: ['id'])
      .eq('user_id', session.user.id)
      .order('priority', ascending: true);
});

// A provider returning a simple interface to manage contacts
final contactsManagerProvider = Provider<ContactsManager>((ref) {
  return ContactsManager(ref);
});

class ContactsManager {
  final Ref ref;

  ContactsManager(this.ref);

  Future<void> addContact(String name, String phone, int priority) async {
    final client = ref.read(supabaseClientProvider);
    final session = ref.read(authSessionProvider).value;
    
    if (session == null) throw Exception('No user found');

    await client.from('contacts').insert({
      'user_id': session.user.id,
      'name': name,
      'phone': phone,
      'priority': priority,
    });
    
    ref.invalidate(contactsProvider);
  }

  Future<void> deleteContact(String contactId) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('contacts').delete().eq('id', contactId);
    ref.invalidate(contactsProvider);
  }
}
