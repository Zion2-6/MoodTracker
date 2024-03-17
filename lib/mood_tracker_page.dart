import 'package:flutter/material.dart';
import 'journal_entry_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoodTrackerPage extends StatefulWidget {
  @override
  _MoodTrackerPageState createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage> {
  late List<JournalEntryModel> entries;
  late DateTime selectedDate;
  late String overallMood;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    loadEntries().then((loadedEntries) {
      setState(() {
        entries = loadedEntries;
        overallMood = calculateOverallMood(selectedDate);
      });
    });
  }

  Future<List<JournalEntryModel>> loadEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? entriesJson = prefs.getStringList('entries');
    if (entriesJson != null) {
      return entriesJson.map((json) => JournalEntryModel.fromJson(json)).toList();
    }
    return [];
  }

  String calculateOverallMood(DateTime date) {
    // Filter entries for the given date, ignoring time
    List<JournalEntryModel> entriesForDate = entries.where((entry) {
        String entryDate = entry.date.substring(0, 10); // Extract the date part of the entry's timestamp
        return entryDate == date.toString().substring(0, 10);
    }).toList();

    // Filter out neutral moods and handle nullable mood values
    List<String> nonNeutralMoods = entriesForDate
        .where((entry) => entry.mood != null && entry.mood != 'Neutral')
        .map((entry) => entry.mood!)
        .toList();

    // Define a map to store the numerical values for each mood
    Map<String, int> moodScores = {
        'Relaxed': 2,
        'Happy': 1,
        'Sad': -1,
        'Stressed': -2,
    };

    // Calculate the average score for all non-neutral moods
    double averageScore = nonNeutralMoods.fold(0.0, (sum, mood) => sum + (moodScores[mood] ?? 0)) / (nonNeutralMoods.isNotEmpty ? nonNeutralMoods.length : 1);

    // Determine the overall mood based on the average score
    String overallMood;
    if (averageScore <= 2 && averageScore > 1.5) {
        overallMood = 'Relaxed';
    } else if (averageScore <= 1.5 && averageScore > 0.5) {
        overallMood = 'Happy';
    } else if (averageScore <= 0.5 && averageScore >= -0.5) {
        overallMood = 'Neutral';
    } else if (averageScore < -0.5 && averageScore >= -1.5) {
        overallMood = 'Sad';
    } else if (averageScore < -1.5 && averageScore >= -2) {
        overallMood = 'Stressed';
    } else {
        overallMood = 'Neutral'; // Default case, could also be an error state
    }

    return overallMood;
}

  @override
Widget build(BuildContext context) {
  // Check if entries are loaded
  if (entries == null) {
    return Center(child: CircularProgressIndicator()); // Show loading spinner until entries are loaded
  } else {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mood Tracker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Overall Mood for ${selectedDate.toString().substring(0, 10)}:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              overallMood,
              style: TextStyle(fontSize: 20, color: Colors.blue),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Show date picker to select a date
                showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                ).then((pickedDate) {
                  if (pickedDate != null && pickedDate != selectedDate) {
                    setState(() {
                      selectedDate = pickedDate;
                      overallMood = calculateOverallMood(selectedDate);
                    });
                  }
                });
              },
              child: Text('Select Date'),
            ),
          ],
        ),
      ),
    );
  }
}
}
