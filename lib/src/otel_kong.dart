// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_kong_suppression.dart';

class KongResult {
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

class KongCallResult<T> {
  const KongCallResult({required this.value, this.result});
  final T value;
  final KongResult? result;
}

Future<T> tracedKong<T>({
  required String operation,
  required Future<KongCallResult<T>> Function() invoke,
  Tracer? tracer,
}) async {
  if (kongInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTel.tracerProvider().getTracer('otel_kong');
  final span = t.startSpan('kong $operation', kind: SpanKind.server);
  try {
    span.setStringAttribute('http.route', '$operation');
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.route != null) {
        span.setStringAttribute('http.route', res.route!);
      }
      if (res.service != null) {
        span.setStringAttribute('service.name', res.service!);
      }
      if (res.consumer != null) {
        span.setStringAttribute('kong.consumer', res.consumer!);
      }
      if (res.upstreamHost != null) {
        span.setStringAttribute('server.address', res.upstreamHost!);
      }
      if (res.upstreamUri != null) {
        span.setStringAttribute('url.full', res.upstreamUri!);
      }
      if (res.plugin != null) {
        span.setStringAttribute('kong.plugin', res.plugin!);
      }
      if (res.latencyKongMs != null) {
        span.setIntAttribute('kong.latency.kong', res.latencyKongMs!);
      }
      if (res.latencyProxyMs != null) {
        span.setIntAttribute('kong.latency.proxy', res.latencyProxyMs!);
      }
      if (res.statusCode != null) {
        span.setIntAttribute('http.response.status_code', res.statusCode!);
      }
      if (res.errorCode != null) {
        span.setStringAttribute('kong.error.code', res.errorCode!);
      }
      final fail = res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.setStringAttribute(
            ErrorResource.errorType.key, res.errorCode ?? 'kong.error');
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
