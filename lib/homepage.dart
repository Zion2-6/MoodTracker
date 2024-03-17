//import 'dart:io';
//import 'dart:convert';
import 'package:flutter/material.dart';
import 'editentry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'journal_entry_model.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'mood_tracker_page.dart';

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
  List<JournalEntryModel> filteredEntries = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }


  Future<void> _deleteEntry(int index) async {
    // Remove the entry from the list
    setState(() {
      entries.removeAt(index);
      // Also update the filtered list if needed
      filteredEntries = List.from(entries);
    });

    // Update the entries in SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> updatedEntriesJson = entries.map((entry) => entry.toJson()).toList();
    await prefs.setStringList('entries', updatedEntriesJson);
}

  Future<void> _loadEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? entriesJson = prefs.getStringList('entries');
    if (entriesJson != null) {
      setState(() {
        entries = entriesJson.map((json) => JournalEntryModel.fromJson(json)).toList();
        // Initialize filteredEntries as well
        filteredEntries = entries;
      });
    }
  }

  void updateSearchQuery(String newQuery) {
  setState(() {
    searchQuery = newQuery;
    if (searchQuery.isNotEmpty) {
      filteredEntries = entries.where((entry) {
        return entry.title.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    } else {
      filteredEntries = List.from(entries); // If search query is empty, show all entries
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: updateSearchQuery,
          decoration: InputDecoration(
            hintText: 'Search entries...',
            icon: Icon(Icons.search),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                // Clear search query
                setState(() {
                  searchQuery = '';
                  filteredEntries = entries;
                });
              },
            ),
        ],
      ),
      body: ListView.builder(
  itemCount: filteredEntries.length,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text(filteredEntries[index].title),
      subtitle: Text(filteredEntries[index].date),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EntryEditScreen(entry: filteredEntries[index], entries: entries),
          ),
        ).then((_) => _loadEntries());
      },
      trailing: IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: () async {
  bool confirmDelete = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this entry?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false), // Dismiss dialog returning false
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true), // Dismiss dialog returning true
          ),
        ],
      );
    },
  ) ?? false; // The dialog returns null if dismissed by backdrop tap

  if (confirmDelete) {
    _deleteEntry(index);
  }
},
      ),
    );
  },
),
  floatingActionButton: SpeedDial(
  icon: Icons.add,
  activeIcon: Icons.remove,
  buttonSize: Size(56.0, 56.0), // it's the FloatingActionButton size
  visible: true,
  closeManually: false,
  curve: Curves.bounceIn,
  overlayColor: Colors.black,
  overlayOpacity: 0.5,
  tooltip: 'Speed Dial',
  heroTag: 'speed-dial-hero-tag',
  backgroundColor: Colors.blue,
  foregroundColor: Colors.white,
  elevation: 8.0,
  shape: CircleBorder(),
  children: [
    SpeedDialChild(
      child: Icon(Icons.add),
      backgroundColor: Colors.red,
      label: 'New Entry',
      labelStyle: TextStyle(fontSize: 18.0),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EntryEditScreen(entry: null, entries: entries)),
      ).then((_) => _loadEntries()),
    ),
    SpeedDialChild(
      child: Icon(Icons.track_changes),
      backgroundColor: Colors.blue,
      label: 'Mood Tracker',
      labelStyle: TextStyle(fontSize: 18.0),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MoodTrackerPage()),
      ),
    ),
  ],
),
      
    );
  }
}
