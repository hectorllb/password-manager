import 'dart:convert';
import 'package:uuid/uuid.dart';

class PasswordItem {
  final String id;
  final String title;
  final String username;
  final String password;
  final String website;
  final String notes;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  PasswordItem({
    String? id,
    required this.title,
    required this.username,
    required this.password,
    this.website = '',
    this.notes = '',
    this.category = 'General',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isFavorite = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  PasswordItem copyWith({
    String? title,
    String? username,
    String? password,
    String? website,
    String? notes,
    String? category,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return PasswordItem(
      id: id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'website': website,
      'notes': notes,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory PasswordItem.fromJson(Map<String, dynamic> json) {
    return PasswordItem(
      id: json['id'],
      title: json['title'],
      username: json['username'],
      password: json['password'],
      website: json['website'] ?? '',
      notes: json['notes'] ?? '',
      category: json['category'] ?? 'General',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  static List<PasswordItem> fromJsonList(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => PasswordItem.fromJson(json)).toList();
  }

  static String toJsonList(List<PasswordItem> items) {
    final List<Map<String, dynamic>> jsonList = items.map((item) => item.toJson()).toList();
    return json.encode(jsonList);
  }
}
