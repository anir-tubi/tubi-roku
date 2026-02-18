' PivotItem - A specialized EnhancedButton for pivot list items.
' Extends EnhancedButton with pivot-specific styling and viewable impression tracking.
'
' Impression tracking is always enabled for pivot items. When a pivot item is visible
' for >= 1 second, a viewable impression event is fired via m.global.viewableImpressionEventInfo
' with trackingType "pivot". ContentController aggregates these into the components/utility_tiles
' payload format (as opposed to the containers/contents format used by StarterGridItem).
'
' Tracking fields read from parent PivotList at fire time:
'   - parentScreenId: screen ID for the impression event
'   - trackingPageInfo: page context including personalization_id


' Initializes the PivotItem component
'
' Sets up:
'   1. Pivot-specific 9-patch background (inserted behind all children)
'   2. Typography for both default and focused label states
'   3. Theme observer for dynamic color updates
'   4. Viewable impression tracking state (timespans, dwell accumulators)
'   5. Parent node reference for reading tracking context at fire time
'   6. Render-tracking, content, and focus observers for impression lifecycle
Function init() as Void
  topRef = m.top
  topRef.padding = 24

  ' Cache the pivotBackground Poster and re-insert at index 0 so it renders
  ' behind the button label and focus overlay inherited from EnhancedButton
  m.pivotBackground = topRef.findNode("pivotBackground")
  topRef.insertChild(m.pivotBackground, 0)

  ' Override the default EnhancedButton background URIs with the pivot 9-patch.
  ' Both unfocused and focused states share the same asset; color tinting is
  ' handled by onPivotItemThemeChange via blendColor.
  pivotBgUri = "pkg:/images/pivot-background-$$RES$$.9.png"
  m.buttonBackground.uri = pivotBgUri
  m.buttonBackgroundFocused.uri = pivotBgUri
  topRef.backgroundUri = pivotBgUri

  ' Keep pivotBackground dimensions in sync whenever the button is resized
  topRef.observeFieldScoped("width", "onPivotItemSizeChange")
  topRef.observeFieldScoped("height", "onPivotItemSizeChange")

  ' Apply bodySmallStrong typography to both default and focused label nodes
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.label, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.labelFocused, typographyConstants.ids.bodySmallStrong)

  ' Subscribe to global theme changes and apply initial theme colors
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onPivotItemThemeChange")
  end if
  onPivotItemThemeChange()

  ' -- Viewable impression tracking (always enabled for pivots) --
  ' m.itemVisibleTimespan: tracks total visible duration (set when renderTracking becomes "full"/"partial")
  ' m.itemFocusTimespan: tracks active focus duration (set when itemHasFocus becomes true)
  ' m.impressionDwellTime: accumulated focus time in ms across multiple focus/unfocus cycles
  m.itemVisibleTimespan = invalid
  m.itemFocusTimespan = invalid
  m.impressionDwellTime = 0
  m.pivotId = ""
  m.pivotCol = 1

  ' Walk up the node tree to find the PivotList parent.
  ' PivotItem is nested inside RowList internal containers, so we walk up to 10 levels.
  m.parentTrackingNode = invalid
  parent = topRef.getParent()
  for x = 1 to 10
    if parent = invalid then exit for
    if parent.hasField("parentScreenId") = true
      m.parentTrackingNode = parent
      exit for
    end if
    parent = parent.getParent()
  end for

  topRef.enableRenderTracking = true
  topRef.observeFieldScoped("renderTracking", "onPivotRenderTrackingChange")
  topRef.observeFieldScoped("itemContent", "onPivotItemContentChange")
  topRef.observeFieldScoped("itemHasFocus", "onPivotItemFocusChange")
End Function


' Applies pivot-specific theme colors to the button and pivot background
'
' The unfocused button background is tinted with neutralColor while the
' additional pivotBackground layer behind it uses shadeColor4 for a
' subtle layered visual effect.
'
' @param msg - Optional roSGNodeEvent from observeFieldScoped("theme"),
'              or invalid when called directly during init()
Function onPivotItemThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    ' Tint the unfocused button background with the neutral theme color
    m.buttonBackground.blendColor = theme.neutralColor
    ' Tint the outer pivot background with the shade color for a layered look
    m.pivotBackground.blendColor = theme.shadeColor4
  end if
End Function


' Syncs pivotBackground Poster dimensions when the button width or height changes
'
' Called by observeFieldScoped on both "width" and "height" so the background
' layer always matches the EnhancedButton bounds.
'
' @param msg - roSGNodeEvent from the width/height observer (unused)
Function onPivotItemSizeChange(msg = invalid) as Void
  topRef = m.top
  m.pivotBackground.width = topRef.width
  m.pivotBackground.height = topRef.height
