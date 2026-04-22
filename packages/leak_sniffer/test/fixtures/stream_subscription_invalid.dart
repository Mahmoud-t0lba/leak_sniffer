// ignore_for_file: unused_field

import 'dart:async';

class MissingSubscriptionCancelInDispose {
  late final StreamSubscription<int> _subscription;

  MissingSubscriptionCancelInDispose() {
    _subscription = Stream<int>.periodic(
      const Duration(seconds: 1),
    ).listen((_) {});
  }

  void dispose() {}
}

class MissingSubscriptionLifecycleMethod {
  late final StreamSubscription<int> _subscription;

  MissingSubscriptionLifecycleMethod() {
    _subscription = Stream<int>.periodic(
      const Duration(seconds: 1),
    ).listen((_) {});
  }
}
