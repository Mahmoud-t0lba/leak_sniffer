import 'dart:async';

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
