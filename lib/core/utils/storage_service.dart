import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;

  // Initialize the shared preferences instance
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Get a boolean value
  static bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  // Set a boolean value
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  // Get a string value
  static String getString(String key, {String defaultValue = ''}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  // Set a string value
  static Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  // Get an integer value
  static int getInt(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  // Set an integer value
  static Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  // Get a double value
  static double getDouble(String key, {double defaultValue = 0.0}) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  // Set a double value
  static Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  // Get a list of strings
  static List<String> getStringList(String key, {List<String> defaultValue = const []}) {
    return _prefs.getStringList(key) ?? defaultValue;
  }

  // Set a list of strings
  static Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  // Store an object by converting to JSON
  static Future<bool> setObject(String key, dynamic value) async {
    return await _prefs.setString(key, json.encode(value));
  }

  // Get an object by converting from JSON
  static dynamic getObject(String key) {
    String? jsonString = _prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    return json.decode(jsonString);
  }

  // Remove a value
  static Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  // Clear all values
  static Future<bool> clear() async {
    return await _prefs.clear();
  }

  // Check if a key exists
  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
} 