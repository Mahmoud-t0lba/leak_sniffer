// ignore_for_file: unused_field

import 'dart:async';

class MissingControllerCloseInDispose {
  final StreamController<int> _controller = StreamController<int>();

  void dispose() {}
}

class MissingControllerLifecycleMethod {
  late final StreamController<String> _controller;

  MissingControllerLifecycleMethod() {
    _controller = StreamController<String>.broadcast();
  }
}
