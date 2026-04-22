// ignore_for_file: unused_element, unused_field

import 'dart:async';

import 'package:flutter/material.dart';

class CleanTextEditingControllerView extends StatefulWidget {
  const CleanTextEditingControllerView({super.key});

  @override
  State<CleanTextEditingControllerView> createState() =>
      _CleanTextEditingControllerViewState();
}

class _CleanTextEditingControllerViewState
    extends State<CleanTextEditingControllerView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class CleanAnimationAndTabControllersView extends StatefulWidget {
  const CleanAnimationAndTabControllersView({super.key});

  @override
  State<CleanAnimationAndTabControllersView> createState() =>
      _CleanAnimationAndTabControllersViewState();
}

class _CleanAnimationAndTabControllersViewState
    extends State<CleanAnimationAndTabControllersView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class CleanScrollAndPageControllersView extends StatefulWidget {
  const CleanScrollAndPageControllersView({super.key});

  @override
  State<CleanScrollAndPageControllersView> createState() =>
      _CleanScrollAndPageControllersViewState();
}

class _CleanScrollAndPageControllersViewState
    extends State<CleanScrollAndPageControllersView> {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class CleanFocusNodeOwner {
  final FocusNode _focusNode = FocusNode();

  void dispose() {
    _focusNode.dispose();
  }
}

class CleanBlocLikeControllerOwner {
  final TextEditingController _queryController = TextEditingController();
  late final StreamController<String> _events;

  CleanBlocLikeControllerOwner() {
    _events = StreamController<String>.broadcast();
  }

  Future<void> close() async {
    _queryController.dispose();
    await _events.close();
  }
}
