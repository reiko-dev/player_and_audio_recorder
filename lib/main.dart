import 'package:audio_recorder/audio_player.dart';
import 'package:audio_recorder/audio_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String? audioPath;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: audioPath != null
              ? AudioPlayer(
                  source: audioPath!,
                  onDelete: () {
                    setState(() => audioPath = null);
                  },
                )
              : AudioRecorder(
                  onStop: (path) {
                    if (kDebugMode) print('Recorded file path: $path');
                    setState(() {
                      audioPath = path;
                    });
                  },
                ),
        ),
      ),
    );
  }
}
