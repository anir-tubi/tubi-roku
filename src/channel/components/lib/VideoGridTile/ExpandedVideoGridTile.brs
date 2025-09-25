Function init()
  topRef = m.top
  m.poster = topRef.findNode("Poster")
  m.videoInGridGradient = topRef.findNode("videoInGridGradient")
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("height", "onHeightChange")
  m.posterGroup = topRef.findNode("posterGroup")
  m.videoGridMetadataGroup = topRef.findNode("videoGridMetadataGroup")
  m.videoGridMetadata = topRef.findNode("videoGridMetadata")

  ' Creating a temporary poster that we will use to kind of pre-load the next poster to avoid having flash of grey when we navigate to the nex item.
  ' This should not cause any performance issues since roku caches images. since both posters use same url it will not re-download the image and not use extra memory.
  m.preloadPoster = createObject("roSGNode", "Poster")
  m.preloadPoster.observeFieldScoped("loadStatus", "onPreloadPosterLoadStatus")

  ' Pre-loading poster for the next item timer.
  ' This is purely a safety net to avoid having user think that his request is not being processed.
  ' If for some reason the poster is not loaded in time, we will show a grey poster and let the regular poster load.
  m.preloadPosterTimer = createObject("roSGNode", "Timer")
  m.preloadPosterTimer.duration = 0.2
  m.preloadPosterTimer.observeFieldScoped("fire", "onPreloadPosterTimerFire")

  m.metadataFadeDelay = 0.5
  m.animationDuration = 0

  experimentInfo = getStatsigExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v_1_6", false)
  if isAA(experimentInfo) = true
    m.variant = experimentInfo.variant
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    isBillboardRow = m.variant = "billboard" AND m.top.containerIndex = m.top.billboardContainerIndex

    if isBillboardRow = false
      m.videoInGridGradient.uri = "pkg:/images/video_in_grid_gradient_$$RES$$.9.png"
    else
      m.videoInGridGradient.uri = "pkg:/images/billboard-gradient-$$RES$$.webp"
    end if

    m.videoGridMetadataGroup.visible = true
    ' Resetting the blend color to default.
    m.poster.blendColor = "#FFFFFFFF"

    currentProgram = invalid
    if itemContent.type = "linear"
      currentProgram = getCurrentLiveProgram(itemContent)
    end if

    posterUri = ""
    if currentProgram <> invalid
      if isNonEmptyString(currentProgram.landscapePosterUrl) = true
        posterUri = currentProgram.landscapePosterUrl
      end if
    else if isNonEmptyString(itemContent.billboardImageUrl) AND isBillboardRow = true
      posterUri = itemContent.billboardImageUrl
    else if isNonEmptyString(itemContent.featuredLandscape) = true
      posterUri = itemContent.featuredLandscape
    else if isNonEmptyString(itemContent.landscape) = true
      posterUri = itemContent.landscape
    end if

    if isNonEmptyString(posterUri) = true
      m.preloadPoster.uri = posterUri
      m.preloadPosterTimer.control = "stop"
      m.preloadPosterTimer.control = "start"
    end if

    m.videoGridMetadata.opacity = 0
    if isBillboardRow = false
      fade(m.videoGridMetadata, "in", m.animationDuration, m.metadataFadeDelay)
      m.videoGridMetadata.itemContent = itemContent
    end if
    m.metadataFadeDelay = 0
  else
    m.videoGridMetadataGroup.visible = false
  end if
End Function


Function onPreloadPosterLoadStatus(msg)
  if msg.getData() = "ready"
    m.poster.uri = m.preloadPoster.uri
    m.preloadPoster.uri = ""
    m.preloadPosterTimer.control = "stop"
  end if
End Function


Function onHeightChange(msg)
  height = msg.getData()
  if height > 0
    m.videoInGridGradient.height = height
  end if
End Function


Function onPreloadPosterTimerFire(msg)
  if isNonEmptyString(m.preloadPoster.uri) = true
    ' If the image is taking more time to load switching to placeholder image until the image is loaded.
    m.poster.uri = "pkg:/images/placeholder-featured.webp"
  end if
End Function


Function onSkipAnimationChange(msg)
  skipAnimation = msg.getData()

  if skipAnimation = true
    m.animationDuration = 0
  else
    m.animationDuration = 0.3
  end if
End Function
