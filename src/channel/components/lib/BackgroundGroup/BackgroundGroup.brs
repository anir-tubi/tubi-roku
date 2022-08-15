Function init()
  TubiLog("BackgroundGroup.init")
  m._ = rodash()
  m.constants = m.global.constants

  m.blurredDefaultBackground = m.constants.ui.uris.defaultBackground
  m.blurredDefaultBackground_kidsMode = m.constants.ui.uris.kidsModeBackground
  '// The blurred background that we are currently using
  m.blurredDefaultBackground_current = m.blurredDefaultBackground

  'set background info defaults; the uriList is invalid at first. Must set the background to properly display background
  m.top.backgroundInfo = {
    type: m.constants.ui.backgroundTypes.fullScreen
    uriList: []
  }
  '//This is a store that we can use to change the current backgrounds. Like m.lastBackgroundInfo, we can update
  '// this variable and prevent the updateBackground() observer from being triggered.
  m.aCurrentBackgroundInfo = m.top.backgroundInfo
  'this is a store that we can check against in order to prevent updateBackground logic from running when
  'm.top.lastBackgroundInfo is updated with the same info as before. "alwaysNotify" doesn't seem to work on assocArray fields
  m.lastBackgroundInfo = m.top.backgroundInfo
  m.top.observeField("backgroundInfo", "newBackgroundSet")
  m.top.observeField("kidsMode", "onKidsModeChange")
  m.top.observeField("posterVisible", "onPosterVisibleChange")
  m.top.observeFieldScoped("shouldRotateBackgrounds", "onShouldRotateBackgroundsChange")

  m.PosterGroup = m.top.findNode("PosterGroup")
  m.GradientGroup = m.top.findNode("GradientGroup")
  m.fullScreenGradient = m.top.findNode("FullScreenGradient")
  m.topRightGradient = m.top.findNode("TopRightGradient")
  m.linearGradient1 = m.top.findNode("LinearGradient1")
  m.linearGradient2 = m.top.findNode("LinearGradient2")
  m.leftGradient = m.top.findNode("LeftGradient")

  m.leftBottomGradient = m.top.findNode("LeftBottomGradient")
  m.leftBottomGradient.uriList = ["pkg:/images/leftGradient.png", "pkg:/images/bottomGradient.png"]

  m.background = m.top.findNode("background")
  m.oldPoster = m.top.findNode("Poster1")  'the poster that is hidden (or transitioning to be hidden)
  m.newPoster = m.top.findNode("Poster2")  'the poster that is visible (or transitioning to be visible)
  m.oldBackgroundType = m.constants.ui.backgroundTypes.fullscreen  'set the default background type
  m.newBackgroundType = m.top.backgroundInfo.type

  m.isRotation = false

  m.timer = CreateObject("roSGNode", "Timer")
  m.timer.duration = 3

  ' Prevent artifacts when a parent node is faded in, which might cause
  ' the masked image to show through the gradient
  m.top.inheritParentOpacity = false
End Function


Function onKidsModeChange()
  if m.top.kidsMode = true
    m.fullScreenGradient.uri = m.constants.ui.uris.backgroundFullScreenGradient_kidsMode
    m.topRightGradient.uri = m.constants.ui.uris.backgroundTopRightGradient_kidsMode
    m.blurredDefaultBackground_current  = m.blurredDefaultBackground_kidsMode
  else
    m.fullScreenGradient.uri = m.constants.ui.uris.backgroundFullScreenGradient
    m.blurredDefaultBackground_current  = m.blurredDefaultBackground
  end if
  '//call newBackgroundSet() in case the kids mode change cause the default background is being used
  '//   and we need to change to appropriate default backround for the current mode.
  newBackgroundSet()
End Function


' Hide or display the background posters when posterVisible changes value
Function onPosterVisibleChange()
  sInOut = "in"
  if m.top.posterVisible = false
    sInOut = "out"
  end if
  fade(m.PosterGroup, sInOut, .5)
End Function


Function onShouldRotateBackgroundsChange(msg)
  if msg.getData() = true then
    startTimer()
  else
    stopTimer()
  end if
End Function


