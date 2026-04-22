import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'class_resource_analyzer.dart';
import 'resource_spec.dart';

const streamControllerResourceSpecs = [
  ResourceSpec(
    debugName: 'StreamController',
    typeChecker: TypeChecker.fromUrl('dart:async#StreamController'),
    cleanupAction: CleanupAction.close,
  ),
  ResourceSpec(
    debugName: 'Subject',
    typeNames: ['Subject'],
    typeNameSuffixes: ['Subject'],
    cleanupAction: CleanupAction.close,
  ),
];

const streamControllerResourceAnalyzer = ClassResourceAnalyzer(
  specs: streamControllerResourceSpecs,
);

const streamSubscriptionResourceSpecs = [
  ResourceSpec(
    debugName: 'StreamSubscription',
    typeChecker: TypeChecker.fromUrl('dart:async#StreamSubscription'),
    cleanupAction: CleanupAction.cancel,
  ),
];

const streamSubscriptionResourceAnalyzer = ClassResourceAnalyzer(
  specs: streamSubscriptionResourceSpecs,
);

const timerResourceSpecs = [
  ResourceSpec(
    debugName: 'Timer',
    typeChecker: TypeChecker.fromUrl('dart:async#Timer'),
    cleanupAction: CleanupAction.cancel,
  ),
];

const timerResourceAnalyzer = ClassResourceAnalyzer(specs: timerResourceSpecs);

const blocOrCubitResourceSpecs = [
  ResourceSpec(
    debugName: 'BlocBase',
    typeNames: ['BlocBase', 'Cubit'],
    typeNameSuffixes: ['Bloc', 'Cubit'],
    cleanupAction: CleanupAction.close,
  ),
];

const blocOrCubitResourceAnalyzer = ClassResourceAnalyzer(
  specs: blocOrCubitResourceSpecs,
);

const disposableControllerResourceSpecs = [
  ResourceSpec(
    debugName: 'TextEditingController',
    typeChecker: TypeChecker.fromName(
      'TextEditingController',
      packageName: 'flutter',
    ),
    cleanupAction: CleanupAction.dispose,
  ),
  ResourceSpec(
    debugName: 'AnimationController',
    typeChecker: TypeChecker.fromName(
      'AnimationController',
      packageName: 'flutter',
    ),
    cleanupAction: CleanupAction.dispose,
  ),
  ResourceSpec(
    debugName: 'ScrollController',
    typeChecker: TypeChecker.fromName(
      'ScrollController',
      packageName: 'flutter',
    ),
    cleanupAction: CleanupAction.dispose,
  ),
  ResourceSpec(
    debugName: 'FocusNode',
    typeChecker: TypeChecker.fromName('FocusNode', packageName: 'flutter'),
    cleanupAction: CleanupAction.dispose,
  ),
  ResourceSpec(
    debugName: 'TabController',
    typeChecker: TypeChecker.fromName('TabController', packageName: 'flutter'),
    cleanupAction: CleanupAction.dispose,
  ),
  ResourceSpec(
    debugName: 'PageController',
    typeChecker: TypeChecker.fromName('PageController', packageName: 'flutter'),
    cleanupAction: CleanupAction.dispose,
  ),
  ResourceSpec(
    debugName: 'ChangeNotifier',
    typeChecker: TypeChecker.fromName('ChangeNotifier', packageName: 'flutter'),
    cleanupAction: CleanupAction.dispose,
  ),
  ResourceSpec(
    debugName: 'ValueNotifier',
    typeChecker: TypeChecker.fromName('ValueNotifier', packageName: 'flutter'),
    cleanupAction: CleanupAction.dispose,
  ),
  ResourceSpec(
    debugName: 'Disposable controller',
    typeNameSuffixes: ['Controller'],
    cleanupAction: CleanupAction.dispose,
  ),
  ResourceSpec(
    debugName: 'Disposable node',
    typeNameSuffixes: ['Node'],
    cleanupAction: CleanupAction.dispose,
  ),
  ResourceSpec(
    debugName: 'Disposable notifier',
    typeNameSuffixes: ['Notifier'],
    cleanupAction: CleanupAction.dispose,
  ),
];

const disposableControllerResourceAnalyzer = ClassResourceAnalyzer(
  specs: disposableControllerResourceSpecs,
);

const allLeakSnifferResourceSpecs = [
  ...streamControllerResourceSpecs,
  ...streamSubscriptionResourceSpecs,
  ...timerResourceSpecs,
  ...blocOrCubitResourceSpecs,
  ...disposableControllerResourceSpecs,
];

const allLeakSnifferResourceAnalyzer = ClassResourceAnalyzer(
  specs: allLeakSnifferResourceSpecs,
);
