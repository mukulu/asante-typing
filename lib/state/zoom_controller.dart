import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZoomController extends ChangeNotifier {
  static const _kPrefKey = 'zoom.scale';

  double _scale = 1;
  final double minScale = 0.8;
  final double maxScale = 1.6;
  final double step = 0.1;

  double get scale => _scale;

  void zoomIn()  => setScale((_scale + step).clamp(minScale, maxScale));
  void zoomOut() => setScale((_scale - step).clamp(minScale, maxScale));
  void reset()   => setScale(1);

  /// Restores the last persisted zoom from SharedPreferences.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _scale = prefs.getDouble(_kPrefKey) ?? 1.0;
    notifyListeners(); // make sure any listeners rebuild with the restored value
  }

  /// Updates the zoom scale and persists it.
  Future<void> setScale(double v) async {
    if (v == _scale) return;
    _scale = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPrefKey, _scale);
  }
}
