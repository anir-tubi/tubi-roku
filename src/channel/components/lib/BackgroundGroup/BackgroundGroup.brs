Function init()
  TubiLog("BackgroundGroup.init")
  m._ = rodash()
  m.constants = m.global.constants

  'set background info defaults
  m.top.backgroundInfo = {
    type: m.constants.ui.backgroundTypes.fullScreen
    uriList: [m.blurredDefaultBackground]
  }
  'this is a store that we can check against in order to prevent updateBackground logic from running when
  'm.top.lastBackgroundInfo is updated with the same info as before. "alwaysNotify" doesn't seem to work on assocArray fields
  m.lastBackgroundInfo = m.top.backgroundInfo
  m.top.observeField("backgroundInfo", "newBackgroundSet")

  m.fullScreenGradient = m.top.findNode("FullScreenGradient")
  m.topRightGradient = m.top.findNode("TopRightGradient")
  m.featureGradient = m.top.findNode("FeatureGradient")
  m.oldPoster = m.top.findNode("Poster1")  'the poster that is hidden (or transitioning to be hidden)
  m.newPoster = m.top.findNode("Poster2")  'the poster that is visible (or transitioning to be visible)
  m.oldBackgroundType = m.constants.ui.backgroundTypes.fullscreen  'set the default background type
  m.newBackgroundType = m.top.backgroundInfo.type

  m.blurredDefaultBackground = m.constants.ui.uris.defaultBackground
  m.isRotation = false

  m.timer = CreateObject("roSGNode", "Timer")
  m.timer.duration = 3

  ' Prevent artifacts when a parent node is faded in, which might cause
  ' the masked image to show through the gradient
  m.top.inheritParentOpacity = false
End Function


'Runs when the backgroundType has been set.
Function newBackgroundSet()
  TubiLog("BackgroundGroup.newBackgroundSet")

  'can't rely on alwaysNotify for m.top.uriList, so run our own logic to determine if the field value has actually changed
  isSame = true
  if type(m.lastBackgroundInfo.type) <> type(m.top.backgroundInfo.type) or m.lastBackgroundInfo.type <> m.top.backgroundInfo.type
    isSame = false
  else if m.lastBackgroundInfo.uriList.count() <> m.top.backgroundInfo.uriList.count()
    isSame = false
  else
    'types are the same and uriList counts are the same, so check if all elements in uriList are the same
    for i=0 to m.lastBackgroundInfo.count()-1
      if type(m.lastBackgroundInfo.uriList[i]) <> type(m.top.backgroundInfo.uriList[i]) or m.lastBackgroundInfo.uriList[i] <> m.top.backgroundInfo.uriList[i]
        isSame = false
        exit for
      end if
    end for
  end if

  if isSame = false
    m.timer.control = "stop"
    m.isRotation = false
    updateBackground(0)
    m.lastBackgroundInfo = m.top.backgroundInfo
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
  setPosterValues(m.top.backgroundInfo.uriList[uriIndex])

  'move newPoster to oldPoster, and switch oldPoster to be the newPoster now that it has the newest values
  tempPoster = m.newPoster
  m.newPoster = m.oldPoster
  m.oldPoster = tempPoster

  'update the old and new background types
  m.oldBackgroundType = m.newBackgroundType
  m.newBackgroundType = m.top.backgroundInfo.type

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
  if m.top.backgroundInfo.type = m.constants.ui.backgroundTypes.fullScreen or m.top.backgroundInfo.type = m.constants.ui.backgroundTypes.feature
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
  else if m.top.backgroundInfo.type = m.constants.ui.backgroundTypes.topRight
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
      m.oldPoster.fadeOutControl = "start"
      m.oldPoster.lastAnimationName = "FadeOut"

      if m.newPoster.loadStatus = "ready"
        'choose and start the correct transition based on the background type and/or presence of the default background uri
        startTransitionIn()

        'once the transition is complete we will want to start the timer for rotating background images
        m.newPoster.findNode(m.newPoster.lastAnimationName).observeField("state", "onTransitionComplete")
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
    if m.newPoster.uri = m.blurredDefaultBackground
      m.fullScreenGradient.gradientOpacity = 0.0
      m.topRightGradient.gradientOpacity = 0.0
      m.featureGradient.gradientOpacity = 0.0
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.fullScreen
      m.fullScreenGradient.gradientOpacity = 1.0
      m.topRightGradient.gradientOpacity = 0.0
      m.featureGradient.gradientOpacity = 0.0
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.topRight
      m.fullScreenGradient.gradientOpacity = 0.0
      m.topRightGradient.gradientOpacity = 1.0
      m.featureGradient.gradientOpacity = 0.0
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.feature
      m.fullScreenGradient.gradientOpacity = 0.0
      m.topRightGradient.gradientOpacity = 0.0
      m.featureGradient.gradientOpacity = 1.0
    end if
  else
    if m.newPoster.uri = m.blurredDefaultBackground
      if m.fullScreenGradient.gradientOpacity > 0.0
        m.fullScreenGradient.fadeOutControl = "start"
        m.fullScreenGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.topRightGradient.gradientOpacity > 0.0
        m.topRightGradient.fadeOutControl = "start"
        m.topRightGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.featureGradient.gradientOpacity > 0.0
        m.featureGradient.fadeOutControl = "start"
        m.featureGradient.lastAnimationName = "GradientFadeOut"
      end if
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.fullScreen
      if m.fullScreenGradient.gradientOpacity < 1.0
        m.fullScreenGradient.fadeInControl = "start"
        m.fullScreenGradient.lastAnimationName = "GradientFadeIn"
      end if
      if m.topRightGradient.gradientOpacity > 0.0
        m.topRightGradient.fadeOutControl = "start"
        m.topRightGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.featureGradient.gradientOpacity > 0.0
        m.featureGradient.fadeOutControl = "start"
        m.featureGradient.lastAnimationName = "GradientFadeOut"
      end if
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.feature
      if m.featureGradient.gradientOpacity < 1.0
        m.featureGradient.fadeInControl = "start"
        m.featureGradient.lastAnimationName = "GradientFadeIn"
      end if
      if m.fullScreenGradient.gradientOpacity > 0.0
        m.fullScreenGradient.fadeOutControl = "start"
        m.fullScreenGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.topRightGradient.gradientOpacity > 0.0
        m.topRightGradient.fadeOutControl = "start"
        m.topRightGradient.lastAnimationName = "GradientFadeOut"
      end if
    else if m.newBackgroundType = m.constants.ui.backgroundTypes.topRight
      'don't fade in the topRightGradient due to 2 reasons
      '1) if the old background poster was the default background, there is no gradient, so fading in the
      '   gradient while the topRight background poster fades in shows the edges of the topRight background
      '   poster since it is not full screen
      '2) when returning to the category screen from the details screen, the animation is clunky. Setting
      '   the value without animating it is an attempt to reduce the processing needed to run the animations.
      m.topRightGradient.gradientOpacity = 1.0
      if m.fullScreenGradient.gradientOpacity > 0.0
        m.fullScreenGradient.fadeOutControl = "start"
        m.fullScreenGradient.lastAnimationName = "GradientFadeOut"
      end if
      if m.featureGradient.gradientOpacity > 0.0
        m.featureGradient.fadeOutControl = "start"
        m.featureGradient.lastAnimationName = "GradientFadeOut"
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
    if m.newPoster.findNode(m.newPoster.lastAnimationName) <> invalid
      m.newPoster.findNode(m.newPoster.lastAnimationName).observeField("state", "onTransitionComplete")
    end if
  end if
