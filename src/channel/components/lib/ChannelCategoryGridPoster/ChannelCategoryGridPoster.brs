Function init()
  m.constants = m.global.constants
  m._ = rodash()
  m.poster = m.top.findNode("Poster")
  m.posterRect = m.top.findNode("PosterRect")
  m.logo = m.top.findNode("Logo")
  m.title = m.top.findNode("Title")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("gridHasFocus", "onGridFocusChange")
  m.logo.observeField("loadStatus", "onLogoLoad")
  m.channelsExperimentEnabled = getExperimentResource("roku_channels_list_page", "roku_channels_list_page_v1", false).enabled = true
  ' used to keep track of if the grid has focus or not, onGridFocusChange fires every time any focus changes including
  ' scrolling between tiles.
  m.gridIsFocused = false
End Function


''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange(data)
  tubiLog("ChannelCategoryGridPoster.onContentChange " + data.getField())

  ' set some defaults
  m.title.visible = false

  if m.top.itemContent <> invalid then
    if m.top.itemContent.isSpecial <> true and m.channelsExperimentEnabled <> true
      ' Thumbnail images from the matrix/homescreen API are currently 640 x 360.
      ' These textures are too large when displayed in large amounts (over about 12) as occurs on the category list page,
      ' resulting in screen flashes as the background and category posters re-render themselves.
      ' Resampling the images to the size as they are meant to be displayed (430 x 242) uses less texture memory and prevents
      ' flashing of images up to at least 48 category posters.
      if m.constants.deviceInfo.limitedUi = true or m.constants.deviceInfo.lowVram = true
        urlBaseLength = Len(m.constants.ui.uris.categoryBackgrounds.urlBase)
        if type(m.top.itemContent.thumbnail) = "roString" and Left(m.top.itemContent.thumbnail, urlBaseLength) <> m.constants.ui.uris.categoryBackgrounds.urlBase
          m.poster.loadWidth = 430
          m.poster.loadHeight = 242
          m.poster.loadDisplayMode = "scaleToZoom"
        end if
      end if
    end if

    if m.channelsExperimentEnabled = true then
      m.posterRect.width = m.top.width
      m.posterRect.height = m.top.height
      m.posterRect.visible = true
      m.poster.visible = false
    else
      m.poster.visible = true
      m.posterRect.visible = false
      m.poster.uri = m.top.itemContent.thumbnail
    end if

    categoryContent = m.top.itemContent.getParent()
    if categoryContent <> invalid then
        if m.top.itemContent.logouri <> invalid and m.top.itemContent.logouri <> ""
          m.logo.uri = m.constants.urls.channelLogoBrandedPrefix + m.top.itemContent.id + m.constants.urls.channelLogoBrandedSuffix
        else
          displayTitle()
        end if
    end if
    setTranslations()
  end if
End Function


Function setTranslations()
  nXLogo = (m.top.width - m.logo.width)/2
  nYLogo = (m.top.height - m.logo.height)/2
  m.logo.translation = [nXLogo, nYLogo]

  nTitleWidth = m.top.width * .9 
  nXTitle = (m.top.width - nTitleWidth)/2
  nYTitle = (m.top.height - m.title.boundingRect().height)/2
  m.title.width = nTitleWidth
  m.title.translation = [nXTitle, nYTitle]
End Function


Function onLogoLoad()
  if m.logo.loadStatus = "failed"
    '//If the logo fails to load, then display the title as a failsafe
    displayTitle()
  end if
End Function


Function displayTitle()
  m.title.visible = true
  m.title.text = m.top.itemContent.title
End Function


Function onFocusPercentChange(msg)
  if m.channelsExperimentEnabled = false
    focusPercent = msg.getData()
    m.poster.opacity = m._.max(focusPercent, 0.5)
  end if
End Function


Function onGridFocusChange()
  if m.channelsExperimentEnabled = true
    ' Nothing needs to be done
  else if m.top.gridHasFocus = false and m.gridIsFocused = true 'grid is losing focus
    if m.poster.opacity > 0.5
      fade(m.poster, "out", 0.4, 0, 0.5)
    end if
    m.gridIsFocused = false
  else if m.top.gridHasFocus = true
    if m.gridIsFocused = false and m.top.itemHasFocus = true 'grid is regaining focus
      fade(m.poster, "in", 0.4, 0)
    end if
    m.gridIsFocused = true
  end if
End Function