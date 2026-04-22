// ignore_for_file: unused_field

import 'dart:async';

class TimerOwner {
  final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) {});

  void dispose() {}
}
