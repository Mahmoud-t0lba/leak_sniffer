// ignore_for_file: unused_field

class State<T> {
  void dispose() {}
}

class SearchController {
  void dispose() {}
}

class SearchViewState extends State<Object> {
  final SearchController _controller = SearchController();
}
