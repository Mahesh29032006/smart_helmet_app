import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telephony/telephony.dart';
import '../../../core/providers/contacts_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestSmsPermission();
  }

  Future<void> _requestSmsPermission() async {
    final telephony = Telephony.instance;
    await telephony.requestPhoneAndSmsPermissions;
  }

  void _showContactDialog({EmergencyContact? contact}) {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phoneNumber ?? '');
    bool isEnabled = contact?.enabled ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(contact == null ? 'Add Contact' : 'Edit Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+91...'),
                keyboardType: TextInputType.phone,
              ),
              if (contact != null)
                SwitchListTile(
                  title: const Text('Enabled'),
                  value: isEnabled,
                  onChanged: (val) => setState(() => isEnabled = val),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty && phoneController.text.trim().isNotEmpty) {
                  if (contact == null) {
                    ref.read(contactsProvider.notifier).addContact(nameController.text.trim(), phoneController.text.trim());
                  } else {
                    ref.read(contactsProvider.notifier).updateContact(contact.id, nameController.text.trim(), phoneController.text.trim(), isEnabled);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsProvider);
    _msgController.text = contactsState.messageTemplate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Configuration'),
      ),
      drawer: const AppDrawer(currentRoute: '/contacts'),
      body: Column(
        children: [
          // Backend sync status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Config Version: ${contactsState.version}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${contactsState.contacts.where((c) => c.enabled).length} Enabled', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor)),
              ],
            ),
          ),
          
          // Template Editor
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Emergency Message Template', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _msgController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter template...',
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Placeholders: {LOCATION}, {LATITUDE}, {LONGITUDE}, {SPEED}', style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    ref.read(contactsProvider.notifier).updateMessageTemplate(_msgController.text);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template Synced with Backend!')));
                  },
                  child: const Text('Save & Sync Template'),
                ),
              ],
            ),
          ),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),

          // Contacts List
          Expanded(
            child: contactsState.contacts.isEmpty
                ? const Center(child: Text('No emergency contacts added yet.'))
                : ListView.builder(
                    itemCount: contactsState.contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contactsState.contacts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: contact.enabled ? AppTheme.dangerColor : Colors.grey,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(contact.name, style: TextStyle(fontWeight: FontWeight.bold, color: contact.enabled ? Colors.black : Colors.grey)),
                          subtitle: Text(contact.phoneNumber),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                                onPressed: () => _showContactDialog(contact: contact),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppTheme.dangerColor),
                                onPressed: () => ref.read(contactsProvider.notifier).removeContact(contact.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
