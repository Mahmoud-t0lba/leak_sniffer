abstract class BlocBase<State> {
  Future<void> close();
}

class SearchCubit {
  Future<void> close() async {}
}

class FeedBloc {
  Future<void> close() async {}
}

class CounterBloc extends BlocBase<int> {
  @override
  Future<void> close() async {}
}

class ClosesCubitInDispose {
  final SearchCubit _cubit = SearchCubit();

  Future<void> dispose() async {
    await _cubit.close();
  }
}

class ClosesBlocInOnClose {
  late final FeedBloc _bloc;

  ClosesBlocInOnClose() {
    _bloc = FeedBloc();
  }

  Future<void> onClose() async {
    await _releaseResources();
  }

  Future<void> _releaseResources() async {
    await _bloc.close();
  }
}

class ClosesBlocBaseTypedField {
  final BlocBase<int> _bloc = CounterBloc();

  Future<void> close() async {
    await _bloc.close();
  }
}

class ReceivesExternalCubit {
  final SearchCubit cubit;

  ReceivesExternalCubit(this.cubit);
}
