import 'package:url_launcher/url_launcher.dart';

class WhatsAppDeepLinkService {
  const WhatsAppDeepLinkService._();

  static String normalizePhone(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty || digits == 'null') return '';

    var phone = digits;
    if (phone.startsWith('+')) phone = phone.substring(1);
    if (phone.startsWith('0')) phone = '62${phone.substring(1)}';

    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static Uri? chatUri({required String? phoneNumber, String? message}) {
    final phone = normalizePhone(phoneNumber);
    if (phone.isEmpty) return null;

    return Uri.https('wa.me', '/$phone', {
      if ((message ?? '').trim().isNotEmpty) 'text': message!.trim(),
    });
  }

  static Future<bool> openChat({
    required String? phoneNumber,
    String? message,
  }) async {
    final uri = chatUri(phoneNumber: phoneNumber, message: message);
    if (uri == null) return false;

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static String tenantGreeting(String? nama) {
    final cleanName = (nama ?? '').trim();
    if (cleanName.isEmpty || cleanName == 'null') return 'Halo';
    return 'Halo $cleanName';
  }
}