'Runs when the backgroundType has been set.
Function newBackgroundSet()
  TubiLog("BackgroundGroup.newBackgroundSet")

  ' reenable shouldRotateBackgrounds for simplicity
  m.top.shouldRotateBackgrounds = true

  m.aCurrentBackgroundInfo = m.top.backgroundInfo

  for i=0 to m.aCurrentBackgroundInfo.uriList.count()-1
    '//Modify the default background so the correct default background is used depending on the kids mode state
    if m.top.kidsMode = true and m.aCurrentBackgroundInfo.uriList[i] = m.blurredDefaultBackground
      m.aCurrentBackgroundInfo.uriList[i] = m.blurredDefaultBackground_kidsMode
    else if m.top.kidsMode = false and m.aCurrentBackgroundInfo.uriList[i] = m.blurredDefaultBackground_kidsMode
      m.aCurrentBackgroundInfo.uriList[i] = m.blurredDefaultBackground
    end if
  end for

  'can't rely on alwaysNotify for m.top.uriList, so run our own logic to determine if the field value has actually changed
  isSame = true
  if type(m.lastBackgroundInfo.type) <> type(m.aCurrentBackgroundInfo.type) or m.lastBackgroundInfo.type <> m.aCurrentBackgroundInfo.type
    isSame = false
  else if m.lastBackgroundInfo.uriList.count() <> m.aCurrentBackgroundInfo.uriList.count()
    isSame = false
  else
    'types are the same and uriList counts are the same, so check if all elements in uriList are the same
    for i=0 to m.lastBackgroundInfo.uriList.count()-1
      if type(m.lastBackgroundInfo.uriList[i]) <> type(m.aCurrentBackgroundInfo.uriList[i]) or m.lastBackgroundInfo.uriList[i] <> m.aCurrentBackgroundInfo.uriList[i]
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
  TubiLog("BackgroundGroup.updateBackground")
  'unobserve newPoster loadStatus in case we begin a new transition before the
  'onBackgroundPosterReady callback has run for the previous transition
  m.newPoster.unobserveField("loadStatus")

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

  'transition the gradients if necessary
  transitionGradients()

  'transition/fade out the old poster, transition/fade in the new poster
  transitionPosters()
End Function


'Jump to end of the most recent BackgroundPosterGroup and BackgroundGradientGroup animations
Function completePosterAnimations()
  posterGroups = [
    m.oldPoster
    m.newPoster
    m.topRightGradient
    m.fullScreenGradient
    m.leftBottomGradient
    m.leftGradient
  ]

  for each poster in posterGroups
    if poster.lastAnimationName <> invalid and poster.lastAnimationName <> ""
      animation = poster.findNode(poster.lastAnimationName)
      if animation.state = "running" or animation.state = "paused"
        animation.control = "finish"
      end if
    end if
  end for
End Function


'Set the poster values for height, width, translation depending on the type of poster
'@posterGroup: a BackgroundPosterGroup node
'@posterType: string, can be one of the background poster types as defined in constants ("fullscreen" or "topright")
'@posterUri: string, image uri to use for the background poster
Function setPosterValues(posterUri)
  if m.aCurrentBackgroundInfo.type = m.constants.ui.backgroundTypes.fullScreen
    m.oldPoster.width = 1920
    m.oldPoster.height = 1080
    m.oldPoster.posterTranslation = [0,0]
    if m.constants.deviceInfo.limitedUi = true
      ' Expecting background images to be 1920x1080, setting loadWidth/loadHeight causes:
      '  - VRAM usage 9% of unscaled (450K from 8MB)
      '  - load time comparable to unscaled image (no improvement but no worse, ~800ms on 3500X)
      '  - resampling of scaled image so it still looks acceptable
      m.oldPoster.loadWidth = "640"
      m.oldPoster.loadHeight = "360"
      m.oldPoster.loadDisplayMode = "scaleToZoom"
    else if m.constants.deviceInfo.lowVram = true
      m.oldPoster.loadWidth = "1280"
      m.oldPoster.loadHeight = "720"
      m.oldPoster.loadDisplayMode = "scaleToZoom"
    end if
  else if m.aCurrentBackgroundInfo.type = m.constants.ui.backgroundTypes.marketingScreen
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
  else if m.aCurrentBackgroundInfo.type = m.constants.ui.backgroundTypes.rightScreen
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
  else if m.aCurrentBackgroundInfo.type = m.constants.ui.backgroundTypes.topRight
    m.oldPoster.width = 1615
    m.oldPoster.height = 909
    m.oldPoster.posterTranslation = [305,0]
    if m.constants.deviceInfo.limitedUi = true
      m.oldPoster.loadWidth = "538"
      m.oldPoster.loadHeight = "303"
      m.oldPoster.loadDisplayMode = "scaleToZoom"
    else if m.constants.deviceInfo.lowVram = true
      m.oldPoster.loadWidth = "1077"
      m.oldPoster.loadHeight = "606"
      m.oldPoster.loadDisplayMode = "scaleToZoom"
    end if
  else if m.aCurrentBackgroundInfo.type = m.constants.ui.backgroundTypes.epg
    m.oldPoster.width = 1120
    m.oldPoster.height = 630
    m.oldPoster.posterTranslation = [800,0]
    if m.constants.deviceInfo.limitedUi = true
      m.oldPoster.loadWidth = "373"
      m.oldPoster.loadHeight = "210"
      m.oldPoster.loadDisplayMode = "scaleToZoom"
    else if m.constants.deviceInfo.lowVram = true
      m.oldPoster.loadWidth = "747"
      m.oldPoster.loadHeight = "420"
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
  TubiLog("BackgroundGroup.transitionPosters")
  'don't transition if nothing has changed
  if m.newPoster.uri <> m.oldPoster.uri or m.oldBackgroundType <> m.newBackgroundType

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
          lastAnimationNode.observeField("state", "onTransitionComplete")
        end if
      else
        'set observer/callback to select and start the transition animation if the poster is not yet ready
        m.newPoster.observeField("loadStatus", "onBackgroundPosterReady")
      end if
    end if
  end if
