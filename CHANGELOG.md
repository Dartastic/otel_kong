# Changelog

## [0.1.0-beta.1-wip]

### Added

- Initial release.
- `tracedKong<T>(...)` — wraps a otel_kong call in a CLIENT-kind span
  with vendor-specific attributes.
- Zone-scoped suppression via `runWithoutKongInstrumentation()` / `Async()`.
