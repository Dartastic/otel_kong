# otel_kong

Dartastic OpenTelemetry bridge for Kong (API gateway).

Wraps each call in a CLIENT-kind span with vendor-specific attributes following OpenTelemetry semantic conventions where applicable.

```dart
import 'package:otel_kong/otel_kong.dart';

await tracedKong<void>(
  operation: 'someOp',
  invoke: () async {
    final r = await client.someOp();
    return KongCallResult(value: r, result: KongResult(statusCode: 200));
  },
);
```

Suppress instrumentation within a block:

```dart
await runWithoutKongInstrumentationAsync(() async {
  await client.someInternalSync();
});
```
