import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'homepage.dart'; // Import HomePage

class EntryEditScreen extends StatefulWidget {
  final JournalEntryModel? entry;
  final List<JournalEntryModel> entries;

  EntryEditScreen({this.entry, required this.entries});

  @override
  _EntryEditScreenState createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends State<EntryEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  Color _textColor = Colors.black;
  Color _backgroundColor = Colors.white;
  File? _image;

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
                    _updateAppBarColors();
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
                    _updateAppBarColors();
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

  AppBar _appBar = AppBar();

  void _updateAppBarColors() {
    setState(() {
      _appBar = AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        title: Text(widget.entry != null ? 'Edit Entry' : 'New Entry'),
      );
    });
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
        Navigator.pop(context);
        return true;
      },
      child: Scaffold(
        appBar: _appBar,
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
                  _getImage();
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
    final newEntry = JournalEntryModel(
      title: _titleController.text,
      content: _contentController.text,
      date: DateTime.now().toString(),
      image: _image,
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
