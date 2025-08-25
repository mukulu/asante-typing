import 'package:asante_typing/state/zoom_controller.dart';
import 'package:flutter/widgets.dart';

/// Makes [ZoomController] available down the tree without packages.
class ZoomScope extends InheritedNotifier<ZoomController> {
  const ZoomScope({
    required ZoomController controller, required super.child, super.key,
  }) : super(notifier: controller);

  static ZoomController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ZoomScope>();
    assert(scope != null, 'ZoomScope not found in the widget tree.');
    return scope!.notifier!;
  }
}
