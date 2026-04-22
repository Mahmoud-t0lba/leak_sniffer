import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const LeakSnifferExampleApp());
}

class LeakSnifferExampleApp extends StatelessWidget {
  const LeakSnifferExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E), brightness: Brightness.light);

    return MaterialApp(
      title: 'leak_sniffer Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: colorScheme, scaffoldBackgroundColor: const Color(0xFFF6F3EC), useMaterial3: true),
      home: const StreamLeakDemoPage(),
    );
  }
}

class StreamLeakDemoPage extends StatefulWidget {
  const StreamLeakDemoPage({super.key});

  @override
  State<StreamLeakDemoPage> createState() => _StreamLeakDemoPageState();
}

class _StreamLeakDemoPageState extends State<StreamLeakDemoPage> {
  /// This is the intentional demo case:
  /// leak_sniffer should warn because this controller is created and used,
  /// but never closed inside dispose().
  // ignore: unused_field
  final StreamController<int> _counterStream = StreamController<int>.broadcast();

  @override
  void dispose() {
    /// Intentionally missing:
    /// _counterStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5EEDF), Color(0xFFE4F1EC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 30, offset: Offset(0, 16))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Badge(
                          label: 'Active lint demo',
                          background: const Color(0xFFD9F3EA),
                          foreground: const Color(0xFF11695A),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'leak_sniffer stream demo',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF183B37),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'A StreamController receives events when you tap the button, '
                          'but dispose() intentionally forgets to close it so '
                          'avoid_unclosed_stream_controller stays visible.',
                          style: theme.textTheme.titleMedium?.copyWith(height: 1.4, color: const Color(0xFF44615D)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _SectionCard(
                    title: 'What this demo is doing',
                    body:
                        'Press "Add Event" to push values into _counterStream via '
                        '_counterStream.add(_counter). The controller is real and used, '
                        'but no close() call exists in dispose().',
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    title: 'Why the warning appears',
                    body:
                        'leak_sniffer tracks class-owned resources. Since _counterStream '
                        'is created by this State class and dispose() never calls '
                        '_counterStream.close(), the lint reports a potential leak.',
                  ),
                  const SizedBox(height: 16),
                  const _CodeCard(
                    title: 'Expected fix',
                    code:
                        '@override\n'
                        'void dispose() {\n'
                        '  _counterStream.close();\n'
                        '  super.dispose();\n'
                        '}',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.background, required this.foreground});

  final Color background;
  final Color foreground;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.body});

  final String body;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.88), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF183B37)),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF49635F), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.title, required this.code});

  final String code;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: const Color(0xFF163532), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 14),
          SelectableText(
            code,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFE3F7F0),
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
