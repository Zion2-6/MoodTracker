import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'editentry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(HomePage());
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Journal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: JournalEntryScreen(),
    );
  }
}

class JournalEntryScreen extends StatefulWidget {
  @override
  _JournalEntryScreenState createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  List<JournalEntryModel> entries = [];
  List<JournalEntryModel> originalEntries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? entriesJson = prefs.getStringList('entries');
    if (entriesJson != null) {
      setState(() {
        entries = entriesJson
            .map((json) => JournalEntryModel.fromJson(json))
            .toList();
        originalEntries = List.from(entries); // Make a copy for filtering
      });
    }
  }

  Future<void> _searchEntries(String query) async {
    if (query.isEmpty) {
      // Show all entries if query is empty
      setState(() {
        entries = List.from(originalEntries);
      });
    } else {
      List<JournalEntryModel> matchedEntries = [];
      originalEntries.forEach((entry) {
        if (entry.title.toLowerCase().contains(query.toLowerCase())) {
          matchedEntries.add(entry);
        }
      });
      setState(() {
        entries = matchedEntries;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Entries'),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Search Entries'),
                    content: TextField(
                      onChanged: (value) {
                        _searchEntries(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter search query',
                      ),
                    ),
                  );
                },
              );
            },
            icon: Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              // Implement mood tracker functionality
            },
            icon: Icon(Icons.mood),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(entries[index].title),
            subtitle: Text(entries[index].date),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EntryEditScreen(
                    entry: entries[index],
                    entries: entries,
                  ),
                ),
              ).then((_) {
                _loadEntries();
              });
            },
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _deleteEntry(index);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EntryEditScreen(entries: entries),
            ),
          ).then((_) {
            _loadEntries();
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _deleteEntry(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      entries.removeAt(index);
    });
    List<String> entriesJson = entries.map((entry) => entry.toJson()).toList();
    prefs.setStringList('entries', entriesJson);
  }
}

class JournalEntryModel {
  final String title;
  final String content;
  final String date;
  final File? image;

  JournalEntryModel({
    required this.title,
    required this.content,
    required this.date,
    this.image,
  });

  factory JournalEntryModel.fromJson(String json) {
    Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(json));
    return JournalEntryModel(
      title: map['title'],
      content: map['content'],
      date: map['date'],
      image: map['image'] != null ? File(map['image']) : null,
    );
  }

  String toJson() {
    return jsonEncode({
      'title': title,
      'content': content,
      'date': date,
      'image': image?.path,
    });
  }
}
