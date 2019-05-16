Function init()
  tubiLog("CategoryScreen.init")
  m._ = rodash()
  m.NodeHelpers = TubiNodeHelpers()
  m.constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.trackingLoggingTask = m.global.trackingLoggingTask
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.ContentArea = m.top.findNode("ContentArea")
  m.CategoryList = m.top.findNode("CategoryList") 'aka category menu
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.HintGroup = m.top.findNode("UpHintGroup")
  fades = m.top.findNode("Fades")
  m.HintGroupFade = fades.findNode("HintGroupFade")
  m.Spinner = m.top.findNode("CategorySpinner")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("dirtyUserCategories", "onDirtyUserCategories")
  m.top.observeField("homescreenResponse", "onHomescreenResponse")
  m.top.observeField("reloadUserCategoriesResponse", "onReloadUserCategoriesResponse")
  m.top.observeField("categoryMenuVisible", "onCategoryMenuVisible")
  m.top.observeField("loadAllCategories", "loadAllCategories")
  
  m.CategoryList.observeField("itemFocused","onCategoryMenuItemFocused")
  m.CategoryList.observeField("rowScrollFocused","onCategoryListScrollFocused")
  m.CategoryList.observeField("itemSelected", "onCategoryMenuSelected")

  m.CategoryRefreshTimer = m.top.findNode("CategoryRefreshTimer")
  m.CategoryRefreshTimer.duration = m.constants.timers.categoryContentRefreshTimeout
  m.CategoryRefreshTimer.observeField("fire", "onCategoryRefreshTimer")
  m.CategoryRefreshTimer.control = "start"

  'Content area
  m.CategoryGridList = m.top.findNode("CategoryGridList")
  m.CategoryGridList.observeField("itemSelected", "onGridItemSelected")
  m.CategoryGridList.observeField("itemFocused", "onGridFocusChange")
  m.CategoryGridList.observeField("categoryTotalCounts", "onTotalCountsChange")
  m.CategoryGridList.observeField("currFocusRow", "onCurrFocusRow")

  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()

  ' Category list loaded by loadAllCategories
  ' Content should be structured as:
  ' <CategoryContentNode json={...all contents info...}>
  '   <CategoryContentNode id="featured">
  '     <ContentNode id="37108" />
  '     <ContentNode id="337825" />
  '      ...
  '   </CategoryContentNode>
  '   <CategoryContentNode id="most_popular" />
  '     <ContentNode id="346629" />
  '     <ContentNode id="407698" />
  '      ...
  '   </CategoryContentNode>
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

  m.gridHasFocus = false
  m.listHasFocus = false

  ' Can be "grid" or "list" for current UI (2/19)
  m.lastFocused = "grid"
End Function


''''''''''''''''''''''''''''''
' onHomescreenResponse
'
Function onHomescreenResponse()
  tubiLog("CategoryScreen.onHomescreenResponse")
  if m.top.homescreenResponse.response <> invalid then
    response = m.top.homescreenResponse.response
    if response.code >= 200 and response.code < 300 then
      m.categoryContent = m.top.homescreenResponse.convertedMetadata
      m.Spinner.visible = false
      m.InfoPanel.mode = "category"
      m.CategoryList.content = m.categoryContent    ' should be all cateogories but with no content in them
      m.CategoryGridList.content = m.categoryContent  ' should be all categories with initial amounts of content in them
    else
      ' if we were loading in the background, don't show an error modal
      if m.top.isInFocusChain()
        errorObj = createErrorObject(m.global.constants.errors.context.homeScreen, m.global.constants.errors.subtypes.fetchError, response.failReason, response.code)
        showErrorModal(errorObj, retryCategoryList, [], retryCategoryList, [])
        sendDialogAnalyticsEvent("WARNING", m.Tracking, m.trackingLoggingTask)
      end if
    end if
  end if
End Function


