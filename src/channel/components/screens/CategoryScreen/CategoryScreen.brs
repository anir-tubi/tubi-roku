Function init()
  tubiLog("CategoryScreen.init")
  m.constants = m.global.constants
  m.ContentArea = m.top.findNode("ContentArea")
  m.CategoryList = m.top.findNode("CategoryList") 'aka category menu
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.SpecialCategories = m.top.findNode("SpecialCategories")
  m.HintGroup = m.top.findNode("UpHintGroup")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("dirtyUserCategories", "onDirtyUserCategories")
  m.top.observeField("categoryListResponse", "onCategoriesReceived")
  m.top.observeField("trackingUri", "onTrackingUriChange")
  m.top.observeField("categoryMenuVisible", "onCategoryMenuVisible")
  m.top.trackingCount = 0
  m.CategoryList.observeField("itemFocused","onCategoryMenuChange")
  m.CategoryList.observeField("preItemFocused","onPreCategoryMenuChange")
  m.CategoryList.observeField("itemSelected", "onCategoryMenuSelected")
  m.categoryListIsFocused = false

  'Content area
  m.CategoryGridList = m.top.findNode("CategoryGridList")
  m.CategoryGridList.observeField("itemFocused", "onGridFocusChange")
  m.CategoryGridList.observeField("itemSelected", "onGridItemSelected")
  m.CategoryGridList.observeField("cursorPosition", "onGridCursorChange")

  'Special categories
  m.ContinueWatchingCategory = m.SpecialCategories.findNode(m.constants.ui.categoryIds.history)
  m.MyQueueCategory = m.SpecialCategories.findNode(m.constants.ui.categoryIds.queue)

  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()

  ' Category list loaded by loadAllCategories
  ' Content should be structured as:
  ' <CategoryContentNode>
  '   <CategoryContentNode title="category1" />
  '   <CategoryContentNode title="category2" />
  '   <CategoryContentNode title="category3" />
  '   ...
  ' </CategoryContentNode>
  m.categoryContent = invalid

  if m.constants.deviceInfo.scaledUi = true then
    frame = m.top.findNode("DockedVideoFrame")
    frameMargin = 4 ' FHD is margin 6
    frame.uri = "pkg:/images/selector-white-hd.9.png"
    frame.width = 455 + frameMargin * 2
    frame.height = 256 + frameMargin * 2
    frame.translation = [1390 - frameMargin, 151 - frameMargin]
  end if

  onSignedInChange()  ' seed the search & sign in menu

  loadAllCategories()
End Function


''''''''''''''''''''''''''''''
' onCategoriesReceived
'
Function onCategoriesReceived()
  tubiLog("CategoryScreen.onCategoriesReceived")
  if m.top.categoryListResponse <> invalid then
    response = m.top.categoryListResponse.response
    if response.code >= 200 and response.code < 300 then
      m.categoryContent = m.top.categoryListResponse.convertedMetadata
      adjustCategories()
      spinner = m.top.findNode("LoadingSpinner")
      spinner.visible = false
      m.CategoryList.content = invalid  ' since alwaysNotify=false on scrollinglist
      ' Prepend special categories, taking care to remove them if they already are there
      m.InfoPanel.mode = "category"
      m.CategoryList.content = m.categoryContent
      m.CategoryGridList.content = m.categoryContent  ' should be the category list
      if m.top.isInFocusChain() then m.CategoryGridList.setFocus(true)
    else
      testLog("Category list returned " + stri(response.code))
      ' if we were loading in the background, don't show an error modal
      if m.top.isInFocusChain() then showErrorModal(response.code, response.failReason, retryCategoryList, retryCategoryList)
    end if
  end if
End Function

' We retry in the cancel or retry cases, since there is nowhere else to go
Function retryCategoryList()
  loadAllCategories()
  m.top.setFocus(true)
End Function

