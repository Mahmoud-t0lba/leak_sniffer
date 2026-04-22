// ignore_for_file: unused_field

class State<T> {
  void dispose() {}
}

class SearchCubit {
  Future<void> close() async {}
}

class SearchViewState extends State<Object> {
  final SearchCubit _cubit = SearchCubit();
}