Function onReloadUserCategoriesResponse(msg)
  handledRequest = msg.getData()
  tubiLog("CategoryScreen.onReloadUserCategoriesResponse")
  if handledRequest.response <> invalid then
    response = handledRequest.response
    if response.code >= 200 and response.code < 300 then
      newCategory = handledRequest.convertedMetadata
      m.Spinner.visible = false

      if m.categoryContent <> invalid
        oldCategory = invalid
        if newCategory <> invalid and newCategory.id <> invalid
          oldCategory = m.categoryContent.findNode(newCategory.id)
        else if handledRequest.context.id <> invalid
          oldCategory = m.categoryContent.findNode(handledRequest.context.id)
        end if

        ' there are 4 options here
        ' 1) new category and old category both have content in them - replace the old with the new
        ' 2) new category has content, old category doesn't exist - add the new category
        ' 3) new category doesn't have content (will be invalid), old category does have content - remove old category
        ' 4) new category doesn't have content (will be invalid), old category doesn't exist - do nothing
        if newCategory <> invalid and oldCategory <> invalid
          'replace old category with new category
          m.categoryContent.replaceChild(newCategory, m.NodeHelpers.getChildIndex(m.categoryContent, oldCategory))
        else if newCategory <> invalid and oldCategory = invalid
          'add new category
          'if new category is history, put it one before queue, or if queue doens't exist put it in 2nd position
          'if new category is queue put it one after history, or if history doesn't exist, put it in 2nd position
          if newCategory.id = m.constants.ui.categoryIds.history
            queueIndex = m.NodeHelpers.getChildIndexById(m.categoryContent, m.constants.ui.categoryIds.queue)
            insertPos = 1
            if queueIndex > -1
              insertPos = queueIndex
            end if
            m.categoryContent.insertChild(newCategory, insertPos)
          else if newCategory.id = m.constants.ui.categoryIds.queue
            historyIndex = m.NodeHelpers.getChildIndexById(m.categoryContent, m.constants.ui.categoryIds.history)
            insertPos = 1
            if historyIndex > -1
              insertPos = historyIndex + 1
            end if
            m.categoryContent.insertChild(newCategory, insertPos)
          end if
        else if newCategory = invalid and oldCategory <> invalid
          'remove old category
          m.categoryContent.removeChild(oldCategory)
        else if newCategory = invalid and oldCategory = invalid
          'do nothing
        end if

        'reset the categoryGridList content so the changes display in the RowList
        categoryContent = m.categoryContent
        m.CategoryGridList.content = categoryContent
      end if

      ' if m.CategoryGridList.content <> invalid
      '   ' Make sure any user categories which didn't get newly added are reloaded
      '   for each userCategory in [m.constants.ui.categoryIds.history, m.constants.ui.categoryIds.queue]
      '     childNode = m.CategoryGridList.content.findNode(userCategory)
      '     if childNode <> invalid
      '       m.CategoryGridList.content.replaceChild(childNode.clone(false), m.NodeHelpers.getChildIndex(m.CategoryGridList.content, childNode))
      '     end if
      '   end for
      ' else
      '   m.CategoryGridList.content = m.categoryContent  ' should be all categories with initial amounts of content in them
      ' end if
      ' if m.top.isInFocusChain() then m.CategoryGridList.setFocus(true)
    else
      ' if we were loading in the background, don't show an error modal
      if m.top.isInFocusChain()

        errorObj = createErrorObject(m.global.constants.errors.context.homeScreen, m.global.constants.errors.subtypes.fetchError, response.failReason, response.code)
        showErrorModal(errorObj, retryCategoryList, [], retryCategoryList, [])
        sendDialogAnalyticsEvent("WARNING", m.Tracking, m.trackingLoggingTask)
      end if
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
Function onDirtyUserCategories(msg)
  tubiLog("CategoryScreen.onDirtyUserCategories")
  categoryId = msg.getData()

  if categoryId <> invalid
    url = m.constants.urls.matrix.container + "/" + categoryId
    options = {
      params: {
        "app_id": m.constants.settings.shortAppName
        platform: m.constants.platform
        "device_id": m.constants.deviceInfo.deviceId
        limit: m.constants.performance.categoryGridList.finalBlockSize
        expand: 1
        cursor: 0
        includeEmpty: true
      }
    }

    'this will be an auth request if the user is logged in
    'auth request creation happens in metadataFetchTask
    'auth request will add the userId param
    reqName = m.constants.reqNames.getCategory
    m.global.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest(categoryId, m.top, "reloadUserCategoriesResponse", reqName)
    m.Spinner.visible = true
  end if
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
    if m.lastFocused = "list"
      m.CategoryList.setFocus(true)
      m.listHasFocus = true
      m.gridHasFocus = false
    else
      m.CategoryGridList.setFocus(true)
      m.top.backgroundUriList = determineBackgroundImage(m.CategoryGridList.itemFocused)
      m.listHasFocus = false
      m.gridHasFocus = true
    end if

    if m.CategoryGridList.content <> invalid and shouldRefresh(m.CategoryGridList.content) = true
      loadAllCategories()
    end if
  else if m.top.isInFocusChain() = false
    if m.listHasFocus = true
      m.lastFocused = "list"
    else
      m.lastFocused = "grid"
    end if
    m.gridHasFocus = false
    m.listHasFocus = false
  end if
