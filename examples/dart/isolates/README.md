# Isolates in Dart and Flutter

---

## 1. What Are Isolates

In **Dart** (and therefore **Flutter**), isolates are independent threads of execution that **do not share memory**.

Each isolate has its own:

- Memory heap (no shared objects between isolates)
- Event loop and microtask queue
- Copy of the Dart runtime

> Isolates provide **true concurrency**, unlike `async`/`await` or `Future`, which only enable cooperative multitasking within a single isolate.

---

## 2. Default Isolate in a Flutter App

When a Flutter application runs, by default there is one primary isolate:  
the **UI isolate**, also known as the **main isolate**.

This isolate:

- Executes the app’s Dart code
- Manages the build tree, widgets, state, and UI updates
- Communicates with the native layer (Android/iOS) through **platform channels**

> In essence, the entire Flutter application operates within a single isolate — unless additional ones are explicitly created.

---

## 3. When to Use Isolates

Isolates are useful for **CPU-bound** tasks that risk blocking animation frames or the UI thread.

Typical use cases include:

- Image decoding or processing
- Large JSON or XML parsing
- Compression or decompression
- Cryptography
- Offline machine learning inference
- Background task handlers (e.g., callbacks for alarms, notifications, or `workmanager` jobs)

---

## 4. Communication Between Isolates

Since isolates do not share memory, they cannot directly access or modify each other's variables, objects, or state.  
Instead, they communicate via **message passing** using **ports**.

### 4.1 Key Concepts

- **ReceivePort** — Listens for incoming messages in an isolate.
- **SendPort** — A handle that can be passed to another isolate to send messages back.

Messages are **copied** (serialized and deserialized), not shared, ensuring thread safety but introducing some serialization overhead.

> Dart’s isolate model is inspired by the **Actor Model**, as used in systems like Erlang and Akka.

---

## 5. Summary

| Concept | Description |
|----------|--------------|
| **Isolation** | Each isolate has a separate memory heap; no shared objects |
| **Communication** | Message passing via `SendPort` and `ReceivePort` |
| **Concurrency Type** | True parallelism (not cooperative multitasking) |
| **Default Behavior** | Flutter runs a single UI isolate by default |
| **Typical Use Cases** | CPU-intensive operations such as image processing, JSON parsing, or cryptography |

---

## 6. References

- [Dart Language: Concurrency and Isolates](https://dart.dev/guides/language/concurrency)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/render-performance)
