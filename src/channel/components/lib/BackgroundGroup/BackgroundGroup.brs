Function init()
  topRef = m.top
  m.constants = getConstantsFromGlobal()
  m._ = rodash()

  topRef.observeFieldScoped("kidsMode", "onKidsModeChange")
  topRef.observeFieldScoped("posterVisible", "onPosterVisibleChange")
  topRef.observeFieldScoped("shouldRotateBackgrounds", "onShouldRotateBackgroundsChange")
  'set background info defaults; the uriList is invalid at first. Must set the background to properly display background
  topRef.backgroundInfo = {
    type: m.constants.ui.backgroundTypes.fullScreen
    uriList: []
  }
  '//This is a store that we can use to change the current backgrounds. Like m.lastBackgroundInfo, we can update
  '// this variable and prevent the updateBackground() observer from being triggered.
  m.aCurrentBackgroundInfo = topRef.backgroundInfo
  'this is a store that we can check against in order to prevent updateBackground logic from running when
  'm.top.lastBackgroundInfo is updated with the same info as before. "alwaysNotify" doesn't seem to work on assocArray fields
  m.lastBackgroundInfo = topRef.backgroundInfo
  topRef.observeField("backgroundInfo", "newBackgroundSet")

  m.topRightContentPosterGroup = topRef.findNode("topRightContentPosterGroup")
  m.oldPoster = topRef.findNode("poster1")  'the poster that is hidden (or transitioning to be hidden)
  m.newPoster = topRef.findNode("poster2")  'the poster that is visible (or transitioning to be visible)
  m.oldBackgroundType = m.constants.ui.backgroundTypes.fullscreen  'set the default background type
  m.newBackgroundType = topRef.backgroundInfo.type
  m.isRotation = false


  m.circularMaskLayer = topRef.findNode("circularMaskLayer")
  m.defaultBackground = topRef.findNode("defaultBackground")
  m.posterGroupMask = topRef.findNode("posterGroupMask")
  m.maskLayer10 = topRef.findNode("maskLayer10")
  m.maskLayer11 = topRef.findNode("maskLayer11")
  m.maskLayer2 = topRef.findNode("maskLayer2")

  m.timer = CreateObject("roSGNode", "Timer")
  m.timer.duration = 3

  setMaskLayerUris()
  ' Prevent artifacts when a parent node is faded in, which might cause the masked image to show through the gradient. 
  m.top.inheritParentOpacity = false
End Function


Function onKidsModeChange()
  setMaskLayerUris()
  newBackgroundSet()
End Function


Function setMaskLayerUris()
  if m.top.kidsMode = true
    m.posterGroupMask.uri = "pkg:/images/background-masks/mask-layer-0-kids.webp"
    m.defaultBackground.uri = "pkg:/images/background-masks/mask-layer-1-0-kids.webp"
    m.maskLayer10.uri = "pkg:/images/background-masks/mask-layer-1-0-kids.webp"
    m.maskLayer11.uri = "pkg:/images/background-masks/mask-layer-1-1-kids.webp"
    m.maskLayer2.uri = "pkg:/images/background-masks/mask-layer-2-kids.webp"
  else
    m.posterGroupMask.uri = "pkg:/images/background-masks/mask-layer-0.webp"
    m.defaultBackground.uri = "pkg:/images/background-masks/mask-layer-1-0.webp"
    m.maskLayer10.uri = "pkg:/images/background-masks/mask-layer-1-0.webp"
    m.maskLayer11.uri = "pkg:/images/background-masks/mask-layer-1-1.webp"
    m.maskLayer2.uri = "pkg:/images/background-masks/mask-layer-2.webp"
  end if
End Function


' Hide or display the background posters when posterVisible changes value
Function onPosterVisibleChange(msg)
  posterVisible = msg.getData()
  animationType = "in"
  if posterVisible = false
    animationType = "out"
  end if

  fade(m.topRightContentPosterGroup, animationType, 0.5)
End Function


Function onShouldRotateBackgroundsChange(msg)
  shouldRotateBackgrounds = msg.getData()
  if shouldRotateBackgrounds = true then
    startTimer()
  else
    stopTimer()
  end if
End Function



