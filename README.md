# cd_ws_client

A reusable WebSocket client package for Flutter and Dart applications.

`cd_ws_client` is designed to provide a lightweight WebSocket layer with connection management, heartbeat, reconnect policy, status stream, and message stream support.

## Features

* WebSocket connection management
* JSON message parsing
* Broadcast message stream
* Connection status stream
* Heartbeat support
* Automatic reconnect support
* Configurable reconnect policy
* Token authentication message support
* Subscribe and unsubscribe helpers
* Clean `dispose` lifecycle

## Installation

Add this package to your project.

### Local path dependency

```yaml
dependencies:
  cd_ws_client:
    path: packages/cd_ws_client
```

Then run:

```bash
flutter pub get
```

## Usage

Import the package:

```dart
import 'package:cd_ws_client/cd_ws_client.dart';
```

Create a client:

```dart
final wsClient = CdWsClient(
  const CdWsConfig(
    url: 'wss://example.com/ws',
    token: 'your-token',
    heartbeatInterval: Duration(seconds: 20),
    reconnectPolicy: CdWsReconnectPolicy(
      enabled: true,
      maxAttempts: 999,
      minDelay: Duration(seconds: 1),
      maxDelay: Duration(seconds: 10),
    ),
  ),
);
```

Listen to connection status:

```dart
final statusSubscription = wsClient.status.listen((status) {
  print('WebSocket status: $status');
});
```

Listen to messages:

```dart
final messageSubscription = wsClient.messages.listen((message) {
  print('Message type: ${message.type}');
  print('Message data: ${message.data}');
  print('Raw message: ${message.raw}');
});
```

Connect:

```dart
await wsClient.connect();
```

Send a custom message:

```dart
wsClient.send({
  'type': 'ping',
  'time': DateTime.now().millisecondsSinceEpoch,
});
```

Subscribe to a topic:

```dart
wsClient.subscribe(
  'market.price',
  params: {
    'symbol': 'BTCUSDT',
  },
);
```

Unsubscribe from a topic:

```dart
wsClient.unsubscribe('market.price');
```

Dispose:

```dart
await messageSubscription.cancel();
await statusSubscription.cancel();
await wsClient.dispose();
```

## Recommended project structure

```text
packages/
└─ cd_ws_client/
   ├─ pubspec.yaml
   ├─ README.md
   ├─ CHANGELOG.md
   ├─ LICENSE
   └─ lib/
      ├─ cd_ws_client.dart
      └─ src/
         ├─ cd_ws_client_base.dart
         ├─ cd_ws_config.dart
         ├─ cd_ws_message.dart
         ├─ cd_ws_status.dart
         └─ cd_ws_reconnect_policy.dart
```

## Responsibilities

This package should only handle generic WebSocket behavior:

* Connect
* Disconnect
* Send
* Receive
* Heartbeat
* Reconnect
* Status updates
* Message stream

Business-specific logic should stay in the application layer, such as:

* Trading symbols
* Market topics
* Order events
* Price chart data
* User token lifecycle
* Business protocol parsing

## License

This package is licensed under the MIT License.
