// Place 'dart:' imports first

import 'package:flutter/foundation.dart';

/// Controls app-wide text scaling (zoom) without external dependencies.
class ZoomController extends ChangeNotifier {
  ZoomController({
    double initialScale = 1.0,
    this.min = 0.8,
    this.max = 1.6,
    this.step = 0.1,
  }) : _scale = initialScale;

  final double min;
  final double max;
  final double step;

  double _scale;
  double get scale => _scale;

  void zoomIn() {
    final next = (_scale + step).clamp(min, max);
    if (next != _scale) {
      _scale = next;
      notifyListeners();
    }
  }

  void zoomOut() {
    final next = (_scale - step).clamp(min, max);
    if (next != _scale) {
      _scale = next;
      notifyListeners();
    }
  }

  void reset() {
    if (_scale != 1.0) {
      _scale = 1.0;
      notifyListeners();
    }
  }
}
