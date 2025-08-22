Function init()
  m.constants = getConstantsFromGlobal()
  topRef = m.top

  topRef.screenLevel = m.constants.ui.screenLevels.linearDetailScreen

  m.liveEventsContainer = topRef.findNode("liveEventsContainer")
  m.relatedContentContainer = topRef.findNode("relatedContentContainer")
  m.contentContainer = topRef.findNode("contentContainer")

  m.liveEventsContainer.translation = [m.constants.ui.translations.marginX, 140]
  m.relatedContentContainer.translation = [m.constants.ui.translations.marginX, 900]

  m.leftChevron = topRef.findNode("leftChevron")

  topRef.isStackable = true
  topRef.handlesTransportVoiceRequests = true

  topRef.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.relatedContentContainer.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  m.relatedContentContainer.observeFieldScoped("trackingComponentInfo", "onTrackingComponentInfoChange")
  topRef.observeFieldScoped("trackingPageInfo", "onTrackingPageInfoChange")
  m.liveEventsContainer.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
  m.animationDuration = 0.4
  m.lastFocusedChild = invalid
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true
    if m.lastFocusedChild <> invalid
      m.lastFocusedChild.setFocus(true)
    else
      m.liveEventsContainer.setFocus(true)
    end if
  end if

  content = m.top.content
  if content <> invalid
    m.top.backgroundUriList = content.backgrounds
  end if
End Function


Function focusRelatedContainer()
  m.relatedContentContainer.setFocus(true)
  m.lastFocusedChild = m.relatedContentContainer

  slideTo(m.contentContainer, [0, -392], m.animationDuration)
  animate(m.relatedContentContainer, { opacity: 1.0, duration: m.animationDuration })
  animate(m.liveEventsContainer, { opacity: 0.2, duration: m.animationDuration })
End Function


Function focusLiveEvents()
  m.liveEventsContainer.setFocus(true)
  m.lastFocusedChild = m.liveEventsContainer

  slideTo(m.contentContainer, [0, 0], m.animationDuration)
  animate(m.relatedContentContainer, { opacity: 0.2, duration: m.animationDuration })
  animate(m.liveEventsContainer, { opacity: 1.0, duration: m.animationDuration })
End Function


Function onNavigateWithinPageInfoChange(msg)
  m.top.navigateWithinPageInfo = msg.getData()
End Function


Function onTrackingComponentInfoChange(msg)
  m.top.trackingComponentInfo = msg.getData()
End Function


Function onTrackingPageInfoChange(msg)
  trackingPageInfo = msg.getData()
  m.relatedContentContainer.trackingPageInfo = trackingPageInfo
  m.liveEventsContainer.trackingPageInfo = trackingPageInfo
End Function


Function onComponentInteractionInfoChange(msg)
  ' Cannot use alias since the field is defined at base screen level.
  m.top.componentInteractionInfo = msg.getData()
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press = true
    if key = "left" OR key = "back"
      m.top.backButtonPressed = true
      return true
    else if key = "down"
      if m.relatedContentContainer.isInFocusChain() = false
        focusRelatedContainer()
        return true
      end if
    else if key = "up"
      if m.relatedContentContainer.isInFocusChain() = true
        focusLiveEvents()
        return true
      end if
    end if
  end if

  return false
End Function
