Function init()
  topRef = m.top
  m.poster = topRef.findNode("Poster")
  m.videoInGridGradient = topRef.findNode("videoInGridGradient")
  m.posterGroup = topRef.findNode("posterGroup")
  m.videoGridMetadataGroup = topRef.findNode("videoGridMetadataGroup")
  m.videoGridMetadata = topRef.findNode("videoGridMetadata")

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("height", "onHeightChange")
  topRef.observeFieldScoped("resetState", "onResetState")

  ' Creating a temporary poster that we will use to kind of pre-load the next poster to avoid having flash of grey when we navigate to the next item.
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
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    m.videoGridMetadataGroup.visible = true

    ' Limited UI mode: Remove poster and metadata elements to save memory
    if m.top.limitedUI = true
      removePosterAndMetadataElements()
    else if m.poster <> invalid AND m.videoGridMetadata <> invalid
      ' Full UI mode: Load poster and metadata
      ' Resetting the blend color to default.
      m.poster.blendColor = "#FFFFFFFF"

      posterUri = getPosterUri(itemContent)

      if isNonEmptyString(posterUri) = true
        m.preloadPoster.uri = posterUri
        m.preloadPosterTimer.control = "stop"
        m.preloadPosterTimer.control = "start"
      end if

      m.videoGridMetadata.opacity = 0
      fade(m.videoGridMetadata, "in", m.animationDuration, m.metadataFadeDelay)
      m.videoGridMetadata.itemContent = itemContent
      m.metadataFadeDelay = 0
    end if
  else
    m.videoGridMetadataGroup.visible = false
  end if
End Function


' Removes poster and metadata elements for limited UI mode to save memory
Function removePosterAndMetadataElements() as Void
  if m.poster <> invalid
    m.posterGroup.removeChild(m.poster)
    m.poster = invalid
  end if
  if m.videoGridMetadata <> invalid
    m.videoGridMetadataGroup.removeChild(m.videoGridMetadata)
    m.videoGridMetadata = invalid
  end if
End Function


' Gets the poster URI from item content, handling both linear and regular content
' @param itemContent - The content node containing poster information
' @return The poster URI string, or empty string if not found
Function getPosterUri(itemContent) as String
  currentProgram = invalid
  if itemContent.type = "linear"
    currentProgram = getCurrentLiveProgram(itemContent)
  end if

  posterUri = ""
  if currentProgram <> invalid
    if isNonEmptyString(currentProgram.landscapePosterUrl) = true
      posterUri = currentProgram.landscapePosterUrl
    end if
  else if isNonEmptyString(itemContent.featuredLandscape) = true
    posterUri = itemContent.featuredLandscape
  else if isNonEmptyString(itemContent.landscape) = true
    posterUri = itemContent.landscape
  end if

  return posterUri
End Function


Function onPreloadPosterLoadStatus(msg)
  if msg.getData() = "ready" AND m.poster <> invalid
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


Function onPreloadPosterTimerFire(_msg)
  if isNonEmptyString(m.preloadPoster.uri) = true AND m.poster <> invalid
    ' If the image is taking more time to load switching to placeholder image until the image is loaded.
    m.poster.uri = "pkg:/images/placeholder-featured.webp"
  end if
End Function


' Resets the tile state by clearing poster URIs and stopping any pending preload
Function onResetState(msg = invalid) as Void
  if m.poster <> invalid
    m.poster.uri = ""
  end if
  m.preloadPoster.uri = ""
  m.preloadPosterTimer.control = "stop"
End Function
