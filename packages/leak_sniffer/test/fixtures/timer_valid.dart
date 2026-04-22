import 'dart:async';

class CancelsTimerInDispose {
  late final Timer _timer;

  CancelsTimerInDispose() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {});
  }

  void dispose() {
    _timer.cancel();
  }
}

class CancelsTimerInOnClose {
  final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) {});

  void onClose() {
    _releaseResources();
  }

  void _releaseResources() {
    _timer.cancel();
  }
}

class CancelsTimerFromCancelMethod {
  final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) {});

  void cancel() {
    _timer.cancel();
  }
}

class ReceivesExternalTimer {
  final Timer timer;

  ReceivesExternalTimer(this.timer);
}
