// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_kong_suppression.dart';

class KongResult {
  /// Creates a result.
  const KongResult({
    this.route,
    this.service,
    this.consumer,
    this.upstreamHost,
    this.upstreamUri,
    this.plugin,
    this.latencyKongMs,
    this.latencyProxyMs,
    this.statusCode,
    this.errorCode,
    this.errorMessage,
  });

  final String? route;
  final String? service;
  final String? consumer;
  final String? upstreamHost;
  final String? upstreamUri;
  final String? plugin;
  final int? latencyKongMs;
  final int? latencyProxyMs;
  final int? statusCode;
  final String? errorCode;
  final String? errorMessage;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class KongCallResult<T> {
  /// Creates a call result.
  const KongCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final KongResult? result;
}

Future<T> tracedKong<T>({
  required String operation,
  required Future<KongCallResult<T>> Function() invoke,
  APITracer? tracer,
}) async {
  if (kongInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTelAPI.tracerProvider().getTracer('otel_kong');
  final span = t.startSpan('kong $operation', kind: SpanKind.server);
  try {
    span.addAttributes(
        OTelAPI.attributes([OTelAPI.attributeString('http.route', operation)]));
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.route != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('http.route', res.route!)]));
      }
      if (res.service != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('service.name', res.service!)]));
      }
      if (res.consumer != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('kong.consumer', res.consumer!)]));
      }
      if (res.upstreamHost != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('server.address', res.upstreamHost!)]));
      }
      if (res.upstreamUri != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('url.full', res.upstreamUri!)]));
      }
      if (res.plugin != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('kong.plugin', res.plugin!)]));
      }
      if (res.latencyKongMs != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeInt('kong.latency.kong', res.latencyKongMs!)]));
      }
      if (res.latencyProxyMs != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeInt('kong.latency.proxy', res.latencyProxyMs!)]));
      }
      if (res.statusCode != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeInt('http.response.status_code', res.statusCode!)
        ]));
      }
      if (res.errorCode != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('kong.error.code', res.errorCode!)]));
      }
      final fail = res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString(
              ErrorAttributes.errorType.key, res.errorCode ?? 'kong.error')
        ]));
        span.setStatus(SpanStatusCode.Error, res.errorMessage);
      }
    }
    return r.value;
  } catch (e, st) {
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
