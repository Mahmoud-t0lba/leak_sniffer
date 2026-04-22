// ignore_for_file: unnecessary_overrides, unused_field

import 'dart:async';

class State<T> {
  void dispose() {}
}

class SearchController {
  void dispose() {}
}

class DashboardState extends State<Object> {
  final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) {});
  final SearchController _controller = SearchController();
  late final StreamSubscription<int> _subscription;

  DashboardState() {
    _subscription = Stream<int>.periodic(
      const Duration(seconds: 1),
    ).listen((_) {});
  }

  @override
  void dispose() {
    super.dispose();
  }
}
