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
    m.poster.uri = m.top.itemContent.thumbnail
    m.poster.opacity = m.top.itemContent.thumbnailAlpha
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