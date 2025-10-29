import 'dart:async';
import 'dart:isolate';

/// =========================
/// Background entry point
/// =========================
/// Receives the UI's SendPort as the single argument.
/// Uses it to send messages back to the UI isolate.
Future<void> backgroundEntryPoint(SendPort uiPort) async {
  // --- Message flow (BG → UI) ---
  // Send a few messages back to the UI.
  for (var i = 1; i <= 3; i++) {
    uiPort.send('msg #$i from background'); // one-way message to UI
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Signal completion to the UI.
  uiPort.send('done');
}

/// =========================
/// UI isolate (main)
/// =========================
/// Sets up a ReceivePort to listen for messages from BG.
/// Spawns the background isolate and passes uiReceivePort.sendPort.
Future<void> main() async {
  // --- UI setup ---
  final uiReceivePort = ReceivePort(); // keeps the process alive while open

  // --- UI listener ---
  late final StreamSubscription sub;
  sub = uiReceivePort.listen((message) async {
    print('[UI] received: $message');

    // --- Cleanup on completion ---
    if (message == 'done') {
      await sub.cancel();     // stop listening
      uiReceivePort.close();  // close the port so the process can exit
    }
  });

  // --- Spawn background isolate ---
  // Pass the UI's SendPort so the BG can talk back.
  await Isolate.spawn<SendPort>(backgroundEntryPoint, uiReceivePort.sendPort);

}
