---
name: otel-collector-export-logging
description: otelcol-contrib 0.124.0 otlphttp exporter logs successful exports at debug level only; journald shows no export lines in normal operation
metadata:
  type: project
---

The `opentelemetry-collector-contrib` (v0.124.0) `otlphttp` exporter does NOT log successful exports at `info` level. Successful OTLP metric exports are silent in journald. This is confirmed on both orgrimmar (running since 2026-05-13) and ironforge (first deployed 2026-06-05).

Only auth failures (401/403), connection errors, and retries would surface at `error` level.

To confirm the collector is exporting cleanly: grep for `error|warn|401|403|fail|retry|refused|timeout` in the journal and exclude the known `containers/storage/overlay: permission denied` line (pre-existing partial scrape error on both hosts, non-blocking).

**Why:** First encountered when verifying ironforge's new collector — silence in logs after activation looked suspicious but turned out to be correct behavior.

**How to apply:** When verifying an otel-collector deployment, confirm: (1) service is active, (2) `/run/secrets/otel-collector-env` exists with correct content, (3) target host is reachable over HTTPS, (4) no error-level log lines beyond the known overlay permission issue.
