import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'emergency_providers.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final bool enabled;

  EmergencyContact({required this.id, required this.name, required this.phoneNumber, this.enabled = true});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phoneNumber': phoneNumber, 'enabled': enabled};
  factory EmergencyContact.fromJson(Map<String, dynamic> json) => 
      EmergencyContact(
        id: json['id'], 
        name: json['name'], 
        phoneNumber: json['phoneNumber'],
        enabled: json['enabled'] ?? true,
      );
}

class ContactsState {
  final List<EmergencyContact> contacts;
  final String messageTemplate;
  final int version;

  ContactsState({this.contacts = const [], this.messageTemplate = "", this.version = 0});

  ContactsState copyWith({List<EmergencyContact>? contacts, String? messageTemplate, int? version}) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      messageTemplate: messageTemplate ?? this.messageTemplate,
      version: version ?? this.version,
    );
  }
}

class ContactsNotifier extends StateNotifier<ContactsState> {
  final Ref ref;
  ContactsNotifier(this.ref) : super(ContactsState()) {
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    final baseUrl = ref.read(appConfigProvider).apiBaseUrl;
    try {
      final res = await http.get(Uri.parse('$baseUrl/contacts'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final contactsList = (data['contacts'] as List).map((e) => EmergencyContact.fromJson(e)).toList();
        state = state.copyWith(
          contacts: contactsList,
          messageTemplate: data['messageTemplate'],
          version: data['contactsVersion'],
        );
      }
    } catch (e) {
      print('Error fetching contacts: $e');
    }
  }

  Future<void> _syncBackend(List<EmergencyContact> newContacts) async {
    final baseUrl = ref.read(appConfigProvider).apiBaseUrl;
    try {
      await http.post(
        Uri.parse('$baseUrl/contacts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contacts': newContacts.map((c) => c.toJson()).toList()}),
      );
      // Wait for socket to update, or optimistically fetch
      _fetchContacts();
    } catch (e) {
      print('Error syncing contacts: $e');
    }
  }

    void updateMessageTemplate(String template) {
    state = state.copyWith(messageTemplate: template);
    final baseUrl = ref.read(appConfigProvider).apiBaseUrl;
    http.put(
      Uri.parse(baseUrl + '/emergency-message'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'messageTemplate': template}),
    ).then((_) => _fetchContacts());
  }
  
  void addContact(String name, String phone) {
    final newContact = EmergencyContact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phoneNumber: phone,
      enabled: true,
    );
    _syncBackend([...state.contacts, newContact]);
  }

  void updateContact(String id, String name, String phone, bool enabled) {
    final newState = [
      for (final contact in state.contacts)
        if (contact.id == id)
          EmergencyContact(id: id, name: name, phoneNumber: phone, enabled: enabled)
        else
          contact,
    ];
    _syncBackend(newState);
  }

  void removeContact(String id) {
    _syncBackend(state.contacts.where((c) => c.id != id).toList());
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  return ContactsNotifier(ref);
});
