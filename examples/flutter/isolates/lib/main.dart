import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // compute

// Βαριά συνάρτηση (πρέπει να είναι top-level για compute)
int slowFib(int n) {
  if (n <= 1) return n;
  // Σκόπιμα αργός αλγόριθμος για CPU-bound παράδειγμα
  return slowFib(n - 1) + slowFib(n - 2);
}

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isolates (compute)',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const IsolatesPage(),
    );
  }
}

class IsolatesPage extends StatefulWidget {
  const IsolatesPage({super.key});
  @override
  State<IsolatesPage> createState() => _IsolatesPageState();
}

class _IsolatesPageState extends State<IsolatesPage> {
  int? result;
  bool busy = false;

  Future<void> _run() async {
    setState(() => busy = true);
    // Παράδειγμα: υπολογισμός Fibonacci σε isolate
    final r = await compute(slowFib, 40); // προσοχή: 40 είναι σχετικά αργό
    if (mounted) {
      setState(() {
        result = r;
        busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Isolates with compute')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy) const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
            if (!busy && result != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('fib(40) = $result'),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: busy ? null : _run,
              child: const Text('Run heavy task'),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Το compute() χρησιμοποιεί isolate για να μην μπλοκάρει το UI. '
                'Βάλε μικρότερο αριθμό αν η συσκευή σου είναι αργή.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
