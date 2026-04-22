import 'dart:async';

class BehaviorSubject<T> {
  Future<void> close() async {}
}

class ClosesControllerInDispose {
  final StreamController<int> _controller = StreamController<int>();

  void dispose() {
    _controller.close();
  }
}

class ClosesControllerFromHelper {
  late final StreamController<int> _controller;

  ClosesControllerFromHelper() {
    _controller = StreamController<int>();
  }

  Future<void> close() async {
    await _releaseResources();
  }

  Future<void> _releaseResources() async {
    await _controller.close();
  }
}

class ReceivesExternalController {
  final StreamController<int> controller;

  ReceivesExternalController(this.controller);
}

class ClosesSubjectInOnClose {
  final BehaviorSubject<int> _subject = BehaviorSubject<int>();

  Future<void> onClose() async {
    await _releaseResources();
  }

  Future<void> _releaseResources() async {
    await _subject.close();
  }
}