End Function


Function onCategoryMenuSelected()
  m.top.categoryMenuVisible = false
End Function


''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("CategoryScreen.onKeyEvent")
  ' ignore keypresses until the screen content has shown up
  if press and m.top.homescreenResponse <> invalid then
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
    m.CategoryList.jumpToItem = Int(m.CategoryGridList.currFocusRow)
    m.CategoryList.setFocus(true)
    m.listHasFocus = true
    if m.global.constants.deviceInfo.limitedUi
      m.ContentArea.translation = [517,m.ContentArea.translation[1]]
      m.CategoryList.translation = [60,m.CategoryList.translation[1]]
    else
      slideTo(m.ContentArea, [517,m.ContentArea.translation[1]], 0.5)
      slideTo(m.CategoryList, [60,m.CategoryList.translation[1]], 0.5)
    end if
    m.CategoryGridList.isFullWidth = false
    m.top.backgroundUriList = [m.defaultBackgroundUri]
  end if
End Function


Function hideCategoryMenu()
  if m.CategoryList.isInFocusChain()
    m.CategoryGridList.setFocus(true)
    m.listHasFocus = false
    if m.global.constants.deviceInfo.limitedUi
      m.ContentArea.translation = [85,m.ContentArea.translation[1]]
      m.CategoryList.translation = [-380,m.CategoryList.translation[1]]
    else
      slideTo(m.ContentArea, [85,m.ContentArea.translation[1]], 0.5)
      slideTo(m.CategoryList, [-380,m.CategoryList.translation[1]], 0.5)
    end if
    m.CategoryGridList.isFullWidth = true
  end if
End Function

' Use this trigger to synchronize menu and grid
Function onCategoryListScrollFocused()
  ' Don't sync if CategoryList has focus and most likely triggered the grid category change
  if m.CategoryList.isInFocusChain() and m.CategoryList.content <> invalid then
    m.CategoryGridList.animateToCategory = m.CategoryList.rowScrollFocused
  end if
End Function