End Function


' Called when RowList assigns or recycles itemContent on this item
'
' Caches the pivot ID (e.g. "throwback_faves") and 1-based column position.
' These values are included in the viewable impression event payload when
' the item eventually goes off-screen after being visible >= 1 second.
'
' @param msg - roSGNodeEvent from observeFieldScoped("itemContent") (unused;
'              content is read directly from m.top.itemContent)
Function onPivotItemContentChange(msg = invalid) as Void
  topRef = m.top
  itemContent = topRef.itemContent
  if itemContent = invalid then return

  ' Cache the pivot identifier from the content node (e.g. "throwback_faves")
  m.pivotId = itemContent.id

  ' RowList sets a 0-based "index" field on item components; convert to
  ' 1-based column for the tracking payload
  m.pivotCol = topRef.index + 1
End Function


' Accumulates dwell_time (total ms the item was focused) across focus/unfocus cycles
'
' When the item gains focus, a new roTimespan is created. When it loses focus,
' the elapsed time is added to m.impressionDwellTime. The accumulated value
' is included in the impression event when the item eventually goes off-screen.
'
' @param msg - roSGNodeEvent from observeFieldScoped("itemHasFocus") (unused;
'              focus state is read directly from m.top.itemHasFocus)
Function onPivotItemFocusChange(msg = invalid) as Void
  topRef = m.top
  if topRef.itemHasFocus = true
    ' Focus gained — start a new timer to track this focus session
    m.itemFocusTimespan = CreateObject("roTimespan")
  else if m.itemFocusTimespan <> invalid
    ' Focus lost — add elapsed focus time to the running accumulator
    m.impressionDwellTime = m.impressionDwellTime + m.itemFocusTimespan.totalMilliseconds()
    m.itemFocusTimespan = invalid
  end if
End Function


' Handles render-tracking state changes to measure viewable impressions
'
' Lifecycle:
'   1. "full" or "partial" - item is on-screen: start visibility timer,
'      reset dwell accumulators
'   2. "none" - item left screen: if visible >= 1 s, build and fire the
'      impression event via m.global.viewableImpressionEventInfo
'
' The event payload uses trackingType "pivot" so ContentController routes it
' to the pivot aggregation path (components/utility_tiles) instead of the
' tile path (containers/contents).
'
' @param msg - roSGNodeEvent from observeFieldScoped("renderTracking") (unused;
'              state is read directly from m.top.renderTracking)
Function onPivotRenderTrackingChange(msg = invalid) as Void
  topRef = m.top
  renderState = topRef.renderTracking

  if renderState = "full" OR renderState = "partial"
    ' Item became visible — start timer only on the first transition.
    ' Subsequent "full" events while already visible are ignored.
    if m.itemVisibleTimespan = invalid
      m.itemVisibleTimespan = CreateObject("roTimespan")
      m.impressionDwellTime = 0
      m.itemFocusTimespan = invalid
    end if
  else if renderState = "none"
    ' Item left the screen — determine if it qualifies as a viewable impression
    if m.itemVisibleTimespan <> invalid
      duration = m.itemVisibleTimespan.totalMilliseconds()

      ' Only fire if visible for >= 1 second and we have a valid parent reference
      if duration >= 1000 AND m.parentTrackingNode <> invalid
        ' Finalize dwell_time: accumulated focus + any in-progress focus session
        dwellTime = m.impressionDwellTime
        if m.itemFocusTimespan <> invalid
          dwellTime = dwellTime + m.itemFocusTimespan.totalMilliseconds()
        end if

        ' Read page context from PivotList parent at fire time (not cached,
        ' so it always reflects the latest trackingPageInfo)
        trackingPageInfo = m.parentTrackingNode.trackingPageInfo

        ' Fire the viewable impression event via the global field.
        ' ContentController observes this field and aggregates the data.
        m.global.viewableImpressionEventInfo = {
          screenId: m.parentTrackingNode.parentScreenId
          trackingPageInfo: trackingPageInfo
          personalizationId: trackingPageInfo.pageValues.personalization_id
          clientTrackingInfo: {
            trackingType: "pivot"
            pivotId: m.pivotId
            col: m.pivotCol
            duration: duration
            dwell_time: dwellTime
          }
        }
      end if
    end if

    ' Reset all tracking state so the next visibility cycle starts clean
    m.itemVisibleTimespan = invalid
    m.impressionDwellTime = 0
    m.itemFocusTimespan = invalid
  end if
End Function
