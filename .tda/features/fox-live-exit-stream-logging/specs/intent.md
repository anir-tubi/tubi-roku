# Feature: Fox Live Exit Stream Logging

## Overview

Emit a client-side analytics log when the Fox Player fires `onEventExitStream` during live playback so the event is visible in the `client_logs` pipeline. This addresses an observability gap — during the Flag football game on Mar 21 2026, unexpected redirections to the home page occurred, and the only code path that exits the player is the `exitStream` event, but no logging exists to capture when Fox triggers it.

**JIRA**: [TPLAYER-2723](https://tubitv.atlassian.net/browse/TPLAYER-2723) (Story, cloned from [TPLAYER-2720](https://tubitv.atlassian.net/browse/TPLAYER-2720))

## Requirements

### Functional Requirements
- Log a `videoInfo` client_log with subtype `foxLiveExitStream` when the Fox Player fires the `exitStream` event
- Payload must include: `tubi_id` (from `m.foxPlayerCurrentListing.tubi_id`), `event_data` (stringified raw event from the Fox player), and `timestamp`
- Log must be emitted BEFORE the stream exit/redirect handling begins (before the delay timer is created), to ensure capture
- On-device console logging via `tubiLog()` should also record the event for debugging

### Non-Functional Requirements
- Apply 0.1% client-side sampling (`samplePercent = 0.001`) — only 1 in 1000 sessions will emit the log
- Must not introduce latency or block the exit stream handling flow
- No live-playback guard needed — the Fox player wrapper is exclusively used for live content

## Technical Context

### Integration Points
- **Exit stream handler**: `onFoxVideoPlayerExitStreamChange()` in `FoxVideoPlayerWrapperScreenHelpers.brs` (line 585) — add logging before the existing timer setup
- **Logging API**: Use `logInfo(FormatJSON(payload), "videoInfo", "foxLiveExitStream", 0.001)` — the `logInfo` function accepts `(message, serverTypeName, subtype, samplePercent)` parameters directly
- **Event data source**: `foxRpfInstance.playerEvent.exitStream` field value contains the raw event data
- **Content ID**: Use `m.foxPlayerCurrentListing.tubi_id` — the Tubi-side video ID, populated from `onLiveAssetInfoChange()` via the Fox listing endpoint response

### Existing Patterns to Follow
- `logInfo(FormatJSON(payload), "videoInfo", "subtype-name", samplePercent)` — see examples in `VideoHelpers.brs` (e.g., "video-title-undefined" subtype at line 271)
- `tubiLog(message)` for on-device console debug logging (separate from analytics pipeline)
- Sampling handled internally by `tubiLog_isSampled()` in `Log.brs` using `Rnd(0)` comparison against samplePercent

### Data Flow
```
Fox Player fires exitStream
  → onFoxVideoPlayerExitStreamChange() is called
  → Build log payload { tubi_id, event_data, timestamp }
  → logInfo(FormatJSON(payload), "videoInfo", "foxLiveExitStream", 0.001)
  → tubiLog() for on-device console debugging
  → Start foxPlayerEndSlateCloseDelay timer (existing behavior, unchanged)
```

### File to Modify
- `src/channel/components/controllers/ContentController/FoxVideoPlayerWrapperScreenHelpers.brs` — `onFoxVideoPlayerExitStreamChange()` function (lines 585-591)

## Out of Scope
- Server-side analytics pipeline changes
- Modifying the exit stream behavior itself (timer delay, redirect logic)
- Logging other Fox player events beyond `exitStream`
- Including Fox content ID or delay timer value in the payload (keep it minimal)
