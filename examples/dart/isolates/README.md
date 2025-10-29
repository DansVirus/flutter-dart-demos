#🧠 What are Isolates?

In Dart (and therefore Flutter), isolates are independent threads of execution that do not share memory.

Each isolate has its own:

Memory heap (no shared objects between isolates).

Event loop and microtask queue.

Copy of the Dart runtime.



Isolates are true concurrency, unlike async/await or Futures, which only provide cooperative multitasking within a single isolate.


#🧠How many isolates does a Flutter app run?

When a Flutter application runs, by default there is one primary isolate, the UI isolate aka the main isolate.


This isolate:

Executes your app’s Dart code.

Manages  the build tree, widgets, state, and UI updates.

Communicates with the native layer(i.e. Android or iOS) via platform channels.


In other words, your entire application operates within a single isolate... unless you explicitly request otherwise!

#🧠When to use isolates?

When a task is CPU-bound and risks blocking animation frames. 
      
Use an isolate for  Image decoding/processing.

Large JSON/XML parsing.

Compression.

Cryptography.

Offline ML inference.

Background task handlers, usually from plugins. (callbacks for alarms, notifications, workmanager, etc)

#🧠 How Isolates communicate?

Isolates do not share memory. Because of that, they can’t directly access or mutate each other’s variables, objects, or instances. 

They talk to each other by sending messages through ports.

Dart isolates use a message-passing system similar to the actor model (like Erlang or Akka).

A ReceivePort listens for incoming messages in an isolate.

A SendPort is a handle you can pass to another isolate so it can send messages back.

Messages are copied (serialized/deserialized), not shared.

This ensures thread-safety, at the cost of some serialization overhead.
