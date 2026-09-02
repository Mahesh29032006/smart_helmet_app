import 'package:telephony/telephony.dart';
import '../providers/contacts_provider.dart';
import '../models/location_data.dart';
import '../models/sensor_data.dart';

class EmergencySmsService {
  final Telephony telephony = Telephony.instance;
  final Set<String> _processedEmergencyIds = {};

  Future<void> sendEmergencySms({
    required String emergencyId,
    required ContactsState contactsState,
    required LocationData? location,
    required SensorData? telemetry,
  }) async {
    if (_processedEmergencyIds.contains(emergencyId)) {
      print('SMS already sent for emergency $emergencyId. Skipping.');
      return;
    }
    _processedEmergencyIds.add(emergencyId);

    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != true) {
      print('SMS permission denied. Cannot send emergency SMS.');
      return;
    }

    String message = contactsState.messageTemplate;
    
    // Replace placeholders
    final locStr = location != null ? 'https://maps.google.com/?q=${location.latitude},${location.longitude}' : 'Unknown';
    final lat = location?.latitude.toStringAsFixed(4) ?? 'N/A';
    final lng = location?.longitude.toStringAsFixed(4) ?? 'N/A';
    final speed = (location != null ? location.speed * 3.6 : 0.0).toStringAsFixed(1) ?? '0.0';
    final alt = location?.altitude.toStringAsFixed(1) ?? 'N/A';
    final sats = 'N/A';

    message = message.replaceAll('{LOCATION}', locStr);
    message = message.replaceAll('{LATITUDE}', lat);
    message = message.replaceAll('{LONGITUDE}', lng);
    message = message.replaceAll('{SPEED}', speed);
    message = message.replaceAll('{ALTITUDE}', alt);
    message = message.replaceAll('{SATELLITES}', sats);
    // Replace TIME if present
    message = message.replaceAll('{TIME}', DateTime.now().toIso8601String());

    final enabledContacts = contactsState.contacts.where((c) => c.enabled).toList();
    
    for (final contact in enabledContacts) {
      try {
        await telephony.sendSms(
          to: contact.phoneNumber,
          message: message,
        );
        print('Sent SMS to ${contact.phoneNumber}');
      } catch (e) {
        print('Failed to send SMS to ${contact.phoneNumber}: $e');
      }
    }
  }
}

final emergencySmsService = EmergencySmsService();
