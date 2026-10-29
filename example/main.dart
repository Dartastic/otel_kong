// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_kong/otel_kong.dart';

/// Traces Kong calls with OpenTelemetry.
///
/// `otel_kong` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Kong call in
/// [tracedKong]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'kong-example');

  // Traces a Kong call.
  final kongId = await tracedKong<String>(
    operation: 'create',
    invoke: () async {
      // Make the Kong call here, then report what it returned.
      const id = 'kong_8f3a2c';
      return const KongCallResult(
          value: id,
          result: KongResult(
              route: 'example',
              service: 'example',
              consumer: 'example',
              upstreamHost: 'api.example.com',
              upstreamUri: 'example',
              plugin: 'example',
              latencyKongMs: 120,
              latencyProxyMs: 120,
              statusCode: 201,
              errorCode: 'example',
              errorMessage: 'example'));
    },
  );
  OTelLog.info('tracedKong create returned $kongId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutKongInstrumentationAsync.
  await runWithoutKongInstrumentationAsync(
    () => tracedKong<String>(
      operation: 'create',
      invoke: () async {
        const id = 'kong_8f3a2c';
        return const KongCallResult(
            value: id,
            result: KongResult(
                route: 'example',
                service: 'example',
                consumer: 'example',
                upstreamHost: 'api.example.com',
                upstreamUri: 'example',
                plugin: 'example',
                latencyKongMs: 120,
                latencyProxyMs: 120,
                statusCode: 201,
                errorCode: 'example',
                errorMessage: 'example'));
      },
    ),
  );

  await OTel.shutdown();
}
