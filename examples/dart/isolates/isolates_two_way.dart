import 'dart:async';
import 'dart:isolate';

/// =========================
/// Background entry point
/// =========================
/// Receives the UI's SendPort. Creates its own ReceivePort,
/// then sends its SendPort back to UI as the first handshake message.
Future<void> backgroundEntryPoint(SendPort uiPort) async {
  // --- BG setup ---
  final bgReceivePort = ReceivePort();            // BG's inbound channel
  uiPort.send(bgReceivePort.sendPort);            // handshake: tell UI how to reach BG

  // --- Message flow (UI → BG → UI) ---
  await for (final msg in bgReceivePort) {
    if (msg is String) {
      if (msg == 'ping') {
        uiPort.send('[BG] pong');                 // reply to UI
      } else if (msg == 'quit') {
        uiPort.send('[BG] shutting down');        // final signal
        bgReceivePort.close();                    // stop listening
        break;                                    // exit loop
      } else {
        uiPort.send('[BG] got: $msg');            // echo / handle arbitrary text
      }
    } else if (msg is List && msg.length == 2 && msg[0] == 'add') {
      // Simple RPC-like message: ["add", 41] → 42
      final int n = msg[1] as int;
      uiPort.send('[BG] add result: ${n + 1}');
    } else {
      uiPort.send('[BG] unknown message: $msg');
    }
  }
}

/// =========================
/// UI isolate (main)
/// =========================
/// Sets up UI ReceivePort, spawns BG, waits for the BG SendPort (handshake),
/// then sends commands to BG and handles responses.
Future<void> main() async {
  // --- UI setup ---
  final uiReceivePort = ReceivePort(); // keeps the process alive while open

  // --- Spawn background isolate ---
  await Isolate.spawn<SendPort>(backgroundEntryPoint, uiReceivePort.sendPort);

  // --- UI listener ---
  late final StreamSubscription sub;
  SendPort? bgSendPort; // will be set after handshake

  sub = uiReceivePort.listen((message) async {
    // First message from BG is its SendPort (handshake complete).
    if (message is SendPort) {
      bgSendPort = message;

      // --- UI → BG requests ---
      bgSendPort!.send('ping');         // expect "[BG] pong"
      bgSendPort!.send(['add', 41]);    // expect result 42
      bgSendPort!.send('hello from UI');

      // Ask BG to shut down after a short demo.
      Future.delayed(const Duration(milliseconds: 600), () {
        bgSendPort!.send('quit');
      });
      return;
    }

    // --- BG → UI responses ---
    print('[UI] received: $message');

    // --- Cleanup on completion ---
    if (message == '[BG] shutting down') {
      await sub.cancel();     // stop listening
      uiReceivePort.close();  // close the port so the process can exit
    }
  });
}
