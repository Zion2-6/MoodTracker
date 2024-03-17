import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'user.dart'; // Your user model class
//import 'dart:io';
//import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart'; // Used for accessing the file system

class DatabaseHelper {
  static Future<Database> getDatabase() async {
    final databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, 'your_database.db');
    //print("Database path: $path");

    // Open/create the database at the path
    return openDatabase(path, version: 1, onCreate: (db, version) async {
      // Create the 'users' table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          username TEXT PRIMARY KEY,
          password TEXT
        );
      ''');
    });
  }

  static Future<String> getDatabasesPath() async {
    final directory = await getApplicationDocumentsDirectory(); // This works for both mobile and desktop
    return directory.path;
  }

  static Future<void> insertUser(User user) async {
    final Database db = await getDatabase();
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<User?> getUserByUsername(String username) async {
    final Database db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      // Assuming the password is stored in a hashed format
      return User(username: maps[0]['username'], password: maps[0]['password']);
    }
    return null; // User not found
  }
}