'Runs when the backgroundType has been set.
Function newBackgroundSet()
  ' reenable shouldRotateBackgrounds for simplicity
  m.top.shouldRotateBackgrounds = true

  m.aCurrentBackgroundInfo = m.top.backgroundInfo
  if m.lastBackgroundInfo <> invalid AND m.aCurrentBackgroundInfo <> invalid AND m.lastBackgroundInfo.type <> m.aCurrentBackgroundInfo.type
    if m.aCurrentBackgroundInfo.type = m.constants.ui.backgroundTypes.fullScreen
      fade(m.circularMaskLayer, "out", 0.5)
      fade(m.posterGroupMask, "out", 0.5)
      fade(m.defaultBackground, "in", 0.5)
    else
      fade(m.defaultBackground, "out", 0.5)
      fade(m.circularMaskLayer, "in", 0.5)
      ' Showing the poster group. Posters will automatically animate with width shrink effect due to update in the background info.
      fade(m.posterGroupMask, "in", 0.5)
    end if
  end if
  

  'can't rely on alwaysNotify for m.top.uriList, so run our own logic to determine if the field value has actually changed
  isSame = true
  if type(m.lastBackgroundInfo.type) <> type(m.aCurrentBackgroundInfo.type) OR m.lastBackgroundInfo.type <> m.aCurrentBackgroundInfo.type
    isSame = false
  else if m.lastBackgroundInfo.uriList.count() <> m.aCurrentBackgroundInfo.uriList.count()
    isSame = false
  else
    'types are the same and uriList counts are the same, so check if all elements in uriList are the same
    for i=0 to m.lastBackgroundInfo.uriList.count()-1
      if type(m.lastBackgroundInfo.uriList[i]) <> type(m.aCurrentBackgroundInfo.uriList[i]) OR m.lastBackgroundInfo.uriList[i] <> m.aCurrentBackgroundInfo.uriList[i]
        isSame = false
        exit for
      end if
    end for
  end if

  if isSame = false
    stopTimer()
    m.isRotation = false
    updateBackground(0)
    m.lastBackgroundInfo = m.aCurrentBackgroundInfo
  end if
End Function


'Does the all the necessary steps to update the background image
'@uriIndex: integer, the index of the uri in the uriList
Function updateBackground(uriIndex)
  'unobserve newPoster loadStatus in case we begin a new transition before the
  'onBackgroundPosterReady callback has run for the previous transition
  m.newPoster.unobserveFieldScoped("loadStatus")

  'stop any current transitions/fades
  completePosterAnimations()

  'set the "old" or "hidden" poster with the new poster uri and size (if necessary)
  setPosterValues(m.aCurrentBackgroundInfo.uriList[uriIndex])

  'move newPoster to oldPoster, and switch oldPoster to be the newPoster now that it has the newest values
  tempPoster = m.newPoster
  m.newPoster = m.oldPoster
  m.oldPoster = tempPoster

  'update the old and new background types
  m.oldBackgroundType = m.newBackgroundType
  m.newBackgroundType = m.aCurrentBackgroundInfo.type

  'transition/fade out the old poster, transition/fade in the new poster
  transitionPosters()
End Function


'Jump to end of the most recent BackgroundPosterGroup animations
Function completePosterAnimations()
  posterGroups = [
    m.oldPoster
    m.newPoster
  ]

  for each poster in posterGroups
    if poster.lastAnimationName <> invalid AND poster.lastAnimationName <> ""
      animation = poster.findNode(poster.lastAnimationName)
      if animation.state = "running" OR animation.state = "paused"
        animation.control = "finish"
      end if
    end if
  end for
End Function


'Set the poster values for height, width, translation depending on the type of poster
'@posterUri: string, image uri to use for the background poster
Function setPosterValues(posterUri)
  if m.aCurrentBackgroundInfo.type = m.constants.ui.backgroundTypes.topRight
    m.oldPoster.width = 1197
    m.oldPoster.height = 675
    m.oldPoster.posterTranslation = [804,0]
    if m.constants.deviceInfo.limitedUi = true OR m.constants.deviceInfo.lowVram = true
      m.oldPoster.loadDisplayMode = "scaleToZoom"
    end if
  else
    ' else block handles the case where we display full screen single gradient background.
    m.oldPoster.width = 1920
    m.oldPoster.height = 1080
    m.oldPoster.posterTranslation = [0,0]
    if m.constants.deviceInfo.limitedUi = true
      m.oldPoster.loadWidth = "640"
      m.oldPoster.loadHeight = "360"
      m.oldPoster.loadDisplayMode = "scaleToZoom"
    else if m.constants.deviceInfo.lowVram = true
      m.oldPoster.loadWidth = "1280"
      m.oldPoster.loadHeight = "720"
      m.oldPoster.loadDisplayMode = "scaleToZoom"
    end if
  end if

  if posterUri <> invalid
    m.oldPoster.uri = posterUri
  else
    m.oldPoster.uri = ""
  end if
End Function


