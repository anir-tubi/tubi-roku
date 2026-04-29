# V1 → V2 Live Test Run API Migration Guide

**Audience**: Teams still calling the legacy V1 live test run endpoints (Roku).

**Status of V1**: Deprecated. Retained for backward compatibility only. Will be removed once all platforms migrate.

## Why migrate

The V1 endpoints (`/test-run/start`, `/test-suite/result`, `/test-run/complete`, `/test-runs/in-progress*`) have structural limitations:

- Suite results are stored as a JSONB blob inside `test_run_results.metadata`, which is prone to race conditions under parallel workers (read-modify-write cycle can silently drop suite data).
- No per-suite lifecycle tracking — there's no way to distinguish "suite is running" from "suite finished", so live dashboards can't show accurate in-flight status.
- Test-run IDs are random UUIDs, making CI retries hard to deduplicate and breaking idempotency.
- The data V1 writes does not populate `test_case_results` / `test_suite_results` — the tables that the modern dashboard's drill-down, flakiness detection, and known-issue linking all query. V1 runs only appear correctly because the separate `POST /api/reports/ingest-direct` call enriches those tables later.

V2 solves all of the above with an atomic, RESTful API backed by dedicated tables. See [`../test-run-progress-reporting-design.md`](../test-run-progress-reporting-design.md) for the full design rationale.

## Endpoint mapping

| Goal | V1 (legacy) | V2 (new) |
| --- | --- | --- |
| Start a test run | `POST /api/test-run/start` | `POST /api/v2/test-runs` |
| Record a suite starting | *(no equivalent)* | `POST /api/v2/test-runs/:testRunId/suites` |
| Record a suite finishing | `POST /api/test-suite/result` | `PATCH /api/v2/test-runs/:testRunId/suites/:suiteId` |
| Complete the run | `POST /api/test-run/complete` | `PATCH /api/v2/test-runs/:testRunId` |
| List in-progress runs | `GET /api/test-runs/in-progress` | `GET /api/v2/test-runs?status=running` |
| Get run detail | `GET /api/test-runs/in-progress/:id` | `GET /api/v2/test-runs/:testRunId` |
| Force status change | `PATCH /api/test-runs/in-progress/:id/status` | `PATCH /api/v2/test-runs/:testRunId` |

**Unchanged**: `POST /api/reports/ingest-direct` (the Allure `push-report` step). Continue calling this the same way — it uses the same `testRunId` that V2's `POST /api/v2/test-runs` returns.

## `POST /api/v2/test-runs` — Create Run

### Request comparison

**V1:**

```json
POST /api/test-run/start
{
  "event": "test_run_started",
  "timestamp": "2026-04-23T14:55:35Z",
  "platform": "roku",
  "runners": "1",
  "tag": "@sidenav",
  "githubActionId": "24818732594",
  "estimated": { "tests": 31, "suites": 1 }
}
```

**V2:**

```json
POST /api/v2/test-runs
{
  "platform": "roku",
  "githubRunId": "24818732594",
  "totalSuites": 1,
  "estimatedTests": 31,
  "tags": ["@sidenav"],
  "deviceCount": 1,
  "type": "regression"
}
```

### Field mapping

| V1 field | V2 field | Notes |
| --- | --- | --- |
| `platform` | `platform` | Unchanged. Required. |
| `githubActionId` | `githubRunId` | **Renamed**, now **required**. |
| `estimated.suites` | `totalSuites` | **Required**, flattened to top level. |
| `estimated.tests` | `estimatedTests` | Optional, flattened to top level. |
| `tag` (string) | `tags` (string array) | Pass `[tag]` if you have a single tag. |
| `runners` | `deviceCount` | Renamed, now a number (not a string). |
| `event`, `timestamp` | — | Drop. Inferred / server-assigned. |
| — | `type` | New field. One of `regression`, `smoke`, `pr`, `sweep`, `analysis`. Defaults to `regression`. |

### Response — critical change

**V1:**

```json
{ "success": true, "data": { "testRunId": "<random-uuid>", "test_run_id_in_progress": "...", "message": "..." } }
```

**V2:**

```json
{ "success": true, "data": { "testRunId": "roku.24818732594" } }
```

The ID is now **deterministic**: `{platform}.{githubRunId}`. **Persist this `testRunId`** — every subsequent call requires it in the URL path.

