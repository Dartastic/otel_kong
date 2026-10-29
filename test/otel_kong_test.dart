// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:otel_kong/otel_kong.dart';
import 'package:test/test.dart';

void main() {
  group('otel_kong', () {
    test('suppression toggles in zone', () async {
      expect(kongInstrumentationSuppressed(), isFalse);
      await runWithoutKongInstrumentationAsync(() async {
        expect(kongInstrumentationSuppressed(), isTrue);
      });
      expect(kongInstrumentationSuppressed(), isFalse);
    });

    test('KongResult fields default null', () {
      const r = KongResult();
      expect(r.statusCode, isNull);
    });
  });
}