'''''''''''''''''''''
' onCategoryMenuItemFocused
'
' On category menu, item focus change, update the info panel
Function onCategoryMenuItemFocused() As Void
  tubiLog("CategoryScreen.onCategoryMenuItemFocused")
  if not m.CategoryList.isInFocusChain() or m.CategoryList.content = invalid then return

  infoMetadata = CreateObject("roSGNode", "CategoryContentNode")

  newCategory = m.CategoryList.content.getChild(m.CategoryList.itemFocused)
  if newCategory <> invalid
    infoMetadata.title = newCategory.title
    infoMetadata.description = newCategory.description
    infoMetadata.totalCount = newCategory.totalCount
    infoMetadata.logoUri = newCategory.logoUri
  end if

  populateInfoPanel("category", infoMetadata)

  'Set up the navigateWithinPageInfo to send to ContentController via Homescreen
  if m.listHasFocus = true
    m.top.navigateWithinPageInfo = {
      pageOneof: m.Tracking.getAnalyticsPage("home_page", {})
      componentOneof: m.Tracking.getAnalyticsComponent("category_list_component", {}) 'category_list_component doesn't exist in protos
      means_of_navigation: "BUTTON"  'MeansOfNavigation enum
      vertical_location: m.CategoryList.itemFocused + 1 '1 based index
      vertical_location_mode: "INDEX"  'LocationMode enum
      horizontal_location: 1
      horizontal_location_mode: "INDEX"  'LocationMode enum
    }
  end if
  m.listHasFocus = true
  m.gridHasFocus = false
End Function


'''''''''''''''''''''''''''
' onSignedInChange
'
' When signed in/out changes, we need to reload all categories to 
' reflect changes in parental controls between guest and signed-in
' users
Function onSignedInChange()
  tubiLog("CategoryScreen.onSignedInChange")
  loadAllCategories()
End Function

Function onCurrFocusRow()
  ' Toolbar is available at any grid row so we only fade out this
  ' up hint for OnNow content
  if m.top.onNowHintVisible = true
    if m.CategoryGridList.currFocusRow >= 1
      animationFraction = 1.0
    else
      animationFraction = m.CategoryGridList.currFocusRow
    end if

    m.HintGroupFade.fraction = animationFraction
  end if
End Function


'''''''''''''''''''''
' onGridFocusChange
'
' On grid focus change, update the info panel
Function onGridFocusChange() As Void
  tubiLog("CategoryScreen.onGridFocusChange")
  if not m.CategoryGridList.isInFocusChain() then return

  oldFocusedContent = m.CategoryGridList.oldItemFocused
  focusedContent = m.CategoryGridList.itemFocused
  if focusedContent <> invalid
    populateInfoPanel("item", focusedContent)
  end if

  ' If focus is on an empty category, leave the background as is.  This helps avoid
  ' background jank and keeps CPU usage down while categories are being fetched.
  if focusedContent <> invalid
    m.top.backgroundUriList = determineBackgroundImage(focusedContent)
  end if

  'Set up the navigateWithinPageInfo to send to ContentController via Homescreen
  oldAnalyticsRow = m.CategoryGridList.oldCursorPosition[0] + 1
  oldAnalyticsCol = m.CategoryGridList.oldCursorPosition[1] + 1
  newAnalyticsRow = m.CategoryGridList.cursorPosition[0] + 1
  newAnalyticsCol = m.CategoryGridList.cursorPosition[1] + 1

  if m.gridHasFocus = true and oldAnalyticsRow > 0 and oldAnalyticsCol > 0
    if oldAnalyticsRow <> newAnalyticsRow or oldAnalyticsCol <> newAnalyticsCol
      categoryComponentInfo = {
        category_slug: m.CategoryGridList.oldCategoryId
        category_row: oldAnalyticsRow
        'row is hardcoded to 1 in the line below because the row represents the row within the category_component, not within the grid
        'and the current design only has one row per category
        content_tile: m.Tracking.getAnalyticsTile(oldFocusedContent, oldAnalyticsCol, 1)
      }

      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage("home_page", {})
        componentOneof: m.Tracking.getAnalyticsComponent("category_component", categoryComponentInfo)
        means_of_navigation: "BUTTON"  'MeansOfNavigation enum
        vertical_location: newAnalyticsRow
        vertical_location_mode: "INDEX"  'LocationMode enum
        horizontal_location: newAnalyticsCol
        horizontal_location_mode: "INDEX"  'LocationMode enum
      }
    end if
  end if
  m.gridHasFocus = true
  m.listHasFocus = false
End Function

Function onGridItemSelected() As Void
  tubiLog("CategoryScreen.onGridItemSelected")
  selectedItem = m.CategoryGridList.itemSelected

  ' Set the tracking component of the item that was selected so it can be accessed as part of the navigateToPage event
  m.top.trackingComponentInfo = {
    componentType: "category_component"
    componentValues: {
      category_slug: m.top.currCategoryId
      category_row: m.top.selectedPosition[0] + 1  'all analytics are 1 based
      content_tile: m.Tracking.getAnalyticsTile(selectedItem, m.top.selectedPosition[1] + 1)
    }
  }

  ' Content controller observes contentSelected to populate/push the detail screen
  if selectedItem <> invalid then 
    m.top.contentSelected = selectedItem
    m.gridHasFocus = false
    m.listHasFocus = false
  end if
End Function


Function onTotalCountsChange(msg)
  tubiLog("CategoryScreen.onTotalCountsChange")
  totalCountInfo = msg.getData()

  for i=totalCountInfo.count()-1 to 0 Step -1
    categoryInList = m.categoryContent.getChild(i)
    categoryInList.totalCount = totalCountInfo[i]

    'category has no content, so we delete it here
    if categoryInList.totalCount = -1
      m.categoryContent.removeChildIndex(i)
    end if
  end for

  itemFocused = m.CategoryList.rowScrollFocused
  m.CategoryList.content = m.categoryContent
  m.CategoryGridList.content = m.categoryContent
  ' NOTE: Setting the content for the CategoryList forces a refresh of the
  ' CategorySeasonListItems but the side effect is the MarkupGrid focuses
  ' to the first item.  We counteract that here by explicitly setting
  ' the focus.
  m.CategoryList.jumpToItem = itemFocused
End Function


'''''''''''''''''''''
' loadAllCategories
'
' Load all category content, including . Series do not have season or episode information though.
Function loadAllCategories()
  tubiLog("CategoryScreen.loadAllCategories")
  ' This check causes all category fetches to be skipped prior to the field
  ' being set to true.  Then, once true it will reload any time loadCategories() is
  ' called, such as when signedIn field changes.
  if m.top.loadAllCategories = true
    reqName = m.constants.reqNames.getHomescreen
    '//::TODO:: JHAND - test error here!
    m.global.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("homescreen", m.top, "homescreenResponse", reqName)
    m.Spinner.visible = true
  end if
