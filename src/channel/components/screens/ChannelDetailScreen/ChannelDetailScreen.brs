Function init()
  m._ = rodash()
  m.constants = m.global.constants
  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  m.InfoPanel = m.top.findNode("ChannelsInfoPanel")
  m.ButtonList = m.top.findNode("ChannelsButtonList")
  m.RowList = m.top.findNode("ChannelsRowList")

  m.top.observeField("content", "onContentChange")
  m.top.observeField("isLoading", "onIsLoading")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.RowList.observeField("rowItemFocused", "onRowItemFocused")
  m.RowList.observeField("rowItemSelected", "onRowItemSelected")

  ' populate the "about this channel" button
  aboutContainer = CreateObject("roSGNode", "ContentNode")
  aboutButton = aboutContainer.createChild("ContentNode")
  aboutButton.title = "About This Channel"
  m.ButtonList.content = aboutContainer

  ' track the last focused item
  m.focusTarget = m.ButtonList
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true
    m.focusTarget.setFocus(true)
  else if m.top.isInFocusChain() = false
    m.top.trackingCount = 0
  end if
End Function


Function onKeyEvent(key, press)
  if press = true
    if key = "left" and m.RowList.isInFocusChain() = true
      if m.top.content <> invalid
        showButtonList(m.ButtonList, m.RowList)
        rowItem = m.RowList.rowItemFocused
        category = m.top.content.getChild(rowItem[0])
        content = category.getChild(rowItem[1])
        populateInfoPanel(m.InfoPanel, category, "category")
      end if
    else if key = "right" and m.ButtonList.isInFocusChain() = true
      if m.top.content <> invalid
        hideButtonList(m.ButtonList, m.RowList)
        rowItem = m.RowList.rowItemFocused
        category = m.top.content.getChild(rowItem[0])
        content = category.getChild(rowItem[1])
        populateInfoPanel(m.InfoPanel, content, "item")
      end if
    else if key = "back"
      return false
    end if
  end if
  return true
End Function


Function showButtonList(buttonList, rowList)
  tubiLog("ChannelDetailScreen.showButtonList")
  'update the positions of the buttonList and rowList
  if m.constants.deviceInfo.limitedUi = true
    buttonList.translation = [60, buttonList.translation[1]]
    rowList.translation = [517, rowList.translation[1]]
  else
    slideTo(buttonList, [60, buttonList.translation[1]], 0.5)
    slideTo(rowList, [517, rowList.translation[1]], 0.5)
  end if

  'set focus on buttonList
  buttonList.setFocus(true)
  m.focusTarget = buttonlist

  'use the default background when not focusing on content
  m.top.backgroundUriList = [m.defaultBackgroundUri]
End Function


Function hideButtonList(buttonList, rowList)
  tubiLog("ChannelDetailScreen.hideButtonList")
  'update the positions of the buttonList and rowList
  if m.constants.deviceInfo.limitedUi = true
    buttonList.translation = [-380, buttonList.translation[1]]
    rowList.translation = [85, rowList.translation[1]]
  else
    slideTo(buttonList, [-380, buttonList.translation[1]], 0.5)
    slideTo(rowList, [85 ,rowList.translation[1]], 0.5)
  end if

  'set focus on rowList
  rowList.setFocus(true)
  m.focusTarget = rowList

  'show the background image of the focused content
  rowItem = m.RowList.rowItemFocused
  category = m.top.content.getChild(rowItem[0])
  content = category.getChild(rowItem[1])
  if type(content.backgrounds) = "roArray" and content.backgrounds.count() > 0
    m.top.backgroundUriList = content.backgrounds
  end if
End Function


Function onContentChange()
  if m.top.content <> invalid
    m.top.trackingCount = 0
    category = m.top.content.getChild(0)
    if category <> invalid
      showButtonList(m.ButtonList, m.RowList)
      populateInfoPanel(m.InfoPanel, category, "category")
      m.top.trackingUri = generateTrackingUri(invalid, category)
    end if
  end if
End Function

Function onIsLoading()
  tubiLog("ChannelDetailScreen.onIsLoading")
  if m.top.isLoading = true
    m.InfoPanel.visible = false
    m.ButtonList.visible = false
    m.RowList.visible = false
  else
    m.InfoPanel.visible = true
    m.ButtonList.visible = true
    m.RowList.visible = true
  end if
