import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class JournalEntryModel {
  final String title;
  final String content;
  final String date;
  final String? imagePath;
  String? backgroundColor;
  String? mood;

  JournalEntryModel({
    required this.title,
    required this.content,
    required this.date,
    this.imagePath,
    this.backgroundColor,
    this.mood
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'date': date,
      'imagePath': imagePath,
      'backgroundColor': backgroundColor,
      'mood': mood,
    };
  }

  factory JournalEntryModel.fromJson(String json) {
    Map<String, dynamic> map = jsonDecode(json);
    return JournalEntryModel(
      title: map['title'],
      content: map['content'],
      date: map['date'],
      imagePath: map['imagePath'],
      backgroundColor: map['backgroundColor'],
      mood: map['mood'],
    );
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  String? getMood() 
  {
    return mood;
  }

  Color getBackgroundColor() {
    // Assuming the color is stored as a hex string, convert it to a Color object
    // Default to white if backgroundColor is null or invalid
    try {
        return Color(int.parse(backgroundColor ?? '0xFFFFFFFF'));
    } catch (e) {
        return Colors.white; // Fallback to white if parsing fails
    }
  }

  // Optional: if you want to get the image file from the imagePath
  File? get imageFile {
    return imagePath != null ? File(imagePath!) : null;
  }
}