**Idempotency bonus**: Calling `POST /api/v2/test-runs` again with the same `githubRunId` wipes and recreates the run and all associated data. Use this for CI retries instead of trying to deduplicate client-side.

## Suite Lifecycle — biggest change

V1 used a single `POST /api/test-suite/result` call after a suite completed. V2 splits this into **two calls**, enabling real-time dashboards to show suites as they progress.

### Step A: Suite starts → `POST /api/v2/test-runs/:testRunId/suites`

Call this when a suite *begins running*, before you have any results.

```json
POST /api/v2/test-runs/roku.24818732594/suites
{
  "suite": {
    "path": "tests/sidenav/navigation.spec.ts",
    "name": "Sidenav navigation"
  },
  "device": {
    "id": "00008130-0016790021EA001C",
    "model": "Roku Ultra 4800"
  },
  "typeOfTest": "functional"
}
```

Response:

```json
{ "success": true, "data": { "suiteId": "<uuid>", "status": "running" } }
```

**Persist `suiteId`** — you need it for the PATCH call when the suite finishes.

### Step B: Suite finishes → `PATCH /api/v2/test-runs/:testRunId/suites/:suiteId`

```json
PATCH /api/v2/test-runs/roku.24818732594/suites/<suiteId>
{
  "results": {
    "total": 5,
    "passed": 4,
    "failed": 1,
    "broken": 0,
    "skipped": 0
  },
  "tests": [
    {
      "title": "should open sidenav",
      "fullName": "Sidenav navigation > should open sidenav",
      "duration": 1234,
      "status": "passed"
    },
    {
      "title": "should close sidenav",
      "fullName": "Sidenav navigation > should close sidenav",
      "duration": 987,
      "status": "failed",
      "failureMessages": ["Expected element to be hidden"]
    }
  ],
  "status": "completed"
}
```

### Differences from V1's single-call suite endpoint

- `tests` is now a **flat array** of `{title, fullName, duration, status, failureMessages?}`. V1 used a nested `{passed: [...], failed: [...]}` shape — that's gone.
- Every test must have an explicit `status` field: `passed` | `failed` | `broken` | `skipped`.
- `results` has a new `broken` field (for test-infrastructure failures, distinct from actual test failures).
- **Do not send `duration` on the suite**. The server computes it from `(completed_at - started_at)`.
- **Do not re-send device info** in Step B. It was recorded in Step A.

### Minimal migration path (no real-time tracking)

If you can't split the two calls across suite lifecycle events in your test runner, the simplest migration is to call A followed immediately by B when the suite finishes:

```js
const { data: { suiteId } } = await POST(`/api/v2/test-runs/${testRunId}/suites`, startPayload);
await PATCH(`/api/v2/test-runs/${testRunId}/suites/${suiteId}`, completePayload);
```

You lose the "suite is running" indicator in the dashboard but still get correct data into `test_suite_results` and `test_case_results`.

## `PATCH /api/v2/test-runs/:testRunId` — Complete Run

### Request comparison

**V1:**

```json
POST /api/test-run/complete
{
  "event": "test_run_completed",
  "timestamp": "...",
  "platform": "roku",
  "test_run_id_in_progress": "<opaque-id>",
  "success": true,
  "summary": {
    "totalTestSuites": 1,
    "totalTests": 31,
    "passed": 30,
    "failed": 1,
    "skipped": 0,
    "duration": 120000
  }
}
```

**V2:**

```json
PATCH /api/v2/test-runs/roku.24818732594
{
  "status": "completed",
  "summary": {
    "totalTests": 31,
    "passed": 30,
    "failed": 1,
    "skipped": 0,
    "durationMs": 120000
  }
}
```

### Changes

| V1 | V2 | Notes |
| --- | --- | --- |
| `success: true/false` | `status: "completed" \| "failed" \| "cancelled"` | Explicit string status. |
| `test_run_id_in_progress` in body | `testRunId` in URL path | Deterministic. |
| `duration` | `durationMs` | Renamed for clarity. |
| `totalTestSuites` | — | Server computes from suite count. |
| `event`, `timestamp`, `platform` | — | Drop. |

**Tip**: If you called the suite PATCH endpoint faithfully during the run, the server already has accurate counts from suite aggregation. You can send just `{"status": "completed"}` and omit the `summary` entirely.