End Function

Function onRowItemFocused()
  tubiLog("ChannelDetailScreen.onRowItemFocused")
  rowItem = m.RowList.rowItemFocused
  category = m.top.content.getChild(rowItem[0])
  content = category.getChild(rowItem[1])

  ' Update the info panel
  populateInfoPanel(m.InfoPanel, content, "item")

  ' Update the tracking URI.  Only send events if they have not been fired already,
  ' in case focus changes cause rowIteFocused to trigger
  trackingUri = generateTrackingUri(rowItem, category)
  if trackingUri <> m.top.trackingUri
    m.top.trackingCount = m.top.trackingCount + 1
    m.top.trackingUri = trackingUri
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "navigateInPage"
      value: m.top.trackingCount
      ctx: m.top.trackingUri
    }
  end if

  ' Update the background image
  if type(content.backgrounds) = "roArray" and content.backgrounds.count() > 0
    m.top.backgroundUriList = content.backgrounds
  else
    m.top.backgroundUriList = [m.defaultBackgroundUri]
  end if
End Function


Function onRowItemSelected()
  rowItem = m.RowList.rowItemSelected
  category = m.top.content.getChild(rowItem[0])
  content = category.getChild(rowItem[1])

  ' Update the tracking URI so that it is ready once the ContentController creates the details page
  m.top.trackingUri = generateTrackingUri(rowItem, category)

  ' Pass info to ContentController
  m.top.contentSelected = content
End Function


'@infoPanel: roSGNode, an InfoPanel component
'@content: roSGNode, a content node
Function populateInfoPanel(infoPanel, content, mode)
  infoPanel.mode = mode
  if content.title <> invalid
    infoPanel.title = content.title
  else
    infoPanel.title = ""
  end if

  if content.channelImg <> invalid
    infoPanel.titleLogoUri = content.channelImg
  else
    infoPanel.titleLogoUri = ""
  end if

  if content.description <> invalid
    infoPanel.description = content.description
  else
    infoPanel.description = ""
  end if

  if content.releaseDate <> invalid
    infoPanel.releaseDate = content.releaseDate
  else
    infoPanel.releaseDate = ""
  end if

  if content.length <> invalid
    infoPanel.length = content.length
  else
    infoPanel.length = 0
  end if

  if content.rating <> invalid
    infoPanel.rating = content.rating
  else
    infoPanel.rating = 0
  end if

  if content.genres <> invalid
    infoPanel.genres = content.genres
  else
    infoPanel.genres = []
  end if

  if (content.hasSubtitles = true or not m._.empty(content.subtitleTracks)) = true
    infoPanel.hasCC = true
  else
    infoPanel.hasCC = false
  end if

  if content.channelImg <> invalid
    infoPanel.partnerLogoUri = content.channelImg
  else
    infoPanel.partnerLogoUri = ""
  end if

  if content.totalCount <> invalid and content.totalCount >= 0
    infoPanel.categoryContentCount = content.totalCount
  else
    infoPanel.categoryContentCount = 0
  end if

  if content.logoUri <> invalid
    infoPanel.titleLogoUri = content.logoUri
  else
    infoPanel.titleLogoUri = ""
  end if
  
  infoPanel.calculateHeight = true

  return infoPanel
End Function


'@rowItem: 2DArray, [x, y] where x is the position in the channel row. Expect y = 0.
'@channel: roSGNode, a content node for a single channel
'
'returns a string with a tracking uri that is ready to be sent to the tracking api
Function generateTrackingUri(rowItem, channel)
  'TODO BRYAN: verify that the following URI format is appropriate -> "/channel/slug/row/col"
  slug = ""
  row = ""
  col = ""

  if channel.slug <> invalid then slug = channel.slug
  
  if rowItem <> invalid
    if rowItem[1] <> invalid then row = "/" + (rowItem[1] + 1).toStr()
    if rowItem[0] <> invalid then col = "/" + (rowItem[0] + 1).toStr()
  end if
  return "/category/" + slug + row + col
End Function
