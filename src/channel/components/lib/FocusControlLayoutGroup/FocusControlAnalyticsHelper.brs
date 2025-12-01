' FocusControlAnalyticsHelper.brs
' Helper functions for analytics tracking in FocusControlLayoutGroup and FocusControlGroup


' Initializes the analytics tracking helper
Function initFocusControlAnalytics() as Void
  constants = getConstantsFromGlobal()
  m.tracking = TubiTrackingInfo(constants)
End Function


' Hook method that handles focus change analytics tracking
'
' Extracts tracking context from components and emits navigation analytics event.
' Tracking context is retrieved from:
'   1. component.trackingContext (top-level field)
'   2. component.itemContent.trackingContext (fallback for grid items)
'
' Expected trackingContext structure:
'   {
'     type: String        - Component type (e.g., "middle_nav_component", "related_component")
'     values: AssocArray  - Component-specific values (e.g., { middle_nav_section: "PLAY" })
'   }
'
' @param sourceComponent - Component that is losing focus
' @param destComponent - Component that is gaining focus
' @param destIndex - Index of the destination component
Function onFocusControlFocusChange(sourceComponent as Dynamic, destComponent as Dynamic, destIndex as Integer) as Void
  trackingPageInfo = m.top.trackingPageInfo
  if not isValidForTracking(trackingPageInfo, sourceComponent, destComponent) then return

  ' Unwrap FocusControl components to get actual child components
  sourceComponent = unwrapFocusControl(sourceComponent)
  destComponent = unwrapFocusControl(destComponent)

  ' Get tracking context from both components
  sourceAnalytics = getTrackingContext(sourceComponent)
  destAnalytics = getTrackingContext(destComponent)
  if sourceAnalytics = invalid OR destAnalytics = invalid then return

  ' Build and emit navigation event
  m.top.navigateWithinPageEventInfo = {
    pageOneof: m.tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
    componentOneof: m.tracking.getAnalyticsComponent(sourceAnalytics.type, sourceAnalytics.values)
    dest_componentOneof: m.tracking.getAnalyticsDestinationComponent("dest_" + destAnalytics.type, destAnalytics.values)
    means_of_navigation: "SCROLL"
    vertical_location: destIndex + 1
    horizontal_location: 1
  }
End Function


' Validates if tracking should occur based on required fields
' @param trackingPageInfo - Tracking page information
' @param sourceComponent - Source component
' @param destComponent - Destination component
' @return Boolean - True if valid for tracking
Function isValidForTracking(trackingPageInfo as Dynamic, sourceComponent as Dynamic, destComponent as Dynamic) as Boolean
  if trackingPageInfo = invalid OR trackingPageInfo.pageType = invalid then return false
  if sourceComponent = invalid OR destComponent = invalid then return false
  if sourceComponent.isSameNode(destComponent) then return false
  return true
End Function


' Unwraps FocusControl components to get the actual gaining focus component
' @param component - Component to unwrap
' @return Dynamic - Unwrapped component or original component
Function unwrapFocusControl(component as Dynamic) as Dynamic
  if component = invalid then return component
  if component.isSubtype("FocusControlGroup") OR component.isSubtype("FocusControlLayoutGroup")
    return component.componentGainingFocus
  end if
  return component
End Function


' Gets tracking context from a component, checking both top level and itemContent
' @param component - Component to extract tracking context from
' @return Dynamic - Tracking context object or invalid
Function getTrackingContext(component as Dynamic) as Dynamic
  if component = invalid then return invalid

  ' Check top level first
  if component.trackingContext <> invalid then return component.trackingContext

  ' Fallback to itemContent
  if component.itemContent <> invalid AND component.itemContent.trackingContext <> invalid
    return component.itemContent.trackingContext
  end if

  return invalid
End Function

