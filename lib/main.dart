import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
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
  late Timer _timer;
  int _milliseconds = 0;
  bool _isRunning = false;
  DateTime? _lastTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if (_isRunning) {
      _timer.cancel();
      WakelockPlus.disable();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isRunning) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        // App is going to background
        _timer.cancel();
        _lastTime = DateTime.now();
      } else if (state == AppLifecycleState.resumed && _lastTime != null) {
        // App is coming back to foreground
        final now = DateTime.now();
        final difference = now.difference(_lastTime!).inMilliseconds;
        _milliseconds += difference;
        _startTimer();
      }
    }
  }

  void _startTimer() {
    if (!_isRunning) {
      // Keep the screen on while timer is running
      WakelockPlus.enable();

      _timer = Timer.periodic(Duration(milliseconds: 10), (timer) {
        setState(() {
          _milliseconds += 10;
        });
      });

      setState(() {
        _isRunning = true;
        _lastTime = null;
      });
    }
  }

  void _stopTimer() {
    if (_isRunning) {
      _timer.cancel();
      WakelockPlus.disable();
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _resetTimer() {
    _timer.cancel();
    WakelockPlus.disable();
    setState(() {
      _milliseconds = 0;
      _isRunning = false;
      _lastTime = null;
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
              _formatTime(_milliseconds),
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
