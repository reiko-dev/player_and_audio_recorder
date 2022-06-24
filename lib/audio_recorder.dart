import 'dart:async';

import 'package:audio_recorder/audio_button.dart';
import 'package:audio_recorder/color_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

class AudioRecorder extends StatefulWidget {
  final void Function(String? path) onStop;

  const AudioRecorder({
    Key? key,
    required this.onStop,
  }) : super(key: key);

  @override
  AudioRecorderState createState() => AudioRecorderState();
}

const textWeight = FontWeight.w300;

class AudioRecorderState extends State<AudioRecorder> {
  bool _isRecording = false;
  bool _isPaused = false;
  final _recordDuration = ValueNotifier<int>(0);
  Timer? _timer;
  final _audioRecorder = Record();

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return MaterialApp(
      home: Scaffold(
        body: SizedBox.fromSize(
          size: size,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Spacer(flex: 2),
              SizedBox(
                width: size.width,
                height: 250,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //Text timer
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ValueListenableBuilder<int>(
                        valueListenable: _recordDuration,
                        builder: (context, secs, _) {
                          final String hours = _formatNumber(secs ~/ 3600);
                          final String minutes = _formatNumber(secs ~/ 60);
                          final String seconds = _formatNumber(secs % 60);

                          return Text(
                            '$hours:$minutes :$seconds',
                            style: const TextStyle(
                              fontSize: 38,
                              color: troveAccent,
                              fontWeight: textWeight,
                            ),
                          );
                        },
                      ),
                    ),

                    //Big Mic
                    AudioButton(
                      buttonSize: 160,
                      fillColor: troveAccent.withOpacity(_isPaused ? 0.4 : 1.0),
                      onTap: _isRecording ? null : _record,
                      icon: CupertinoIcons.mic,
                      iconColor: Colors.white,
                      iconSize: 55,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              //Controll Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  //Record/Play/Resume buttons
                  AudioButton(
                    onTap: () {
                      if (_isPaused) {
                        _resume();
                      } else {
                        _isRecording ? _pause() : _record();
                      }
                    },
                    iconSize: _isRecording ? 36 : 26,
                    icon: _isRecording
                        ? _isPaused
                            ? CupertinoIcons.play_arrow_solid
                            : CupertinoIcons.pause_solid
                        : CupertinoIcons.circle_fill,
                    iconColor: _isRecording ? trovePrimary : troveAccent,
                    borderColor: _isRecording ? trovePrimary : troveAccent,
                    alignment: _isPaused && _isRecording
                        ? const Alignment(.2, 0)
                        : null,
                    label: _isRecording
                        ? _isPaused
                            ? "resume"
                            : "pause"
                        : "record",
                    labelColor: _isRecording ? trovePrimary : troveAccent,
                  ),

                  //Stop Button
                  AudioButton(
                    icon: CupertinoIcons.stop_fill,
                    iconColor: Colors.white,
                    iconSize: 30,
                    fillColor: trovePrimary,
                    onTap: _isRecording ? _stop : null,
                    label: _isRecording ? "done" : "",
                    labelColor: trovePrimary,
                  ),
                ],
              ),

              const Spacer(),

              //Exit button
              AudioButton(
                buttonSize: 42,
                icon: CupertinoIcons.clear,
                iconSize: 24,
                iconColor: trovePrimary,
                borderColor: trovePrimary,
                onTap: _stop,
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  Future<void> _record() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // We don't do anything with this but printing
        final isSupported = await _audioRecorder.isEncoderSupported(
          AudioEncoder.aacLc,
        );
        if (kDebugMode) {
          print('${AudioEncoder.aacLc.name} supported: $isSupported');
        }

        await _audioRecorder.start();

        bool isRecording = await _audioRecorder.isRecording();

        setState(() {
          _isRecording = isRecording;
          _recordDuration.value = 0;
        });

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _stop() async {
    if (!_isRecording) return;

    print("Getting out");

    _timer?.cancel();
    final path = await _audioRecorder.stop();

    setState(() => _isRecording = false);

    widget.onStop(path);
  }

  Future<void> _pause() async {
    _timer?.cancel();
    await _audioRecorder.pause();

    setState(() => _isPaused = true);
  }

  Future<void> _resume() async {
    _startTimer();
    await _audioRecorder.resume();

    setState(() => _isPaused = false);
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration.value++);
    });
  }
}