End Function


'The transition animation has completed, so we use this callback to start the timer for rotating backgrounds.
Function onTransitionComplete()
  m.newPoster.findNode(m.newPoster.lastAnimationName).unobserveField("state")

  if m.top.backgroundInfo.uriList.count() > 1
    m.timer.observeField("fire", "rotateBackgrounds")
    m.timer.control = "start"
  end if
End Function


'Determines the next background image uri and makes call to update the background
Function rotateBackgrounds()
  m.timer.unobserveField("fire")

  currentIndex = 0
  currentIndex = m._.indexOf(m.top.backgroundInfo.uriList, m.newPoster.uri)

  nextIndex = 0
  if currentIndex + 1 < m.top.backgroundInfo.uriList.count()
    nextIndex = currentIndex + 1
  end if
  m.isRotation = true
  updateBackground(nextIndex)
End Function


'Choose the correct transition based on the background type and/or presence of the default background uri
Function startTransitionIn()
  if m.newPoster.uri = m.blurredDefaultBackground
    m.newPoster.fadeInControl = "start"
    m.newPoster.lastAnimationName = "FadeIn"
  else if m.newBackgroundType = m.constants.ui.backgroundTypes.topRight
    if m.oldBackgroundType = m.constants.ui.backgroundTypes.fullScreen and m.oldPoster.uri <> m.blurredDefaultBackground
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
  else if m.newBackgroundType = m.constants.ui.backgroundTypes.fullScreen
    m.newPoster.fullScreenTransitionInControl = "start"
    m.newPoster.lastAnimationName = "FullScreenTransitionIn"
  else if m.newBackgroundType = m.constants.ui.backgroundTypes.feature
    m.newPoster.fadeInControl = "start"
    m.newPoster.lastAnimationName = "FadeIn"
  end if
End Function