## Minimal `dashboardReporter.js` diff

```js
// ============ start ============
// V1:
await POST('/api/test-run/start', {
  event: 'test_run_started',
  platform,
  githubActionId,
  estimated: { tests, suites },
  tag,
});

// V2:
const { data: { testRunId } } = await POST('/api/v2/test-runs', {
  platform,
  githubRunId: githubActionId,
  totalSuites: suites,
  estimatedTests: tests,
  tags: tag ? [tag] : [],
});
// Save testRunId for subsequent calls (env var, file, step output, etc.)

// ============ per suite ============
// V1 (one call after suite finishes):
await POST('/api/test-suite/result', {
  platform,
  suite: { path, name, duration },
  results,
  tests,
});

// V2 (two calls):
const { data: { suiteId } } = await POST(`/api/v2/test-runs/${testRunId}/suites`, {
  suite: { path, name },
  device: device ? { id: device.serial, model: device.model } : undefined,
});
await PATCH(`/api/v2/test-runs/${testRunId}/suites/${suiteId}`, {
  results: {
    total: results.total,
    passed: results.passed,
    failed: results.failed,
    broken: 0,
    skipped: results.skipped,
  },
  tests: flattenTests(tests), // { passed: [...], failed: [...] } → [{...status: 'passed'}, {...status: 'failed'}]
  status: 'completed',
});

// ============ complete ============
// V1:
await POST('/api/test-run/complete', { platform, success, summary });

// V2:
await PATCH(`/api/v2/test-runs/${testRunId}`, {
  status: success ? 'completed' : 'failed',
  summary: { totalTests, passed, failed, skipped, durationMs },
});
```

## Gotchas

1. **404 on suite POST**: Means the parent test run's status isn't `running`. V2 rejects suite creation against runs that have already completed. Ensure `POST /api/v2/test-runs` runs before any suite creation and that `PATCH /api/v2/test-runs/:id` with `status: "completed"` runs *after* all suites finish.
2. **`testRunId` threading**: Unlike V1 — which would fall back to "find the only in-progress run matching this platform" — V2 requires the exact ID in every URL. Persist it across workflow steps via a step output:

   ```yaml
   - id: start
     run: |
       TEST_RUN_ID=$(curl -s -X POST .../api/v2/test-runs ... | jq -r '.data.testRunId')
       echo "test_run_id=$TEST_RUN_ID" >> $GITHUB_OUTPUT

   - run: curl -X PATCH .../api/v2/test-runs/${{ steps.start.outputs.test_run_id }} ...
   ```
3. **`ingest-direct` still works**: Your `push-report` step doesn't change. It can target the same `testRunId` you created with V2. The Allure ingest enriches (not replaces) the per-case and per-suite tables.
4. **Idempotent retries**: Re-calling `POST /api/v2/test-runs` with the same `githubRunId` wipes existing data and recreates the run. Lean on this for CI retries instead of doing client-side dedup.
5. **Type-of-test metadata**: If you populate `typeOfTest` / `experimentName` when creating suites (Step A), your runs will show up correctly in the new dashboard filters for functional vs. experiment-gated tests. Legacy V1 runs can't set these fields.

## Suggested rollout

1. **Phase 1 — Shadow writes (optional)**: Have the reporter call both V1 and V2 in parallel for one week. Compare data in the dashboard to verify parity.
2. **Phase 2 — Cut over `start` + `complete`**: Switch these two actions to V2. Keep `push-report` calling `ingest-direct` unchanged.
3. **Phase 3 — Add suite lifecycle**: Wire the two-call suite tracking into the test runner itself (not the workflow), where you have access to suite-start events. This is the step that unlocks real-time dashboards.
4. **Phase 4 — Remove V1 calls**: Drop the V1 calls from the workflow once Phase 3 is stable.

Once all OTT platforms reach Phase 4, the `automation-ui` team can remove the legacy V1 endpoints and their supporting controller/repository code.

## Related documentation

- [`test-run-progress-reporting-design.md`](../test-run-progress-reporting-design.md) — Full V2 architecture, data model, and design rationale.
- [`test-runs-in-progress.md`](./test-runs-in-progress.md) — Legacy V1 endpoint reference (deprecated; kept for historical context).
