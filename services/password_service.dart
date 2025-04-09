import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/password_item.dart';

class PasswordService {
  static const String _storageKey = 'password_items';
  static const String _masterPasswordKey = 'master_password_hash';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Initialize with a master password
  Future<void> initializeMasterPassword(String masterPassword) async {
    final String hashedPassword = _hashPassword(masterPassword);
    await _secureStorage.write(key: _masterPasswordKey, value: hashedPassword);
  }

  // Verify master password
  Future<bool> verifyMasterPassword(String masterPassword) async {
    final String? storedHash = await _secureStorage.read(key: _masterPasswordKey);
    if (storedHash == null) return false;
    
    final String inputHash = _hashPassword(masterPassword);
    return storedHash == inputHash;
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Get all password items
  Future<List<PasswordItem>> getAllItems() async {
    final String? jsonString = await _secureStorage.read(key: _storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    return PasswordItem.fromJsonList(jsonString);
  }

  // Save all password items
  Future<void> saveAllItems(List<PasswordItem> items) async {
    final String jsonString = PasswordItem.toJsonList(items);
    await _secureStorage.write(key: _storageKey, value: jsonString);
  }

  // Add a new password item
  Future<void> addItem(PasswordItem item) async {
    final List<PasswordItem> items = await getAllItems();
    items.add(item);
    await saveAllItems(items);
  }

  // Update an existing password item
  Future<void> updateItem(PasswordItem updatedItem) async {
    final List<PasswordItem> items = await getAllItems();
    final int index = items.indexWhere((item) => item.id == updatedItem.id);
    
    if (index != -1) {
      items[index] = updatedItem;
      await saveAllItems(items);
    }
  }

  // Delete a password item
  Future<void> deleteItem(String id) async {
    final List<PasswordItem> items = await getAllItems();
    items.removeWhere((item) => item.id == id);
    await saveAllItems(items);
  }

  // Generate a secure password
  String generatePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSpecial = true,
  }) {
    const String uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
    const String numberChars = '0123456789';
    const String specialChars = '!@#\$%^&*()-_=+[]{}|;:,.<>?/';

    String chars = '';
    if (includeUppercase) chars += uppercaseChars;
    if (includeLowercase) chars += lowercaseChars;
    if (includeNumbers) chars += numberChars;
    if (includeSpecial) chars += specialChars;

    if (chars.isEmpty) {
      chars = lowercaseChars + numberChars;
    }

    return List.generate(length, (index) {
      final randomIndex = (DateTime.now().microsecondsSinceEpoch + index) % chars.length;
      return chars[randomIndex];
    }).join('');
  }

  // Check password strength (returns a score from 0-4)
  int checkPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    if (password.length < 8) return 1;

    int score = 0;
    
    // Length check
    if (password.length >= 12) {
      score += 1;
    }
    
    // Character variety checks
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score += 1;
    
    // Cap at 4
    return score > 4 ? 4 : score;
  }

  // Export passwords as JSON
  Future<String> exportPasswords() async {
    final items = await getAllItems();
    return PasswordItem.toJsonList(items);
  }

  // Import passwords from JSON
  Future<bool> importPasswords(String jsonString) async {
    try {
      final List<PasswordItem> items = PasswordItem.fromJsonList(jsonString);
      await saveAllItems(items);
      return true;
    } catch (e) {
      return false;
    }
  }
}
