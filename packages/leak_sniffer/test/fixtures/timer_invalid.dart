// ignore_for_file: unused_field

import 'dart:async';

class MissingTimerCancelInDispose {
  late final Timer _timer;

  MissingTimerCancelInDispose() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {});
  }

  void dispose() {}
}

class MissingTimerLifecycleMethod {
  final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) {});
}
