// ignore_for_file: unused_field

import 'dart:async';

class BehaviorSubject<T> {
  void close() {}
}

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

class MissingSubjectCloseInDispose {
  final BehaviorSubject<int> _subject = BehaviorSubject<int>();

  void dispose() {}
}