End Function


'Transition the background gradients if necessary so the background gradient fits the new background type
Function transitionGradients()
  if m.constants.deviceInfo.limitedUi = true
    if m.newPoster.uri = m.blurredDefaultBackground_current
      m.fullScreenGradient.gradientOpacity = 0.0
      m.leftBottomGradient.gradientOpacity = 0.0
      m.linearGradient1.gradientOpacity = 0.0
      m.linearGradient2.gradientOpacity = 0.0
      m.topRightGradient.gradientOpacity = 0.0
      m.leftGradient.gradientOpacity = 0.0
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.fullScreen
      m.fullScreenGradient.gradientOpacity = 1.0
      m.leftBottomGradient.gradientOpacity = 0.0
      m.linearGradient1.gradientOpacity = 0.0
      m.linearGradient2.gradientOpacity = 0.0
      m.topRightGradient.gradientOpacity = 0.0
      m.leftGradient.gradientOpacity = 0.0
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.topRight
      m.linearGradient1.gradientOpacity = 0.0
      m.linearGradient2.gradientOpacity = 0.0
      m.fullScreenGradient.gradientOpacity = 0.0
      m.leftGradient.gradientOpacity = 0.0
      if m.top.kidsMode = true
        m.leftBottomGradient.gradientOpacity = 0.0
        m.topRightGradient.gradientOpacity = 1.0
      else
        m.topRightGradient.gradientOpacity = 0.0
        m.leftBottomGradient.gradientOpacity = 1.0
      end if
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.rightScreen
      m.linearGradient1.gradientOpacity = 0.0
      m.linearGradient2.gradientOpacity = 0.0
      m.fullScreenGradient.gradientOpacity = 0.0
      m.topRightGradient.gradientOpacity = 0.0
      m.leftGradient.gradientOpacity = 1.0
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.epg
      m.fullScreenGradient.gradientOpacity = 0.0
      m.leftBottomGradient.gradientOpacity = 0.0
      m.topRightGradient.gradientOpacity = 0.0
      m.leftGradient.gradientOpacity = 0.0
      m.linearGradient1.uri = "pkg:/images/horizGradientEPG.png"
      m.linearGradient2.uri = "pkg:/images/vertGradientEPG.png"
      if m.top.kidsMode = true
        m.linearGradient1.gradientBlendColor = m.constants.ui.themes.kidsMode.gradientBlendColor
        m.linearGradient2.gradientBlendColor = m.constants.ui.themes.kidsMode.gradientBlendColor
      else
        m.linearGradient1.gradientBlendColor = m.constants.ui.themes.default.gradientBlendColor
        m.linearGradient2.gradientBlendColor = m.constants.ui.themes.default.gradientBlendColor
      end if

      m.linearGradient1.gradientOpacity = 1.0
      m.linearGradient2.gradientOpacity = 1.0
    end if
  else
    '//Stop gradients to allow them to start again
    m.fullScreenGradient.fadeOutControl = "stop"
    m.linearGradient1.fadeOutControl = "stop"
    m.linearGradient2.fadeOutControl = "stop"
    m.leftBottomGradient.fadeOutControl = "stop"
    m.topRightGradient.fadeOutControl = "stop"
    m.leftGradient.fadeOutControl = "stop"
    if m.newPoster.uri = m.blurredDefaultBackground_current
      if m.fullScreenGradient.gradientOpacity > 0.0
        m.fullScreenGradient.fadeOutControl = "start"
        m.fullScreenGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.linearGradient1.gradientOpacity > 0.0
        m.linearGradient1.fadeOutControl = "start"
        m.linearGradient1.lastAnimationName = "GradientFadeOut"
      end if
      if m.linearGradient2.gradientOpacity > 0.0
        m.linearGradient2.fadeOutControl = "start"
        m.linearGradient2.lastAnimationName = "GradientFadeOut"
      end if
      if m.leftBottomGradient.gradientOpacity > 0.0
        m.leftBottomGradient.fadeOutControl = "start"
        m.leftBottomGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.topRightGradient.gradientOpacity > 0.0
        m.topRightGradient.fadeOutControl = "start"
        m.topRightGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.leftGradient.gradientOpacity > 0.0
        m.leftGradient.fadeOutControl = "start"
        m.leftGradient.lastAnimationName = "GradientFadeOut"
      end if
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.fullScreen
      if m.fullScreenGradient.gradientOpacity < 1.0
        m.fullScreenGradient.fadeInControl = "start"
        m.fullScreenGradient.lastAnimationName = "GradientFadeIn"
      end if
      if m.linearGradient1.gradientOpacity > 0.0
        m.linearGradient1.fadeOutControl = "start"
        m.linearGradient1.lastAnimationName = "GradientFadeOut"
      end if
      if m.linearGradient2.gradientOpacity > 0.0
        m.linearGradient2.fadeOutControl = "start"
        m.linearGradient2.lastAnimationName = "GradientFadeOut"
      end if
      if m.leftBottomGradient.gradientOpacity > 0.0
        m.leftBottomGradient.fadeOutControl = "start"
        m.leftBottomGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.topRightGradient.gradientOpacity > 0.0
        m.topRightGradient.fadeOutControl = "start"
        m.topRightGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.leftGradient.gradientOpacity > 0.0
        m.leftGradient.fadeOutControl = "start"
        m.leftGradient.lastAnimationName = "GradientFadeOut"
      end if
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.marketingScreen
      if m.leftBottomGradient.gradientOpacity > 0.0
        m.leftBottomGradient.fadeOutControl = "start"
        m.leftBottomGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.fullScreenGradient.gradientOpacity > 0.0
        m.fullScreenGradient.fadeOutControl = "start"
        m.fullScreenGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.linearGradient1.gradientOpacity > 0.0
        m.linearGradient1.fadeOutControl = "start"
        m.linearGradient1.lastAnimationName = "GradientFadeOut"
      end if
      if m.linearGradient2.gradientOpacity > 0.0
        m.linearGradient2.fadeOutControl = "start"
        m.linearGradient2.lastAnimationName = "GradientFadeOut"
      end if
      if m.topRightGradient.gradientOpacity > 0.0
        m.topRightGradient.fadeOutControl = "start"
        m.topRightGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.leftGradient.gradientOpacity > 0.0
        m.leftGradient.fadeOutControl = "start"
        m.leftGradient.lastAnimationName = "GradientFadeOut"
      end if
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.topRight
      'don't fade in the topRightGradient due to 2 reasons
      '1) if the old background poster was the default background, there is no gradient, so fading in the
      '   gradient while the topRight background poster fades in shows the edges of the topRight background
      '   poster since it is not full screen
      '2) when returning to the category screen from the details screen, the animation is clunky. Setting
      '   the value without animating it is an attempt to reduce the processing needed to run the animations.
      if m.top.kidsMode = true
        m.topRightGradient.gradientOpacity = 1.0
      else
        m.leftBottomGradient.gradientOpacity = 1.0
      end if
      if m.fullScreenGradient.gradientOpacity > 0.0
        m.fullScreenGradient.fadeOutControl = "start"
        m.fullScreenGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.linearGradient1.gradientOpacity > 0.0
        m.linearGradient1.fadeOutControl = "start"
        m.linearGradient1.lastAnimationName = "GradientFadeOut"
      end if
      if m.linearGradient2.gradientOpacity > 0.0
        m.linearGradient2.fadeOutControl = "start"
        m.linearGradient2.lastAnimationName = "GradientFadeOut"
      end if
      if m.leftGradient.gradientOpacity > 0.0
        m.leftGradient.fadeOutControl = "start"
        m.leftGradient.lastAnimationName = "GradientFadeOut"
      end if
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.rightScreen
      m.leftGradient.gradientOpacity = 1.0
      if m.fullScreenGradient.gradientOpacity > 0.0
        m.fullScreenGradient.fadeOutControl = "start"
        m.fullScreenGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.linearGradient1.gradientOpacity > 0.0
        m.linearGradient1.fadeOutControl = "start"
        m.linearGradient1.lastAnimationName = "GradientFadeOut"
      end if
      if m.linearGradient2.gradientOpacity > 0.0
        m.linearGradient2.fadeOutControl = "start"
        m.linearGradient2.lastAnimationName = "GradientFadeOut"
      end if
      if m.topRightGradient.gradientOpacity > 0.0
        m.topRightGradient.fadeOutControl = "start"
        m.topRightGradient.lastAnimationName = "GradientFadeOut"
      end if
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.epg
      'don't fade in the linearGradient due to 2 reasons
      '1) if the old background poster was the default background, there is no gradient, so fading in the
      '   gradient while the linear background poster fades in shows the edges of the linear background
      '   poster since it is not full screen
      '2) when returning to the category screen from the details screen, the animation is clunky. Setting
      '   the value without animating it is an attempt to reduce the processing needed to run the animations.
      m.linearGradient1.uri = "pkg:/images/horizGradientEPG.png"
      m.linearGradient2.uri = "pkg:/images/vertGradientEPG.png"
      if m.top.kidsMode = true
        m.linearGradient1.gradientBlendColor = m.constants.ui.themes.kidsMode.gradientBlendColor
        m.linearGradient2.gradientBlendColor = m.constants.ui.themes.kidsMode.gradientBlendColor
      else
        m.linearGradient1.gradientBlendColor = m.constants.ui.themes.default.gradientBlendColor
        m.linearGradient2.gradientBlendColor = m.constants.ui.themes.default.gradientBlendColor
      end if
      m.linearGradient1.gradientOpacity = 1.0
      m.linearGradient2.gradientOpacity = 1.0
      if m.fullScreenGradient.gradientOpacity > 0.0
        m.fullScreenGradient.fadeOutControl = "start"
        m.fullScreenGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.leftBottomGradient.gradientOpacity > 0.0
        m.leftBottomGradient.fadeOutControl = "start"
        m.leftBottomGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.topRightGradient.gradientOpacity > 0.0
        m.topRightGradient.fadeOutControl = "start"
        m.topRightGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.leftGradient.gradientOpacity > 0.0
        m.leftGradient.fadeOutControl = "start"
        m.leftGradient.lastAnimationName = "GradientFadeOut"
      end if
    end if
  end if
