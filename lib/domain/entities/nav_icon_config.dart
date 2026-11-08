import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class NavIconConfig {
  const NavIconConfig({this.paths = const <String, String>{}});

  static const List<String> routes = <String>[
    '/home',
    '/calendar',
    '/countdown',
    '/ai',
    '/settings',
  ];

  final Map<String, String> paths;

  String? pathFor(String route) {
    final value = paths[route]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  NavIconConfig withPath(String route, String? path) {
    if (!routes.contains(route)) return this;
    final next = Map<String, String>.from(paths);
    final value = path?.trim();
    if (value == null || value.isEmpty) {
      next.remove(route);
    } else {
      next[route] = value;
    }
    return NavIconConfig(paths: Map<String, String>.unmodifiable(next));
  }

  String toJson() => jsonEncode(paths);

  factory NavIconConfig.fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return const NavIconConfig();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const NavIconConfig();
      final paths = <String, String>{};
      for (final route in routes) {
        final value = decoded[route];
        if (value is String && value.trim().isNotEmpty) {
          paths[route] = value.trim();
        }
      }
      return NavIconConfig(paths: Map<String, String>.unmodifiable(paths));
    } on FormatException {
      return const NavIconConfig();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NavIconConfig || other.paths.length != paths.length) {
      return false;
    }
    for (final entry in paths.entries) {
      if (other.paths[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
        routes.map((String route) => Object.hash(route, paths[route])),
      );
}
