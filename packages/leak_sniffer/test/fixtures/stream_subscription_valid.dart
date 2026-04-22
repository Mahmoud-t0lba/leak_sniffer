import 'dart:async';

class CancelsSubscriptionInDispose {
  late final StreamSubscription<int> _subscription;

  CancelsSubscriptionInDispose() {
    _subscription = Stream<int>.periodic(
      const Duration(seconds: 1),
    ).listen((_) {});
  }

  Future<void> dispose() async {
    await _subscription.cancel();
  }
}

class CancelsSubscriptionFromHelper {
  late final StreamSubscription<int> _subscription;

  CancelsSubscriptionFromHelper() {
    _subscription = Stream<int>.periodic(
      const Duration(seconds: 1),
    ).listen((_) {});
  }

  Future<void> close() async {
    await _cleanup();
  }

  Future<void> _cleanup() async {
    await _subscription.cancel();
  }
}

class ReceivesExternalSubscription {
  final StreamSubscription<int> subscription;

  ReceivesExternalSubscription(this.subscription);
}
