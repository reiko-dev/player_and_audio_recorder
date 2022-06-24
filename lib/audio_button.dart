import 'package:audio_recorder/audio_recorder.dart';
import 'package:flutter/material.dart';

class AudioButton extends StatelessWidget {
  const AudioButton({
    super.key,
    required this.icon,
    required this.iconColor,
    this.iconSize = 28,
    this.buttonSize = 70,
    this.onTap,
    this.borderColor,
    this.fillColor,
    this.alignment,
    this.label,
    this.labelColor,
  });

  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? fillColor;
  final double buttonSize;
  final Alignment? alignment;
  final String? label;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ClipOval(
            child: Material(
              child: InkWell(
                onTap: onTap,
                child: SizedBox.square(
                  dimension: buttonSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: borderColor != null
                          ? Border.all(color: borderColor!, width: 2)
                          : null,
                      color: fillColor,
                    ),
                    child: Align(
                      alignment: alignment ?? Alignment.center,
                      child: Icon(icon, size: iconSize, color: iconColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                label!,
                style: TextStyle(color: labelColor, fontWeight: textWeight),
              ),
            ),
        ],
      ),
    );
  }
}
