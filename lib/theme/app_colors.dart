import 'package:flutter/material.dart';

/// App color palette (single source of truth)
const kColorYellow = Color(0xFFF4B233); // base
const kColorGreen  = Color(0xFF1F5F45);
const kColorRed    = Color(0xFF7A1717);

/// Helpers to compute stage-specific accents for units.
@immutable
class UnitColors {
  const UnitColors._();

  /// Main accent for a given zero-based unit index.
  ///
  /// - Units  1..15 (idx 0..14): slightly brighter yellow
  /// - Units 16..21 (idx 15..21): base yellow
  /// - Units 22..26 (idx 21..25): darker yellow
  static Color accent(int unitIndex) {
    final idx1 = unitIndex + 1; // 1-based for readability
    if (idx1 <= 15) return _darken(kColorYellow, 0.12);
    if (idx1 <= 21) return _darken(kColorYellow, 0.24);
    return _darken(kColorYellow, 0.36);
  }

  /// A very light fill for selected/hover surfaces.
  static Color selectionFill(Color base, {double alpha = 0.18}) =>
      base.withValues(alpha: alpha);

  /// A stronger border/outline derived from accent.
  static Color selectionStroke(Color base, {double alpha = 0.45}) =>
      base.withValues(alpha: alpha);

  // --- HSL helpers for perceptual lighten/darken ---


  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final newL = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(newL).toColor();
  }
}
