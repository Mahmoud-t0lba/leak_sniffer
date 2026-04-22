// ignore_for_file: unused_element, unused_field

import 'dart:async';

import 'package:flutter/material.dart';

class SearchCubit {
  Future<void> close() async {}
}

class CleanTimerInCubitLikeOwner {
  late final Timer _pollTimer;

  CleanTimerInCubitLikeOwner() {
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {});
  }

  Future<void> close() async {
    _pollTimer.cancel();
  }
}

class CleanCubitInNotifierOwner extends ChangeNotifier {
  final SearchCubit _searchCubit = SearchCubit();

  @override
  void dispose() {
    _searchCubit.close();
    super.dispose();
  }
}

class CleanSubscriptionInGetxLikeOwner {
  late final StreamSubscription<int> _subscription;

  CleanSubscriptionInGetxLikeOwner() {
    _subscription = Stream<int>.periodic(
      const Duration(seconds: 1),
    ).listen((_) {});
  }

  Future<void> onClose() async {
    await _subscription.cancel();
  }
}

class CleanStreamControllerInProviderLikeOwner extends ChangeNotifier {
  final StreamController<String> _events = StreamController<String>.broadcast();

  @override
  void dispose() {
    _events.close();
    super.dispose();
  }
}
