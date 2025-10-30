import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // compute

/// Why this is CPU-heavy for n = 40:
/// - This naive recursion recomputes the same subproblems many times
///   (it has exponential time complexity ~ O(phi^n), where phi ≈ 1.618).
/// - For n = 40, the call tree explodes into millions of recursive calls.
/// - That level of CPU work will *block* the UI if done on the main isolate,
///   causing visible jank or a frozen animation.
/// - Running it via `compute(...)` offloads the work to a worker isolate so the
///   UI isolate stays responsive.

// Fibonacci (CPU-bound)
int slowFib(int n) {
  if (n <= 1) return n;
  return slowFib(n - 1) + slowFib(n - 2);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isolates Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const IsolatesVisualDemo(),
    );
  }
}

class IsolatesVisualDemo extends StatelessWidget {
  const IsolatesVisualDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocking vs compute()')),
      body: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth > 720;
          final children = [
            const _BlockingPanel(),
            const _ComputePanel(),
          ];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Row(
              children: [
                Expanded(child: children[0]),
                const SizedBox(width: 16),
                Expanded(child: children[1]),
              ],
            )
                : ListView.separated(
              itemCount: children.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) => children[i],
            ),
          );
        },
      ),
    );
  }
}

/// Panel 1: Run slowFib on main isolate -> animation will stutter/freeze while computes.
class _BlockingPanel extends StatefulWidget {
  const _BlockingPanel({super.key});

  @override
  State<_BlockingPanel> createState() => _BlockingPanelState();
}

class _BlockingPanelState extends State<_BlockingPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  int? result;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  // Intentionally runs the heavy computation on the UI isolate to demonstrate blocking.
  void _runBlocking() {
    setState(() => busy = true);
    final r = slowFib(40);
    setState(() {
      result = r;
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Main isolate (Blocking)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _Spinner(controller: _ac),
            const SizedBox(height: 12),
            if (busy) const Text('Computing on UI isolate... the UI freeze.'),
            if (!busy && result != null) Text('fib(40) = $result'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy ? null : _runBlocking,
              child: const Text('Run on main isolate'),
            ),
            const SizedBox(height: 8),
            const Text(
              'This computation runs on the same thread as the UI, '
                  'so the animation will pause until it completes.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel 2: Runs `slowFib` on a worker isolate via `compute(...)` → the animation remains smooth.
///
/// Why `compute`:
/// - Spawns a temporary isolate, executes the callback with the provided input,
///   and returns the result back to the main isolate.
/// - Keeps the UI thread free to render frames.
///
/// Modern alternative:
/// - `await Isolate.run(() => slowFib(40));` offers a clean API for one-off tasks.
class _ComputePanel extends StatefulWidget {
  const _ComputePanel({super.key});

  @override
  State<_ComputePanel> createState() => _ComputePanelState();
}

class _ComputePanelState extends State<_ComputePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  int? result;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  /// Offloads the heavy computation to a worker isolate using `compute`.
  Future<void> _runWithCompute() async {
    setState(() => busy = true);
    final r = await compute(slowFib, 40);
    if (!mounted) return;
    setState(() {
      result = r;
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Worker isolate (compute)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _Spinner(controller: _ac),
            const SizedBox(height: 12),
            if (busy) const Text('Computing on a worker isolate... the UI stays responsive.'),
            if (!busy && result != null) Text('fib(40) = $result'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy ? null : _runWithCompute,
              child: const Text('Run with compute()'),
            ),
            const SizedBox(height: 8),
            const Text(
              'The computation runs on a separate isolate so the animation continues smoothly.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple visual indicator (rotating square) that makes UI jank obvious if the UI thread is blocked.
class _Spinner extends StatelessWidget {
  final AnimationController controller;
  const _Spinner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 120,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Transform.rotate(
            angle: controller.value * 2 * math.pi,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Icon(Icons.refresh, size: 36)),
            ),
          );
        },
      ),
    );
  }
}
