import 'dart:async';

import 'package:audio_recorder/audio_button.dart';
import 'package:audio_recorder/color_theme.dart';
import 'package:audio_recorder/seek_bar.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AudioPlayer extends StatefulWidget {
  /// Path from where to play recorded audio
  final String source;

  final VoidCallback onDelete;

  const AudioPlayer({
    Key? key,
    required this.source,
    required this.onDelete,
  }) : super(key: key);

  @override
  AudioPlayerState createState() => AudioPlayerState();
}

class AudioPlayerState extends State<AudioPlayer> with WidgetsBindingObserver {
  final _player = ja.AudioPlayer();
  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    // Listen to errors during playback.
    _subscription = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace stackTrace) {
        print('A stream error occurred: $e');
      },
    );
    // Try to load audio from a source and catch any errors.
    try {
      await _player.setAudioSource(
        ja.AudioSource.uri(Uri.parse(widget.source)),
      );
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.
      _player.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox.fromSize(
      size: size,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Spacer(flex: 2),

          //Seek bar
          SizedBox(
            width: size.width,
            height: 250,
            child: SeekBar(player: _player),
          ),

          const Spacer(),

          //Controll Buttons
          ControlButtons(_player),

          const Spacer(),

          //Exit button
          AudioButton(
            buttonSize: 42,
            icon: CupertinoIcons.clear,
            iconSize: 24,
            iconColor: trovePrimary,
            borderColor: trovePrimary,
            onTap: () async {
              widget.onDelete();
            },
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class ControlButtons extends StatefulWidget {
  const ControlButtons(this._player, {super.key});

  final ja.AudioPlayer _player;

  @override
  State<ControlButtons> createState() => _ControlButtonsState();
}

class _ControlButtonsState extends State<ControlButtons> {
  static Set<double> allowedSpeeds = {.25, .5, .75, 1.0, 1.25, 1.5, 1.75, 2.0};

  int currentSpeedIndex = 3;

  Widget _buildMainButton(
      ja.PlayerState? state, ja.ProcessingState? processingState) {
    if (state == null ||
        processingState == null ||
        processingState == ja.ProcessingState.loading ||
        processingState == ja.ProcessingState.buffering) {
      return const SizedBox(
        width: 86,
        height: 112,
        child: Align(
          alignment: Alignment(0, -.55),
          child: SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: trovePrimary,
            ),
          ),
        ),
      );
    }

    IconData icon = Icons.replay;
    String label = "replay";
    Alignment? alignment;
    Function onTap = () => widget._player.seek(null);

    if (!state.playing) {
      icon = CupertinoIcons.play_arrow_solid;
      alignment = const Alignment(.2, 0);
      label = "play";
      onTap = () => widget._player.play();
    } else if (processingState != ja.ProcessingState.completed) {
      icon = CupertinoIcons.pause_solid;
      label = "pause";
      onTap = () => widget._player.pause();
    }

    return AudioButton(
      iconSize: 36,
      icon: icon,
      iconColor: trovePrimary,
      borderColor: trovePrimary,
      alignment: alignment,
      label: label,
      labelColor: trovePrimary,
      onTap: () => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: widget._player.playerStateStream,
        builder: (context, snapshot) {
          final playerState = snapshot.data;
          final processingState = playerState?.processingState;

          return Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Spacer(flex: 2),

              //Decrease speed
              AudioButton(
                icon: CupertinoIcons.backward_end_fill,
                iconColor: trovePrimary,
                iconSize: 32,
                label: "",
                onTap: () {
                  if (currentSpeedIndex > 0) {
                    currentSpeedIndex--;
                    widget._player.setSpeed(
                      allowedSpeeds.elementAt(currentSpeedIndex),
                    );
                  }
                },
              ),

              const Spacer(),

              //play/pause button
              _buildMainButton(playerState, processingState),

              const Spacer(),

              //Save Button
              AudioButton(
                icon: CupertinoIcons.checkmark_alt,
                iconColor: Colors.white,
                iconSize: 48,
                fillColor: trovePrimary,
                onTap: () => widget._player.stop(),
                label: 'save',
                labelColor: trovePrimary,
              ),

              const Spacer(),

              //Increase speed
              AudioButton(
                icon: CupertinoIcons.forward_end_fill,
                iconColor: trovePrimary,
                iconSize: 32,
                label: "",
                onTap: () {
                  if (currentSpeedIndex < allowedSpeeds.length - 1) {
                    currentSpeedIndex++;
                    widget._player.setSpeed(
                      allowedSpeeds.elementAt(currentSpeedIndex),
                    );
                    print(allowedSpeeds.elementAt(currentSpeedIndex));
                  }
                },
              ),
              const Spacer(flex: 2),
            ],
          );
        });
  }
}
