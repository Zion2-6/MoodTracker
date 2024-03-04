import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';

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
  late List<JournalEntry> entries = [];
  late List<JournalEntry> originalEntries = [];

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
        entries =
            entriesJson.map((json) => JournalEntry.fromJson(json)).toList();
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
      List<JournalEntry> matchedEntries = [];
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

class EntryEditScreen extends StatefulWidget {
  final JournalEntry? entry;
  final List<JournalEntry> entries;

  EntryEditScreen({this.entry, required this.entries});

  @override
  _EntryEditScreenState createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends State<EntryEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  Color _textColor = Colors.black;
  Color _backgroundColor = Colors.white;
  File? _image; // Variable to store selected image

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController =
        TextEditingController(text: widget.entry?.content ?? '');
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Color'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ColorPicker(
                  pickerColor: _textColor,
                  onColorChanged: (color) {
                    setState(() {
                      _textColor = color;
                    });
                  },
                  showLabel: true,
                  pickerAreaHeightPercent: 0.8,
                ),
                ColorPicker(
                  pickerColor: _backgroundColor,
                  onColorChanged: (color) {
                    setState(() {
                      _backgroundColor = color;
                    });
                  },
                  showLabel: true,
                  pickerAreaHeightPercent: 0.8,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back navigation to restore original entries
        Navigator.pop(context);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.entry != null ? 'Edit Entry' : 'New Entry'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _contentController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: 'Content',
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _showColorPicker();
                },
                child: Text('Customize'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _getImage(); // Call method to get image
                },
                child: Text('Add Image'),
              ),
              SizedBox(height: 16.0),
              _image != null
                  ? Image.file(
                      _image!,
                      height: 200,
                    )
                  : SizedBox.shrink(),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _saveEntry();
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveEntry() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final newEntry = JournalEntry(
      title: _titleController.text,
      content: _contentController.text,
      date: DateTime.now().toString(),
      image: _image, // Assign selected image to the entry
    );
    if (widget.entry != null) {
      int index = widget.entries
          .indexWhere((entry) => entry.title == widget.entry!.title);
      widget.entries[index] = newEntry;
    } else {
      widget.entries.add(newEntry);
    }
    List<String> entriesJson =
        widget.entries.map((entry) => entry.toJson()).toList();
    prefs.setStringList('entries', entriesJson);
    Navigator.pop(context);
  }
}

class JournalEntry {
  final String title;
  final String content;
  final String date;
  final File? image; // Add image field to JournalEntry

  JournalEntry({
    required this.title,
    required this.content,
    required this.date,
    this.image,
  });

  factory JournalEntry.fromJson(String json) {
    Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(json));
    return JournalEntry(
      title: map['title'],
      content: map['content'],
      date: map['date'],
      image: map['image'] != null
          ? File(map['image'])
          : null, // Parse image file from JSON
    );
  }

  String toJson() {
    return jsonEncode({
      'title': title,
      'content': content,
      'date': date,
      'image': image?.path, // Save image file path
    });
  }
}
