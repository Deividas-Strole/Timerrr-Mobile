import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
  // Method channel for native code
  static const platform = MethodChannel('com.example.timer/stopwatch');

  Timer? _displayTimer;
  int _elapsedMilliseconds = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Keep the screen on
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_displayTimer != null && _displayTimer!.isActive) {
      _displayTimer!.cancel();
    }
    WakelockPlus.disable();
    _stopNativeStopwatch();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isRunning) {
        // Update the elapsed time from native code
        _updateElapsedTimeFromNative();
        // Restart the display timer
        _startDisplayTimer();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Just stop the display timer but let the native stopwatch run
      if (_displayTimer != null && _displayTimer!.isActive) {
        _displayTimer!.cancel();
      }
    }
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
    // Start a native stopwatch implementation
    await _startNativeStopwatch();

    // Start a timer for display updates only
    _startDisplayTimer();

    setState(() {
      _isRunning = true;
    });
  }

  void _stopTimer() async {
    // Stop native stopwatch
    await _stopNativeStopwatch();

    // Stop the display timer
    if (_displayTimer != null && _displayTimer!.isActive) {
      _displayTimer!.cancel();
    }

    // Get the final time
    await _updateElapsedTimeFromNative();

    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() async {
    // Reset native stopwatch
    await _resetNativeStopwatch();

    // Stop the display timer
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _startTimer,
                  child: Text('Start'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isRunning ? _stopTimer : null,
                  child: Text('Stop'),
                ),
                SizedBox(width: 10),
                ElevatedButton(onPressed: _resetTimer, child: Text('Reset')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
