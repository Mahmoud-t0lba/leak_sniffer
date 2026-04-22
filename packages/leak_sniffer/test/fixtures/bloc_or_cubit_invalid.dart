// ignore_for_file: unused_field

class SearchCubit {
  Future<void> close() async {}
}

class FeedBloc {
  void close() {}
}

class MissingCubitCloseInDispose {
  final SearchCubit _cubit = SearchCubit();

  void dispose() {}
}

class MissingBlocLifecycleMethod {
  late final FeedBloc _bloc;

  MissingBlocLifecycleMethod() {
    _bloc = FeedBloc();
  }
}
