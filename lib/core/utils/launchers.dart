// import 'package:url_launcher/url_launcher.dart';
//
// class Launchers {
//   static Future<void> call(String phone) async {
//     final uri = Uri(scheme: 'tel', path: phone);
//     if (await canLaunchUrl(uri)) await launchUrl(uri);
//   }
//
//   static Future<void> whatsapp(String phone, {String? message}) async {
//     final uri = Uri.parse(
//         'https://wa.me/$phone${message != null ? '?text=${Uri.encodeComponent(message)}' : ''}');
//     if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
//   }
//
//   static Future<void> map(double lat, double lng) async {
//     final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
//     if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
//   }
// }


import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class Launchers {
  static Future<void> call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    // Web: tel: only triggers on mobile browsers.
    // Native: use externalApplication so the dialer opens as an app.
    try {
      await launchUrl(
        uri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  static Future<void> whatsapp(String phone, {String? message}) async {
    final text =
    message != null ? '?text=${Uri.encodeComponent(message)}' : '';

    // ── WEB ──
    // Browsers can't resolve the `whatsapp://` custom scheme, so
    // skip straight to the wa.me universal link. It opens WhatsApp
    // Web (or the installed desktop/mobile app if available).
    if (kIsWeb) {
      final webUri = Uri.parse('https://wa.me/$phone$text');
      try {
        await launchUrl(webUri);
      } catch (_) {}
      return;
    }

    // ── NATIVE (Android / iOS) ──
    // 1. Try the native scheme first (opens the WhatsApp app).
    final appUri = Uri.parse(
      'whatsapp://send?phone=$phone'
          '${message != null ? '&text=${Uri.encodeComponent(message)}' : ''}',
    );
    try {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return;
    } catch (_) {}

    // 2. Fall back to the wa.me universal link.
    final webUri = Uri.parse('https://wa.me/$phone$text');
    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(webUri);
      } catch (_) {}
    }
  }

  static Future<void> map(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      await launchUrl(
        uri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }
}