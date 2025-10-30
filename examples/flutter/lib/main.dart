import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // compute

// Σκόπιμα αργός Fibonacci (CPU-bound)
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

/// Panel 1: Τρέχει slowFib στο main isolate -> το animation θα κολλάει όσο διαρκεί ο υπολογισμός.
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

  void _runBlocking() {
    setState(() => busy = true);
    // ΣΚΟΠΙΜΑ στο main isolate: θα παγώσει το UI κι αυτό το animation.
    final r = slowFib(40); // προσαρμόστε (30–42) ανάλογα με τη συσκευή
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
            if (busy) const Text('Υπολογισμός στο main isolate... το UI θα κολλήσει'),
            if (!busy && result != null) Text('fib(40) = $result'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy ? null : _runBlocking,
              child: const Text('Run on main isolate'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Εδώ ο υπολογισμός τρέχει στο ίδιο thread με το UI, '
                  'οπότε το animation θα “παγώσει” μέχρι να τελειώσει.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel 2: Τρέχει slowFib σε worker isolate με compute -> το animation μένει ομαλό.
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

  Future<void> _runWithCompute() async {
    setState(() => busy = true);
    // Με isolate: UI παραμένει responsive.
    final r = await compute(slowFib, 40); // προσαρμόστε (30–42) ανάλογα με τη συσκευή
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
            if (busy) const Text('Υπολογισμός σε worker isolate... UI παραμένει ομαλό'),
            if (!busy && result != null) Text('fib(40) = $result'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy ? null : _runWithCompute,
              child: const Text('Run with compute()'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ο υπολογισμός τρέχει σε ξεχωριστό isolate. Το animation συνεχίζει κανονικά.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ένα απλό “οπτικό” τεστ: περιστρεφόμενο τετράγωνο που θα φανεί αν σπάει/παγώνει.
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
