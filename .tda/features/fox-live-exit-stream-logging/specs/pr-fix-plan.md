# PR Fix Plan: Fox Live Exit Stream Logging

## PR Review Comments

### Comment 1 (line 585): Use `msg` parameter with `msg.getData()`
**Verdict**: Valid concern - follows established observer callback pattern in codebase.

**Change**: Update function signature to accept `msg` and use `msg.getData()` instead of accessing `m.foxRpfInstance.playerEvent.exitStream` directly.

### Comment 2 (line 602): Remove `tubiLog`
**Verdict**: Valid concern - debug logging should not be in production code.

**Change**: Remove the `tubiLog()` line. The `logInfo()` call already captures the data for analytics.

## Implementation

### File
`src/channel/components/controllers/ContentController/FoxVideoPlayerWrapperScreenHelpers.brs`

### Changes

1. **Line 585**: `Function onFoxVideoPlayerExitStreamChange()` → `Function onFoxVideoPlayerExitStreamChange(msg)`
2. **Lines 586-589**: Replace direct field access with `msg.getData()` pattern:
   ```brightscript
   exitStreamEventData = ""
   exitStreamValue = msg.getData()
   if exitStreamValue <> invalid then
     exitStreamEventData = FormatJSON(exitStreamValue)
   end if
   ```
3. **Line 602**: Delete `tubiLog("onFoxVideoPlayerExitStreamChange: " + FormatJSON(payload))`

### Final Function
```brightscript
Function onFoxVideoPlayerExitStreamChange(msg)
  exitStreamEventData = ""
  exitStreamValue = msg.getData()
  if exitStreamValue <> invalid then
    exitStreamEventData = FormatJSON(exitStreamValue)
  end if

  tubiId = ""
  if m.foxPlayerCurrentListing <> invalid then
    tubiId = m.foxPlayerCurrentListing.tubi_id
  end if

  payload = {
    "tubi_id": tubiId
    "event_data": exitStreamEventData
    "timestamp": createObject("roDateTime").toISOString()
  }
  logInfo(FormatJSON(payload), "videoInfo", "foxLiveExitStream", 0.001)

  m.foxPlayerEndSlateCloseDelayTimer = createObject("roSGNode", "Timer")
  m.foxPlayerEndSlateCloseDelayTimer.observeField("fire", "onFoxPlayerEndSlateCloseDelayTimerFired")
  ' We want to delay foxPlayerEndSlateCloseDelay seconds before we close the player
  m.foxPlayerEndSlateCloseDelayTimer.duration = m.foxPlayerEndSlateCloseDelay
  m.foxPlayerEndSlateCloseDelayTimer.control = "start"
End Function
```

### Rationale
- `msg.getData()` is the standard Roku SceneGraph pattern for observer callbacks
- Other callbacks in the same file use this pattern: `onLiveAssetInfoChange`, `onFoxVideoPlayerPlayerPositionChange`, `onFoxVideoPlayerAdStateChange`, `onFoxVideoPlayerLoadTimeChange`
- No need to check `m.foxRpfInstance` validity since the observer only fires when the field path was valid at registration
- Null-check on `exitStreamValue` handles the case where the field value itself is invalid
