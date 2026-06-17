import 'dart:convert';

import 'package:flutter/material.dart';

/// Fasilitas kamar — selaras backend [kamar_helper.js] FASILITAS_VALID.
class KamarFasilitas {
  KamarFasilitas._();

  static const ac = 'AC';
  static const wifi = 'WiFi';
  static const lemari = 'Lemari';
  static const kamarMandi = 'Kamar Mandi';

  static const List<String> validValues = [ac, wifi, lemari, kamarMandi];

  static const List<({String value, String label, IconData icon})> options = [
    (value: ac, label: 'AC', icon: Icons.ac_unit_outlined),
    (value: wifi, label: 'WiFi', icon: Icons.wifi_outlined),
    (value: lemari, label: 'Lemari', icon: Icons.inventory_2_outlined),
    (value: kamarMandi, label: 'Kamar Mandi', icon: Icons.bathtub_outlined),
  ];

  static List<String> parse(dynamic raw) {
    if (raw == null) return const [];

    Iterable<dynamic> source;
    if (raw is List) {
      source = raw;
    } else if (raw is String) {
      final text = raw.trim();
      if (text.isEmpty || text == 'null') return const [];
      try {
        final decoded = jsonDecode(text);
        if (decoded is! List) return const [];
        source = decoded;
      } catch (_) {
        return const [];
      }
    } else {
      return const [];
    }

    final out = <String>[];
    for (final item in source) {
      final label = '$item'.trim();
      if (label.isEmpty || label == 'null') continue;
      if (!validValues.contains(label)) continue;
      if (!out.contains(label)) out.add(label);
    }
    return out;
  }

  static List<String> toPayload(Set<String> selected) {
    return validValues.where(selected.contains).toList();
  }

  static bool contains(dynamic raw, String value) {
    return parse(raw).contains(value);
  }

  static IconData iconFor(String value) {
    for (final o in options) {
      if (o.value == value) return o.icon;
    }
    return Icons.check_circle_outline;
  }

  static String labelFor(String value) {
    for (final o in options) {
      if (o.value == value) return o.label;
    }
    return value;
  }
}
