// ignore_for_file: unnecessary_overrides, unused_field

import 'dart:async';

class BaseCubit {
  Future<void> close() async {}
}

class SearchCubit extends BaseCubit {
  late final StreamSubscription<int> _subscription;

  SearchCubit() {
    _subscription = Stream<int>.periodic(
      const Duration(seconds: 1),
    ).listen((_) {});
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
