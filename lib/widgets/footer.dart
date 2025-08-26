// Footer bar widget showing copyright information.

import 'package:asante_typing/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A simple footer displayed at the bottom of the screen.
class Footer extends StatelessWidget {
  /// Creates a [Footer] widget.
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: kColorGreen,
      alignment: Alignment.center,
      child: const Text(
        'Asante Typing Tutor © MUKULU SJ',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kColorYellow,
          fontSize: 12,
          ),
      ),
    );
  }

}