''''''''''''''''''''''''''''
' onDirtyUserCategories
'
' if one of the user categories is showing, reload it
Function onDirtyUserCategories()
  tubiLog("CategoryScreen.onDirtyUserCategories")
  adjustCategories()
  m.CategoryGridList.dirtyUserCategories = true
End Function

''''''''''''''''''''
' onScreenFocusChange
'
' Set focus back to category list or component group if the
' screen has lost focus, usually due to another screen or dialog
' being shown.
Function onScreenFocusChange()
  tubiLog("CategoryScreen.onScreenFocusChange " + focusState(m.top))
  if m.top.hasFocus()
    if m.categoryListIsFocused = false
    ' defaulted to screen, move to a subcomponent
      m.CategoryGridList.setFocus(true)
    else
      m.CategoryList.setFocus(true)
      m.categoryListIsFocused = true
    end if
  end if
End Function

' We do this here becase the ScrollingList component swallows the 'ok' keypress
Function onCategoryMenuSelected()
  onKeyEvent("ok", true)
End Function

''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("CategoryScreen.onKeyEvent")
  if press then
    if (key = "right" or key = "ok") then
      m.top.categoryMenuVisible = false
      return true
    else if key = "left" then
      m.top.categoryMenuVisible = true
      return true
    end if
  end if
  return false
End Function


' onCategoryMenuVisible
Function onCategoryMenuVisible()
  if m.top.categoryMenuVisible
    showCategoryMenu()
  else
    hideCategoryMenu()
  end if
End Function

Function showCategoryMenu()
  if not m.CategoryList.isInFocusChain()
    m.CategoryList.animateToItem = Int(m.CategoryGridList.currFocusRow)
    m.CategoryList.setFocus(true)
    m.categoryListIsFocused = true
    if m.global.constants.deviceInfo.limitedNewUi
      m.ContentArea.translation = [517,m.ContentArea.translation[1]]
      m.CategoryList.translation = [60,m.CategoryList.translation[1]]
    else
      slideTo(m.ContentArea, [517,m.ContentArea.translation[1]], 0.5)
      slideTo(m.CategoryList, [60,m.CategoryList.translation[1]], 0.5)
    end if
    m.trackingCount = 0
    m.CategoryGridList.isFullWidth = false
  end if
End Function

Function hideCategoryMenu()
  if m.CategoryList.isInFocusChain()
    m.CategoryGridList.setFocus(true)
    m.categoryListIsFocused = false
    if m.global.constants.deviceInfo.limitedNewUi
      m.ContentArea.translation = [85,m.ContentArea.translation[1]]
      m.CategoryList.translation = [-380,m.CategoryList.translation[1]]
    else
      slideTo(m.ContentArea, [85,m.ContentArea.translation[1]], 0.5)
      slideTo(m.CategoryList, [-380,m.CategoryList.translation[1]], 0.5)
    end if
    m.trackingCount = 0
    m.CategoryGridList.isFullWidth = true
  end if
End Function


' Change categories based on current app state
Function adjustCategories() As Void
  if m.categoryContent = invalid then return

  ' Force Featured to the top of the list
  for i=0 to m.categoryContent.getChildCount()-1
    category = m.categoryContent.getChild(i)
    if category.title = "Featured"
      if i > 0 then
        m.categoryContent.removeChild(category)
        m.categoryContent.insertChild(category, 0)
      end if
      exit for
    end if
  end for

  ' Add or remove user categories, taking care to only change them when necessary
  insert = 1
  if m.top.signedIn and m.global.historyIds.getChildCount() > 0 and not m.categoryContent.isSameNode(m.ContinueWatchingCategory.getParent()) then
    m.categoryContent.insertChild(m.ContinueWatchingCategory, insert)
    insert = insert + 1
  else if m.global.historyIds.getChildCount() = 0 and m.ContinueWatchingCategory.getParent() <> invalid then
    m.categoryContent.removeChild(m.ContinueWatchingCategory)
  end if
  if m.top.signedIn and m.global.bookmarkIds.getChildCount() > 0 and not m.categoryContent.isSameNode(m.MyQueueCategory.getParent()) then
    m.categoryContent.insertChild(m.MyQueueCategory, insert)
  else if m.global.bookmarkIds.getChildCount() = 0 and m.MyQueueCategory.getParent() <> invalid then
    m.categoryContent.removeChild(m.MyQueueCategory)
  end if
End Function

' Use this trigger to synchronize menu and grid
Function onPreCategoryMenuChange()
  ' Don't sync if CategoryList has focus and most likely triggered the grid category change
  if m.CategoryList.isInFocusChain() and m.CategoryList.content <> invalid then
    m.CategoryGridList.animateToCategory = m.CategoryList.preItemFocused
  end if
End Function


'''''''''''''''''''''
' onCategoryMenuChange
'
' On category focus change, update the info panel
Function onCategoryMenuChange() As Void
  tubiLog("CategoryScreen.onCategoryMenuChange")
  if not m.CategoryList.isInFocusChain() or m.CategoryList.content = invalid then return

  newCategory = m.CategoryList.content.getChild(m.CategoryList.itemFocused)
  referenceCategory = m.top.cachedContent.getChild(m.CategoryList.itemFocused)
  
  infoMetadata = CreateObject("roSGNode", "CategoryContentNode")
  if newCategory <> invalid
    infoMetadata.title = newCategory.title
    infoMetadata.description = newCategory.description
  end if

  if referenceCategory <> invalid
    infoMetadata.totalCount = referenceCategory.getChildCount()
  end if

  populateInfoPanel("category", infoMetadata)
  m.top.backgroundUriList = [m.defaultBackgroundUri]

  'update the tracking URI for user tracking purposes
  catPos = (m.CategoryList.itemFocused + m.top.rowPlaceholder + 1).toStr()
  if newCategory <> invalid
    catSlug = newCategory.id
  else
    catSlug = ""
  end if
  m.top.trackingUri = "/home/" + catPos + "/cat/" + catSlug
