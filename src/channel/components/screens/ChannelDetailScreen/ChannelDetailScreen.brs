Function init()
  m._ = rodash()
  m.constants = m.global.constants
  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

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

  ' set initial tracking values
  m.top.trackingPageInfo = setTrackingPageInfo(invalid)

  ' used to compare if a newly focused item gained focus from a different item while scrolling,
  ' or gained focus from a different component/screen
  m.contentIsFocused = false
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true
    m.focusTarget.setFocus(true)
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

  m.contentIsFocused = false

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
  '//an extra call to setFocus() is needed to set the proper focus due to a bug in the roku Rowlist component that offsets the cursor in error
  m.RowList.setFocus(false)
  m.RowList.setFocus(true)
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
    category = m.top.content.getChild(0)
    if category <> invalid
      showButtonList(m.ButtonList, m.RowList)
      populateInfoPanel(m.InfoPanel, category, "category")
      m.top.trackingPageInfo = setTrackingPageInfo(category)
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
  category = m.top.content.getChild(rowItem[0]) 'contentNode
  content = category.getChild(rowItem[1]) 'contentNode

  ' Update the info panel
  populateInfoPanel(m.InfoPanel, content, "item")

  ' Update the tracking info.
  trackingPageInfo = setTrackingPageInfo(category)
  m.top.trackingPageInfo = trackingPageInfo

  ' trigger navigate_within_page events in ContentController
  if m.contentIsFocused = true
    col = rowItem[1] + 1
    row = 1
    categoryComponent = {
      category_slug: category.slug
      category_row: 1   ' 1 based index
      content_tile: m.Tracking.getAnalyticsTile(content, col, row)
    }
    m.top.navigateWithinPageInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent("category_component", categoryComponent)
      means_of_navigation: "SCROLL"  'MeansOfNavigation enum
      vertical_location: row '1 based index
      vertical_location_mode: "INDEX"  'LocationMode enum
      horizontal_location: col
      horizontal_location_mode: "COORDINATE"  'LocationMode enum
    }
  end if
  m.contentIsFocused = true

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

  ' Update the tracking info so that it is ready once the ContentController creates the details page
  m.top.trackingPageInfo = setTrackingPageInfo(category)

  categorySlug = ""
  if category <> invalid
    categorySlug = category.slug
  end if

  ' Set the tracking component of the item that was selected so it can be accessed as part of the navigateToPage event
  m.top.trackingComponentInfo = {
    componentType: "category_component"
    componentValues: {
      category_slug: categorySlug
      category_row: 1
      content_tile: m.Tracking.getAnalyticsTile(content, rowItem[1] + 1)
    }
  }
  m.contentIsFocused = false

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

  if content.description <> invalid
    infoPanel.description = content.description
  else
    infoPanel.description = ""
  end if

  line1Data = {}
  if content.releaseDate <> invalid
    line1Data.releaseDate = content.releaseDate
  else
    line1Data.releaseDate = ""
  end if

  if content.length <> invalid
    line1Data.length = content.length
  else
    line1Data.length = 0
  end if

  if (content.hasSubtitles = true or not m._.empty(content.subtitleTracks)) = true
    line1Data.hasCC = true
  else
    line1Data.hasCC = false
  end if

  if content.rating <> invalid
    line1Data.rating = content.rating
  else
    line1Data.rating = 0
  end if

  if content.inlineLogoUri <> invalid
    line1Data.partnerLogoUri = content.inlineLogoUri
  else
    line1Data.partnerLogoUri = ""
  end if
  infoPanel.lineOneData = line1Data

  if content.genres <> invalid
    infoPanel.genres = content.genres
  else
    infoPanel.genres = []
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


'@channel: roSGNode, a content node for a single channel
'
'returns an AA with tracking info formatted for use by ScreenStack.screenTrackingLoad()
Function setTrackingPageInfo(channel)
  slug = ""
  if channel <> invalid
    slug = channel.slug
  end if

  trackingInfo = {
    pageType: "category_page"
    pageValues: {
      category_slug: slug
    }
  }

  return trackingInfo
End Function
