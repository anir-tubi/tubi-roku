Function init()
  m.constants = getConstantsFromGlobal()
  m.carouselLayout = m.top.findNode("carouselLayout")
  m.focusTimer = m.top.findNode("focusTimer")
  m.sideImage = m.top.findNode("sideImage")
  m.sideImageSpacer = m.top.findNode("sideImageSpacer") '//Since the sideImage can be any size up to nSideImageHeight, this spacer is used to ensure the space from the "Ad" indicator to the title is always the same
  m.title = m.top.findNode("title")
  m.adIndicator = m.top.findNode("adIndicator")
  m.carouselGrid = m.top.findNode("carouselGrid")

  m.focusTimer.duration = 10
  m.focusTimer.observeFieldScoped("fire", "onFocusTimerFire")
  m.bTileNavigatedAutomatically = false '//Flag to indicate if the user has automatically navigated to a tile of the carousel.

  nSideImageWidth = 600
  nSideImageHeight = 300
  m.sideImageSpacer.height = nSideImageHeight
  m.sideImage.loadHeight = nSideImageHeight
  m.sideImage.loadWidth = nSideImageWidth

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.adIndicator, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMediumStrong)
  m.adIndicator.text = getTranslation("ad")
  m.carouselGrid.itemSize = m.constants.ui.imageSizes.adRowlistCarouselThumbnail
  m.carouselGrid.observeFieldScoped("itemFocused", "onItemFocused")

  m.top.observeFieldScoped("allowCarouselAutoRotate", "onRotateFieldChanged")
  m.top.observeFieldScoped("updateContent", "onContentChange")
  m.top.observeFieldScoped("focusedChild", "onComponentFocusChange")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.carouselGrid.focusBitmapBlendColor = theme.focusedColor
    m.adIndicator.fontColor = theme.backgroundColor
  end if
End Function


Function onContentChange(msg)
  tubiLog("AdDisplayCarousel.onContentChange")
  content = m.top.content
  if content <> invalid
    m.title.text = content.title
    if isNonEmptyString(content.titleImageUrl) = true
      m.sideImage.uri = content.titleImageUrl
    end if

    gridContent = CreateObject("roSGNode", "ContentNode")
    nCarouselCount = content.carousel.Count()
    gridContent.appendChildren(content.carousel)

    if nCarouselCount > 0
      '//Add the video preview URL to the first item in the gridContent
      if isNonEmptyString(content.videoPreviewUrl) = true
        gridContent.getChild(0).videoPreviewUrl = content.videoPreviewUrl
      end if

      '//Add the processed adInfo to the first item in the gridContent
      if content.adInfoProcessed <> invalid
        gridContent.getChild(0).adInfoProcessed = content.adInfoProcessed
      end if
    end if

    '//Because the layoutGroup is bottom aligned, the layoutGroup's origin is at the bottom of the layoutGroup.
    '//Thus, we need to take the layoutGroup's height and add it to the desired Y position
    nY = 78 + m.carouselLayout.boundingRect().height
    m.carouselLayout.translation = [m.constants.ui.translations.marginX, nY]

    m.carouselGrid.content = gridContent
    nVisibleCount = minValue(nCarouselCount, m.carouselGrid.numColumns)
    nGridWidth = nVisibleCount * m.constants.ui.imageSizes.adRowlistCarouselThumbnail[0] + (nVisibleCount - 1) * m.carouselGrid.itemSpacing[0]
    nRightEdge = 1752
    nYGrid = nY - m.constants.ui.imageSizes.adRowlistCarouselThumbnail[1]
    m.carouselGrid.translation = [nRightEdge - nGridWidth, nYGrid]
  end if
End Function


Function onComponentFocusChange()
  tubiLog("AdDisplayCarousel.onComponentFocusChange")
  if m.top.hasFocus() = true
    m.carouselGrid.setFocus(true)
  else if m.top.isInFocusChain() = false
    '//Reset the row back to the first item when the component loses focus
    m.carouselGrid.jumpToItem = 0
  end if
End Function


Function onRotateFieldChanged(msg)
  tubiLog("AdDisplayCarousel.onRotateFieldChanged")
  if m.top.allowCarouselAutoRotate = true
    m.focusTimer.control = "start"
  else
    m.focusTimer.control = "stop"
  end if
End Function


Function onItemFocused(msg)
  tubiLog("AdDisplayCarousel.onItemFocused")
  index = msg.getData()
  item = m.carouselGrid.content.getChild(index)
  if item <> invalid
    if isNonEmptyString(item.videoPreviewUrl) = false
      m.top.allowCarouselAutoRotate = true
      m.focusTimer.control = "start"
    else
      m.top.allowCarouselAutoRotate = false
      m.focusTimer.control = "stop"
    end if

    m.top.contentFocused = item

    if m.bTileNavigatedAutomatically = false
      '//report that the user has manually navigated the carousel
      m.top.tileManuallyNavigated = true
    end if
    m.bTileNavigatedAutomatically = false '//reset the flag for next time

  end if
End Function


Function onFocusTimerFire()
  tubiLog("AdDisplayCarousel.onFocusTimerFire")
  if m.carouselGrid.isInFocusChain() = true AND m.top.allowCarouselAutoRotate = true
    currentFocusedIndex = m.carouselGrid.itemFocused
    if currentFocusedIndex >= m.carouselGrid.content.getChildCount() - 1
      '//If the user is at the end of the carousel, loop back to the first item
      newFocusedIndex = 0
    else
      '//Otherwise, focus on the next item in the carousel
      newFocusedIndex = currentFocusedIndex + 1
    end if
    m.bTileNavigatedAutomatically = true
    m.carouselGrid.animateToItem = newFocusedIndex
  end if
End Function


''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key as String, press as Boolean) as Boolean
  tubiLog("AdDisplayCarousel.onKeyEvent" + key)
  if press then
    if key = "right" AND m.carouselGrid.isInFocusChain()
      '//loop  to the first item if the user is at the end of the carousel
      m.carouselGrid.animateToItem = 0
      return true
    end if
  end if

  return false
End Function