End Function


'@mode: string, one of the valid info panel modes (see InfoPanel.brs for details)
'@contentNode: content node
Function populateInfoPanel(mode, contentNode)
  if contentNode <> invalid
    if mode = "category"
      m.InfoPanel.mode = "category"
      m.InfoPanel.categoryContentCount = contentNode.totalCount
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description
      m.InfoPanel.titleLogoUri = contentNode.logoUri
    else if mode = "item"
      m.InfoPanel.mode = "item"
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description

      lineOneData = {}
      lineOneData.releaseDate = contentNode.releaseDate
      lineOneData.length = contentNode.length
      lineOneData.hasCC = (contentNode.hasSubtitles or not m._.empty(contentNode.subtitleTracks))
      lineOneData.rating = contentNode.rating
      lineOneData.partnerLogoUri = contentNode.inlineLogoUri

      m.InfoPanel.lineOneData = lineOneData
      m.InfoPanel.titleLogoUri = contentNode.titleLogoUri
      m.InfoPanel.genres = contentNode.genres
    end if

    m.InfoPanel.calculateHeight = true
  end if
End Function


Function sendDialogAnalyticsEvent(dialogType, trackingLib, trackingTask)
  trackingTask.trackEvent = {
    type: "dialog"
    values: {
      dialog_type: dialogType   'DialogType enum
      pageOneof: trackingLib.getAnalyticsPage("home_page", {})
    }
  }
End Function


Function onCategoryRefreshTimer()
  tubiLog("CategoryScreen.onCategoryRefreshTimer")
  loadAllCategories()
End Function


Function determineBackgroundImage(focusedContent)
  if focusedContent <> invalid and focusedContent.backgrounds <> invalid and focusedContent.backgrounds.count() > 0
   return focusedContent.backgrounds
  else
    return [m.defaultBackgroundUri]
  end if
End Function