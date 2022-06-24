import 'dart:math';

import 'package:audio_recorder/color_theme.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:just_audio/just_audio.dart' as ja;

class SeekBar extends StatefulWidget {
  final ja.AudioPlayer player;
  final ValueChanged<Duration>? onChanged;

  const SeekBar({Key? key, required this.player, this.onChanged})
      : super(key: key);

  @override
  SeekBarState createState() => SeekBarState();
}

class SeekBarState extends State<SeekBar> {
  double? _dragValue;
  late SliderThemeData sliderThemeData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 4.0,
      inactiveTrackColor: sliderInactiveColor,
      activeTrackColor: troveAccent,
      thumbColor: troveAccent,
    );
  }

  /// Collects the data useful for displaying in a seek bar, using a handy
  /// feature of rx_dart to combine the 3 streams of interest into one.
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          widget.player.positionStream,
          widget.player.bufferedPositionStream,
          widget.player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
        stream: _positionDataStream,
        builder: (context, snapshot) {
          final positionData = snapshot.data;

          final duration = positionData?.duration ?? Duration.zero;
          final position = positionData?.position ?? Duration.zero;
          final bufferedPosition =
              positionData?.bufferedPosition ?? Duration.zero;

          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              //Slider to show the buffered data.
              SizedBox(
                height: 70,
                child: SliderTheme(
                  data: sliderThemeData.copyWith(
                    trackHeight: 4,
                    thumbShape: SliderComponentShape.noThumb,
                    trackShape: const _CustomSliderTrackShape(),
                    activeTrackColor: bufferSliderColor,
                  ),
                  child: ExcludeSemantics(
                    child: Slider(
                      min: 0.0,
                      max: duration.inMilliseconds.toDouble(),
                      value: min(bufferedPosition.inMilliseconds.toDouble(),
                          duration.inMilliseconds.toDouble()),
                      onChanged: (value) {
                        setState(() {
                          _dragValue = value;
                        });
                        if (widget.onChanged != null) {
                          widget.onChanged!(
                              Duration(milliseconds: value.round()));
                        }
                      },
                      onChangeEnd: (value) {
                        widget.player
                            .seek(Duration(milliseconds: value.round()));
                        _dragValue = null;
                      },
                    ),
                  ),
                ),
              ),

              //Slider with the current position of the audio
              SizedBox(
                height: 70,
                child: SliderTheme(
                  data: sliderThemeData.copyWith(
                    inactiveTrackColor: Colors.transparent,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: duration.inMilliseconds.toDouble(),
                    value: min(_dragValue ?? position.inMilliseconds.toDouble(),
                        duration.inMilliseconds.toDouble()),
                    onChanged: (value) {
                      setState(() {
                        _dragValue = value;
                      });
                      if (widget.onChanged != null) {
                        widget
                            .onChanged!(Duration(milliseconds: value.round()));
                      }
                    },
                    onChangeEnd: (value) {
                      widget.player.seek(Duration(milliseconds: value.round()));

                      _dragValue = null;
                    },
                  ),
                ),
              ),

              //Righ timer
              Positioned(
                right: 24.0,
                bottom: 0.0,
                child: Text(
                  RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                          .firstMatch("$duration")
                          ?.group(1) ??
                      '$duration',
                  style: Theme.of(context).textTheme.caption!.copyWith(
                        color: trovePrimary,
                        fontSize: 18,
                      ),
                ),
              ),

              //Left timer
              Positioned(
                left: 24.0,
                bottom: 0.0,
                child: Text(
                  RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                          .firstMatch("$position")
                          ?.group(1) ??
                      '$position',
                  style: Theme.of(context).textTheme.caption!.copyWith(
                        color: trovePrimary,
                        fontSize: 18,
                      ),
                ),
              ),
            ],
          );
        });
  }
}

/// Uses the [RoundedRectSliderTrackShape] as a base class to paint the SliderTrackShape.
/// The only difference is that [RoundedRectSliderTrackShape] uses an additional height of 2 pixels
/// for the active track shape and with this class we don't.
class _CustomSliderTrackShape extends RoundedRectSliderTrackShape {
  /// Create a slider track that draws two rectangles with rounded outer edges.
  const _CustomSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      additionalActiveTrackHeight: 0,
    );
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
