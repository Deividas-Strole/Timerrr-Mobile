import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(StopwatchApp());
}

class StopwatchApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stopwatchius',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StopwatchPage(),
    );
  }
}

class StopwatchPage extends StatefulWidget {
  @override
  _StopwatchPageState createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage>
    with WidgetsBindingObserver {
  static const platform = MethodChannel('com.example.timer/stopwatch');
  Timer? _displayTimer;
  int _elapsedMilliseconds = 0;
  bool _isRunning = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notesController.dispose();
    if (_displayTimer != null && _displayTimer!.isActive) {
      _displayTimer!.cancel();
    }
    WakelockPlus.disable();
    _stopNativeStopwatch();
    super.dispose();
  }

  Future<void> _startNativeStopwatch() async {
    try {
      await platform.invokeMethod('startStopwatch');
    } on PlatformException catch (e) {
      print("Failed to start native stopwatch: ${e.message}");
    }
  }

  Future<void> _stopNativeStopwatch() async {
    try {
      await platform.invokeMethod('stopStopwatch');
    } on PlatformException catch (e) {
      print("Failed to stop native stopwatch: ${e.message}");
    }
  }

  Future<void> _resetNativeStopwatch() async {
    try {
      await platform.invokeMethod('resetStopwatch');
    } on PlatformException catch (e) {
      print("Failed to reset native stopwatch: ${e.message}");
    }
  }

  Future<void> _updateElapsedTimeFromNative() async {
    try {
      final int elapsedTime = await platform.invokeMethod('getElapsedTime');
      setState(() {
        _elapsedMilliseconds = elapsedTime;
      });
    } on PlatformException catch (e) {
      print("Failed to get elapsed time: ${e.message}");
    }
  }

  void _startDisplayTimer() {
    _displayTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      _updateElapsedTimeFromNative();
    });
  }

  void _startTimer() async {
    await _startNativeStopwatch();
    _startDisplayTimer();
    setState(() {
      _isRunning = true;
    });
  }

  void _stopTimer() async {
    await _stopNativeStopwatch();
    if (_displayTimer != null && _displayTimer!.isActive) {
      _displayTimer!.cancel();
    }
    await _updateElapsedTimeFromNative();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() async {
    await _resetNativeStopwatch();
    if (_displayTimer != null && _displayTimer!.isActive) {
      _displayTimer!.cancel();
    }
    setState(() {
      _elapsedMilliseconds = 0;
      _isRunning = false;
    });
  }

  String _formatTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();
    int hours = (minutes / 60).truncate();

    String hoursStr = (hours % 60).toString().padLeft(2, '0');
    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    String hundredsStr = (hundreds % 100).toString().padLeft(2, '0');

    return "$hoursStr:$minutesStr:$secondsStr:$hundredsStr";
  }

  Future<void> _saveNote() async {
    if (_notesController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      List<String> notes = prefs.getStringList('notes') ?? [];
      String note = json.encode({
        'time': _formatTime(_elapsedMilliseconds),
        'text': _notesController.text,
        'timestamp': DateTime.now().toIso8601String(),
      });
      notes.add(note);
      await prefs.setStringList('notes', notes);
      _notesController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Note saved successfully')));
    }
  }

  void _navigateToNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotesPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stopwatch')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _formatTime(_elapsedMilliseconds),
              style: TextStyle(fontSize: 48.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(onPressed: _saveNote, child: Text('Save')),
                      ElevatedButton(
                        onPressed: _navigateToNotes,
                        child: Text('Notes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isRunning ? null : _startTimer,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Text('Start'),
                  ),
                  ElevatedButton(
                    onPressed: _isRunning ? _stopTimer : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Text('Stop'),
                  ),
                  ElevatedButton(
                    onPressed: _resetTimer,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Text('Reset'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> notes = [];
  List<bool> selectedNotes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedNotes = prefs.getStringList('notes') ?? [];
    setState(() {
      notes =
          savedNotes
              .map((note) => json.decode(note) as Map<String, dynamic>)
              .toList();
      selectedNotes = List.filled(notes.length, false);
    });
  }

  Future<void> _deleteSelectedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedNotes = prefs.getStringList('notes') ?? [];
    List<String> updatedNotes = [];

    for (int i = 0; i < savedNotes.length; i++) {
      if (!selectedNotes[i]) {
        updatedNotes.add(savedNotes[i]);
      }
    }

    await prefs.setStringList('notes', updatedNotes);
    await _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Saved Notes')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Checkbox(
                    value: selectedNotes[index],
                    onChanged: (value) {
                      setState(() {
                        selectedNotes[index] = value!;
                      });
                    },
                  ),
                  title: Text('${notes[index]['time']}'),
                  subtitle: Text('${notes[index]['text']}'),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _deleteSelectedNotes,
                  child: Text('Delete'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Go Back'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
