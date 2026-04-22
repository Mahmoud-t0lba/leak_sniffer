// ignore_for_file: unnecessary_overrides, unused_element, unused_field

import 'package:flutter/material.dart';

class MissingTextEditingControllerCleanupView extends StatefulWidget {
  const MissingTextEditingControllerCleanupView({super.key});

  @override
  State<MissingTextEditingControllerCleanupView> createState() =>
      _MissingTextEditingControllerCleanupViewState();
}

class _MissingTextEditingControllerCleanupViewState
    extends State<MissingTextEditingControllerCleanupView> {
  // expect_lint: avoid_undisposed_controller
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class MissingAnimationControllerCleanupView extends StatefulWidget {
  const MissingAnimationControllerCleanupView({super.key});

  @override
  State<MissingAnimationControllerCleanupView> createState() =>
      _MissingAnimationControllerCleanupViewState();
}

class _MissingAnimationControllerCleanupViewState
    extends State<MissingAnimationControllerCleanupView>
    with SingleTickerProviderStateMixin {
  // expect_lint: avoid_undisposed_controller
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class MissingScrollControllerCleanupView extends StatefulWidget {
  const MissingScrollControllerCleanupView({super.key});

  @override
  State<MissingScrollControllerCleanupView> createState() =>
      _MissingScrollControllerCleanupViewState();
}

class _MissingScrollControllerCleanupViewState
    extends State<MissingScrollControllerCleanupView> {
  // expect_lint: avoid_undisposed_controller
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class MissingFocusNodeLifecycle {
  // expect_lint: avoid_undisposed_controller
  final FocusNode _focusNode = FocusNode();
}

class MissingTabControllerCleanupView extends StatefulWidget {
  const MissingTabControllerCleanupView({super.key});

  @override
  State<MissingTabControllerCleanupView> createState() =>
      _MissingTabControllerCleanupViewState();
}

class _MissingTabControllerCleanupViewState
    extends State<MissingTabControllerCleanupView>
    with SingleTickerProviderStateMixin {
  // expect_lint: avoid_undisposed_controller
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class MissingPageControllerCleanupView extends StatefulWidget {
  const MissingPageControllerCleanupView({super.key});

  @override
  State<MissingPageControllerCleanupView> createState() =>
      _MissingPageControllerCleanupViewState();
}

class _MissingPageControllerCleanupViewState
    extends State<MissingPageControllerCleanupView> {
  // expect_lint: avoid_undisposed_controller
  final PageController _pageController = PageController();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class MissingValueNotifierCleanupOwner extends ChangeNotifier {
  // expect_lint: avoid_undisposed_controller
  final ValueNotifier<int> _counter = ValueNotifier<int>(0);

  @override
  void dispose() {
    super.dispose();
  }
}

class MissingGetxLikeControllerCleanupOwner {
  // expect_lint: avoid_undisposed_controller
  final TextEditingController _controller = TextEditingController();

  void onClose() {}
}
