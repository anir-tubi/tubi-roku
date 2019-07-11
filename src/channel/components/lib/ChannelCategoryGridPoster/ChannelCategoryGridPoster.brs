Function init()
  m.constants = m.global.constants
  m.poster = m.top.findNode("Poster")
  m.logo = m.top.findNode("Logo")
  m.title = m.top.findNode("Title")
  m.top.observeField("itemContent", "onContentChange")
  m.logo.observeField("loadStatus", "onLogoLoad")
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
    if m.top.itemContent.isSpecial <> true
      ' Thumbnail images from the matrix/homescreen API are currently 640 x 360.
      ' These textures are too large when displayed in large amounts (over about 12) as occurs on the category list page,
      ' resulting in screen flashes as the background and category posters re-render themselves.
      ' Resampling the images to the size as they are meant to be displayed (430 x 242) uses less texture memory and prevents
      ' flashing of images up to at least 48 category posters.
      if m.constants.deviceInfo.limitedUi = true or m.constants.deviceInfo.lowVram = true
        m.poster.loadWidth = 430
        m.poster.loadHeight = 242
        m.poster.loadDisplayMode = "scaleToZoom"
      end if
      m.poster.opacity = 0.3
    end if

    m.poster.uri = m.top.itemContent.thumbnail

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