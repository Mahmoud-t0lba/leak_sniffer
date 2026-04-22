// ignore_for_file: unnecessary_overrides, unused_element, unused_field

import 'dart:async';

import 'package:flutter/material.dart';

class SearchCubit {
  Future<void> close() async {}
}

class MissingTimerCleanupInCubitLikeOwner {
  // expect_lint: avoid_uncancelled_timer
  late final Timer _pollTimer;

  MissingTimerCleanupInCubitLikeOwner() {
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {});
  }

  Future<void> close() async {}
}

class MissingCubitCleanupInNotifierOwner extends ChangeNotifier {
  // expect_lint: avoid_unclosed_bloc_or_cubit
  final SearchCubit _searchCubit = SearchCubit();

  @override
  void dispose() {
    super.dispose();
  }
}

class MissingSubscriptionCleanupInGetxLikeOwner {
  // expect_lint: avoid_uncancelled_stream_subscription
  late final StreamSubscription<int> _subscription;

  MissingSubscriptionCleanupInGetxLikeOwner() {
    _subscription = Stream<int>.periodic(
      const Duration(seconds: 1),
    ).listen((_) {});
  }

  void onClose() {}
}

class MissingStreamControllerCleanupInProviderLikeOwner extends ChangeNotifier {
  // expect_lint: avoid_unclosed_stream_controller
  final StreamController<String> _events = StreamController<String>.broadcast();

  @override
  void dispose() {
    super.dispose();
  }
}