'Do the appropriate transition for the poster. Take into account if the device should have a limited version of backgrounds
Function transitionPosters()
  'don't transition if nothing has changed
  if m.newPoster.uri <> m.oldPoster.uri OR m.oldBackgroundType <> m.newBackgroundType

    'Determine if the animation should be skipped due to limitedUi
    if m.constants.deviceInfo.limitedUi = true
      m.newPoster.posterOpacity = 1.0
      m.oldPoster.posterOpacity = 0.0
    else
      'use the full transitions since we are not limited
      'case 1) uris are the same, backgroundType has changed (ie. moving from category screen to details screen or vice versa)
      'case 2) uris are different, backgroundType is same (ie. scrolling around the category screen)
      'case 3) uris are different, background type has changed (ie. moving from category grid to category list)
      m.oldPoster.fadeOutControl = "stop"
      m.oldPoster.fadeOutControl = "start"
      m.oldPoster.lastAnimationName = "FadeOut"

      if m.newPoster.loadStatus = "ready"
        'choose and start the correct transition based on the background type and/or presence of the default background uri
        startTransitionIn()

        'once the transition is complete we will want to start the timer for rotating background images
        lastAnimationNode = m.newPoster.findNode(m.newPoster.lastAnimationName)
        if lastAnimationNode = invalid
          tubiLog("Node could not be found for lastAnimationName: " + m.newPoster.lastAnimationName, "warn")
        else
          lastAnimationNode.observeFieldScoped("state", "onTransitionComplete")
        end if
      else
        'set observer/callback to select and start the transition animation if the poster is not yet ready
        m.newPoster.observeFieldScoped("loadStatus", "onBackgroundPosterReady")
      end if
    end if
  end if
End Function


'The background image wasn't loaded when we wanted to start the transition, so we run this callback when it becomes ready
Function onBackgroundPosterReady()
  if m.newPoster.loadStatus = "ready"
    m.newPoster.unobserveFieldScoped("loadStatus")
    startTransitionIn()

    'once the transition is complete we will want to start the timer for rotating background images
    node = m.newPoster.findNode(m.newPoster.lastAnimationName)
    if node <> invalid
      node.observeFieldScoped("state", "onTransitionComplete")
    end if
  end if
End Function


'The transition animation has completed, so we use this callback to start the timer for rotating backgrounds.
Function onTransitionComplete()
  m.newPoster.findNode(m.newPoster.lastAnimationName).unobserveFieldScoped("state")

  if m.aCurrentBackgroundInfo.uriList.count() > 1 AND m.top.shouldRotateBackgrounds = true then
    startTimer()
  end if
End Function


Function startTimer()
  stopTimer()
  m.timer.observeFieldScoped("fire", "onTimerFired")
  m.timer.control = "start"
End Function


Function stopTimer()
  m.timer.unobserveFieldScoped("fire")
  m.timer.control = "stop"
End Function


'Determines the next background image uri and makes call to update the background
Function onTimerFired()
  stopTimer()
  currentIndex = m._.indexOf(m.aCurrentBackgroundInfo.uriList, m.newPoster.uri)
  nextIndex = 0
  if currentIndex + 1 < m.aCurrentBackgroundInfo.uriList.count()
    nextIndex = currentIndex + 1
  end if
  m.isRotation = true
  updateBackground(nextIndex)
End Function


'Choose the correct transition based on the background type and/or presence of the default background uri
Function startTransitionIn()
  m.newPoster.fadeInControl = "stop"
  if m.newBackgroundType = m.constants.ui.backgroundTypes.topRight
    if m.isRotation = true
      'rotating posters just have a cross fade
      m.newPoster.fadeInControl = "start"
      m.newPoster.lastAnimationName = "FadeIn"
    else
      'default case (like moving between posters in category screen)
      m.newPoster.topRightTransitionInControl = "start"
      m.newPoster.lastAnimationName = "TopRightTransitionIn"
    end if
  else if m.newBackgroundType = m.constants.ui.backgroundTypes.epg
    m.newPoster.epgTransitionInControl = "start"
    m.newPoster.lastAnimationName = "epgTransitionIn"
  else if m.newBackgroundType = m.constants.ui.backgroundTypes.fullScreen
    m.newPoster.fullScreenTransitionInControl = "start"
    m.newPoster.lastAnimationName = "FullScreenTransitionIn"
  else if m.newBackgroundType = m.constants.ui.backgroundTypes.rightScreen
    m.newPoster.fullScreenTransitionInControl = "start"
    m.newPoster.lastAnimationName = "FullScreenTransitionIn"
  end if
End Function
