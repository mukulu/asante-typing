import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A simple service for persisting and retrieving custom typing lessons.
///
/// The custom lesson data is stored as a JSON‑encoded list of maps in
/// [SharedPreferences]. Each entry in the list contains a `title` and
/// `content`. Clients of this service can load and save the list as
/// necessary. Data is persisted across app launches.
class CustomLessonsService {
  /// The key used to store custom lessons in [SharedPreferences].
  static const String _storageKey = 'custom_lessons';

  /// Loads the list of custom lessons from storage.
  ///
  /// Returns an empty list if no custom lessons have been saved yet. The
  /// returned list contains maps with two string keys: `title` and
  /// `content`. Order is preserved.
  static Future<List<Map<String, String>>> loadLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return <Map<String, String>>[];
    }
    try {
      final decoded = json.decode(jsonString);
      if (decoded is List<dynamic>) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map<Map<String, String>>((e) => {
                  'title': e['title']?.toString() ?? '',
                  'content': e['content']?.toString() ?? '',
                })
            .toList();
      }

    } on FormatException {
      // Corrupt JSON -> return empty list.
    } on Exception {
      // Unexpected structure -> return empty list.
    }
    return <Map<String, String>>[];
  }

  /// Persists the provided list of custom lessons to storage.
  ///
  /// The list should contain maps with two string keys: `title` and
  /// `content`. Only minimal validation is performed here; callers should
  /// ensure that values are non‑null strings. When saved, the previous
  /// contents under the storage key are completely overwritten.
  static Future<void> saveLessons(List<Map<String, String>> lessons) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(lessons);
    await prefs.setString(_storageKey, encoded);
  }
}
