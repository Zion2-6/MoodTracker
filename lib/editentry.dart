//import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'journal_entry_model.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class EntryEditScreen extends StatefulWidget {
  final JournalEntryModel? entry;
  final List<JournalEntryModel> entries;

  EntryEditScreen({this.entry, required this.entries});

  @override
  _EntryEditScreenState createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends State<EntryEditScreen> {
  List<String> moods = ['Relaxed','Happy', 'Neutral', 'Sad', 'Stressed'];
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  File? _image;
  late Color _backgroundColor;
  String? _currentMood;

  @override
void initState() {
  super.initState();
  // Initialize text controllers
  _titleController = TextEditingController(text: widget.entry?.title ?? '');
  _contentController = TextEditingController(text: widget.entry?.content ?? '');
  
  // Initialize image and background color if an entry is provided
  if (widget.entry != null) {
    _image = widget.entry!.imageFile; // Initialize the image from the entry
    _backgroundColor = widget.entry!.getBackgroundColor().withAlpha(255); // Initialize background color from the entry
    _currentMood = widget.entry!.mood;
    //print("Saving color: ${_backgroundColor.value.toRadixString(16)}");
// and
    //print("Loaded color: ${widget.entry!.getBackgroundColor()}");
  } else {
    // Defaults if creating a new entry
    
    _image = null; // No image by default
    _backgroundColor = Color.fromARGB(255, 255, 255, 255); // Default background color
    _currentMood = 'neutral';
  }
}
  void _showMoodPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select a mood'),
          children: moods.map((String mood) {
            return SimpleDialogOption(
              onPressed: () {
                // Update the mood of the entry and pop the dialog
                setState(() {
                  _currentMood = mood;
                });
                Navigator.pop(context);
              },
              child: Text(mood),
            );
          }).toList(),
        );
      },
    );
  }
  void changeBackgroundColor(Color color) {
    setState(() {
        _backgroundColor = color.withAlpha(255);
        // Convert the Color to a hex string (without alpha)
        String colorStr = '0x${color.value.toRadixString(16).substring(2)}'; // Convert to a hex string
        widget.entry?.backgroundColor = colorStr;
        //print("Saving color: $colorStr");
    });
}
  
  void _showColorPickerDialog() {
    // Show color picker dialog
    showDialog(
        context: context,
        builder: (BuildContext context) {
            return AlertDialog(
                title: const Text('Select a background color'),
                content: SingleChildScrollView(
                    child: ColorPicker(
                        pickerColor: _backgroundColor.withAlpha(255),
                        onColorChanged: changeBackgroundColor,
                        showLabel: true,
                        pickerAreaHeightPercent: 0.8,
                        enableAlpha: false,
                    ),
                ),
                actions: <Widget>[
                    ElevatedButton(
                        child: const Text('Done'),
                        onPressed: () {
                            Navigator.of(context).pop(); // Dismiss the dialog
                        },
                    ),
                ],
            );
        },
    );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Entry' : 'Edit Entry'),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: _backgroundColor, // Set the background color
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _contentController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(labelText: 'Content'),
            ),
            SizedBox(height: 8.0),
            if (_image != null)
              Image.file(
                _image!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _getImage,
              child: Text('Add Image'),
            ),
            SizedBox(height: 8.0),
            ElevatedButton(
                onPressed: _showColorPickerDialog,
                child: Text('Customize Background Color'),
            ),
            SizedBox(height: 8.0),
            ElevatedButton(
            onPressed: _showMoodPicker,
            child: Text('Add Mood'),
          ),
          if (widget.entry != null && widget.entry!.mood != null)
            SizedBox(height: 8.0), 
            Text('Mood: ${_currentMood ?? widget.entry!.mood ?? 'No mood selected'}'),
          SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _saveEntry,
              child: Text('Save'),
            ),
            
          ],
        ),
      ),
      ),
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

  void _saveEntry() async {
    final newEntry = JournalEntryModel(
      title: _titleController.text,
      content: _contentController.text,
      date: DateTime.now().toString(),
      imagePath: _image?.path,
      backgroundColor: '0x${_backgroundColor.value.toRadixString(16).substring(2)}', // Store color as string
      mood: _currentMood,

    );
    if (widget.entry != null) {
      // Edit mode
      newEntry.mood = _currentMood;
      widget.entries[widget.entries.indexOf(widget.entry!)] = newEntry;
    } else {
      // Add new entry
      widget.entries.add(newEntry);
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> entriesJson = widget.entries.map((entry) => entry.toJson()).toList();
    await prefs.setStringList('entries', entriesJson);
    Navigator.pop(context);
  }
}