End Function


'''''''''''''''''''''''''''
' onSignedInChange
'
Function onSignedInChange()
  tubiLog("CategoryScreen.onSignedInChange")
  adjustCategories()
End Function


Function onGridCursorChange() As Void
  'removes the "On Now" and arrow if the top most category is not focused
  if m.CategoryGridList.cursorPosition[0] = 0
    if m.HintGroup.opacity < 1.0 then fade(m.HintGroup, "in", 0.4)
  else
    if m.HintGroup.opacity > 0.0 then fade(m.HintGroup, "out", 0.4)
  end if
End Function


'''''''''''''''''''''
' onGridFocusChange
'
' On grid focus change, update the info panel
Function onGridFocusChange() As Void
  tubiLog("CategoryScreen.onGridFocusChange")

  if not m.CategoryGridList.isInFocusChain() then return
  focusedContent = m.CategoryGridList.itemFocused
  populateInfoPanel("item", focusedContent)

  if focusedContent <> invalid and focusedContent.backgrounds <> invalid and focusedContent.backgrounds.count() > 0 then
    m.top.backgroundUriList = focusedContent.backgrounds
  else
    m.top.backgroundUriList = [m.defaultBackgroundUri]
  end if

  'update the tracking URI
  catSlug = ""
  if m.CategoryList.content.getChild(m.CategoryGridList.cursorPosition[0]) <> invalid
    if m.CategoryList.content.getChild(m.CategoryGridList.cursorPosition[0]).id <> invalid
      catSlug = m.CategoryList.content.getChild(m.CategoryGridList.cursorPosition[0]).id + "/"
    end if
  end if
  
  row = 1  'row is fixed at 1 for this design, it indicates the row within the category
  col = 0  'column is the column within the category, expect this to change
  catPos = 0  'catPos is the order of the category (Featured should be 1)
  if m.CategoryGridList.cursorPosition[0] >= 0
    catPos = m.CategoryGridList.cursorPosition[0] + 1
    col = m.CategoryGridList.cursorPosition[1] + 1
  end if

  'set the user event tracking info
  row = row.toStr() + "/"
  col = col.toStr()
  catPos = catPos.toStr()
  m.top.trackingUri = "/home/" + catPos + "/cat/" + catSlug + row + col

End Function

Function onGridItemSelected() As Void
  tubiLog("CategoryScreen.onGridItemSelected")
  m.top.trackingCount = 0
  selectedItem = m.CategoryGridList.itemSelected
  if selectedItem <> invalid then 
    m.top.contentSelected = selectedItem
  end if
End Function

'''''''''''''''''''''
' loadAllCategories
'
' Load category list plus one populated category
Function loadAllCategories()
  tubiLog("CategoryScreen.loadAllCategories")

  ' TODO(Chris): This should move to a shim layer which hides specifics of the Tubi v4 API
  settings = m.global.constants.settings
  platform = m.global.constants.platform
  deviceInfo = m.global.constants.deviceInfo
  url = m.global.constants.urls.cms.categories
  options = {
    params: {
      "app_id": settings.shortAppName
      platform: platform
      "device_id": deviceInfo.deviceId
      page_enabled: false
    }
  }
  m.global.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("categories", m.top, "categoryListResponse", url, "getAllCategories", options)
End Function


'''''''''''
' onTrackingUriChange
'
' send the navigateInPage (navigate_within_page) tracking event
Function onTrackingUriChange()
  if m.top.trackingUri <> ""
    m.top.trackingCount = m.top.trackingCount + 1
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "navigateInPage"
      value: m.top.trackingCount
      ctx: m.top.trackingUri
    }
  end if
End Function


'@mode: string, one of the valid info panel modes (see InfoPanel.brs for details)
'@content: content node
Function populateInfoPanel(mode, contentNode)
  if mode = "category"
    m.InfoPanel.mode = "category"
    m.InfoPanel.categoryContentCount = contentNode.totalCount
    m.InfoPanel.title = contentNode.title
    m.InfoPanel.description = contentNode.description
  else if mode = "item"
    m.InfoPanel.mode = "item"
    m.InfoPanel.title = contentNode.title
    m.InfoPanel.description = contentNode.description
    m.InfoPanel.releaseDate = contentNode.releaseDate
    m.InfoPanel.length = contentNode.length
    m.InfoPanel.rating = contentNode.rating
    m.InfoPanel.genres = contentNode.genres
    if contentNode.subtitleTracks <> invalid
      m.InfoPanel.hasCC = true
    else
      m.InfoPanel.hasCC = false
    end if
  end if

  m.InfoPanel.calculateHeight = true
End Function