End Function


'The background image wasn't loaded when we wanted to start the transition, so we run this callback when it becomes ready
Function onBackgroundPosterReady()
  if m.newPoster.loadStatus = "ready"
    m.newPoster.unobserveField("loadStatus")
    startTransitionIn()

    'once the transition is complete we will want to start the timer for rotating background images
    node = m.newPoster.findNode(m.newPoster.lastAnimationName)
    if node <> invalid
      node.observeField("state", "onTransitionComplete")
    end if
  end if
End Function


'The transition animation has completed, so we use this callback to start the timer for rotating backgrounds.
Function onTransitionComplete()
  m.newPoster.findNode(m.newPoster.lastAnimationName).unobserveField("state")

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
  if m.newPoster.uri = m.blurredDefaultBackground_current
    m.newPoster.fadeInControl = "start"
    m.newPoster.lastAnimationName = "FadeIn"
  else if m.newBackgroundType = m.constants.ui.backgroundTypes.topRight
    if m.oldBackgroundType = m.constants.ui.backgroundTypes.fullScreen and m.oldPoster.uri <> m.blurredDefaultBackground_current
      'moving from detail screen to category screen is clunky, so try to reduce the amount of animations
      m.newPoster.posterOpacity = 1.0
    else if m.isRotation = true
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
  else if m.newBackgroundType = m.constants.ui.backgroundTypes.marketingScreen
    m.newPoster.fullScreenTransitionInControl = "start"
    m.newPoster.lastAnimationName = "FullScreenTransitionIn"
  else if m.newBackgroundType = m.constants.ui.backgroundTypes.rightScreen
    m.newPoster.fullScreenTransitionInControl = "start"
    m.newPoster.lastAnimationName = "FullScreenTransitionIn"
  end if
End Function
