Function init()
  tubiLog("CategoryScreen.init")
  m._ = rodash()
  m.NodeHelpers = TubiNodeHelpers()
  m.constants = m.global.constants
  m.ContentArea = m.top.findNode("ContentArea")
  m.CategoryList = m.top.findNode("CategoryList") 'aka category menu
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.FeatureInfo = m.top.findNode("FeatureInfo")
  m.HintGroup = m.top.findNode("UpHintGroup")
  m.FeatureDots = m.top.findNode("FeatureDots")
  fades = m.top.findNode("Fades")
  m.InfoPanelFade = fades.findNode("InfoPanelFade")
  m.FeatureInfoFade = fades.findNode("FeatureInfoFade")
  m.HintGroupFade = fades.findNode("HintGroupFade")
  m.Spinner = m.top.findNode("CategorySpinner")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("dirtyUserCategories", "onDirtyUserCategories")
  m.top.observeField("homescreenResponse", "onHomescreenResponse")
  m.top.observeField("reloadUserCategoriesResponse", "onReloadUserCategoriesResponse")
  m.top.observeField("trackingUri", "onTrackingUriChange")
  m.top.observeField("categoryMenuVisible", "onCategoryMenuVisible")
  m.top.observeField("loadAllCategories", "loadAllCategories")
  m.top.trackingCount = 0
  
  m.CategoryList.observeField("itemFocused","onCategoryMenuItemFocused")
  m.CategoryList.observeField("rowScrollFocused","onCategoryListScrollFocused")
  m.CategoryList.observeField("itemSelected", "onCategoryMenuSelected")
  m.categoryListIsFocused = false

  m.CategoryRefreshTimer = m.top.findNode("CategoryRefreshTimer")
  m.CategoryRefreshTimer.duration = m.constants.timers.categoryContentRefreshTimeout
  m.CategoryRefreshTimer.observeField("fire", "onCategoryRefreshTimer")
  m.CategoryRefreshTimer.control = "start"

  'Content area
  m.CategoryGridList = m.top.findNode("CategoryGridList")
  m.CategoryGridList.observeField("itemFocused", "onGridFocusChange")
  m.CategoryGridList.observeField("itemSelected", "onGridItemSelected")
  m.CategoryGridList.observeField("cursorPosition", "onGridCursorChange")
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

  m.singleFeaturePoster = false
  if m.constants.ui.categoryScreen.singleFeaturePoster <> invalid
     m.singleFeaturePoster = m.constants.ui.categoryScreen.singleFeaturePoster
  else
    m.singleFeaturePoster = (getExperimentValue("UserNamespace", "roku_single_feature_poster") = "single")
  end if

  ' Corrections for the XML values in case of not showing single feature poster
  if not m.singleFeaturePoster
    m.FeatureInfo.opacity = 0.0
    m.InfoPanel.opacity = 1.0
  end if
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
      if m.top.isInFocusChain() then m.CategoryGridList.setFocus(true)
    else
      testLog("Category list returned " + stri(response.code))
      ' if we were loading in the background, don't show an error modal
      if m.top.isInFocusChain() then showErrorModal(response.code, response.failReason, retryCategoryList, retryCategoryList)
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
Function onDirtyUserCategories(msg)
  tubiLog("CategoryScreen.onDirtyUserCategories")
  categoryId = msg.getData()

  if categoryId <> invalid
    url = m.constants.urls.matrix.container + "/" + categoryId
    options = {
      params: {
        "app_id": m.constants.settings.shortAppName,
        platform: m.constants.platform,
        "device_id": m.constants.deviceInfo.deviceId,
        limit: m.constants.performance.categoryGridList.finalBlockSize
        expand: 1,
        cursor: 0,
        includeEmpty: true
      }
    }

    'this will be an auth request if the user is logged in
    'auth request creation happens in metadataFetchTask
    'auth request will add the userId param
    reqName = m.constants.reqNames.getCategory
    m.global.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest(categoryId, m.top, "reloadUserCategoriesResponse", url, reqName, options)
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
    if m.categoryListIsFocused = false
    ' defaulted to screen, move to a subcomponent
      m.CategoryGridList.setFocus(true)
    else
      m.CategoryList.setFocus(true)
      m.categoryListIsFocused = true
    end if
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
    fade(m.InfoPanel, "in", 0.4)  ' if feature row is focused on the grid, the info panel would be hidden
    m.CategoryList.jumpToItem = Int(m.CategoryGridList.currFocusRow)
    m.CategoryList.setFocus(true)
    m.categoryListIsFocused = true
    if m.global.constants.deviceInfo.limitedUi
      m.ContentArea.translation = [517,m.ContentArea.translation[1]]
      m.CategoryList.translation = [60,m.CategoryList.translation[1]]
    else
      slideTo(m.ContentArea, [517,m.ContentArea.translation[1]], 0.5)
      slideTo(m.CategoryList, [60,m.CategoryList.translation[1]], 0.5)
    end if
    m.trackingCount = 0
    m.CategoryGridList.isFullWidth = false
    m.top.backgroundUriList = [m.defaultBackgroundUri]
  end if
End Function


Function hideCategoryMenu()
  if m.CategoryList.isInFocusChain()
    m.CategoryGridList.setFocus(true)
    m.categoryListIsFocused = false
    if m.CategoryGridList.currFocusRow = 0 and m.singleFeaturePoster = true
      m.InfoPanel.opacity = 0.0   ' hide info panel if category grid will show the feature row
    end if
    if m.global.constants.deviceInfo.limitedUi
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
  end if

  populateInfoPanel(m.InfoPanel, "category", infoMetadata)

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
' When signed in/out changes, we need to reload all categories to 
' reflect changes in parental controls between guest and signed-in
' users
Function onSignedInChange()
  tubiLog("CategoryScreen.onSignedInChange")
  loadAllCategories()
End Function

Function onCurrFocusRow()
  if m.CategoryGridList.currFocusRow >= 1
    animationFraction = 1.0
  else
    animationFraction = m.CategoryGridList.currFocusRow
  end if

  m.HintGroupFade.fraction = animationFraction
  if m.singleFeaturePoster = true
    if m.CategoryGridList.isInFocusChain()
      ' If category menu is focused, info panel shows category description so don't hide it
      m.InfoPanelFade.fraction = animationFraction
    end if
    m.FeatureInfoFade.fraction = animationFraction
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
  if focusedContent <> invalid
    if m.CategoryGridList.currFocusRow = 0 and m.singleFeaturePoster = true
      populateInfoPanel(m.FeatureInfo, "item", focusedContent)

      ' Show the position dots
      totalCount = 0
      if m.categoryContent <> invalid
        referenceCategory = m.categoryContent.findNode(m.constants.ui.categoryIds.featured)
        if referenceCategory <> invalid
          totalCount = referenceCategory.totalCount
        end if
      end if
      m.FeatureDots.removeChildrenIndex(m.FeatureDots.getChildCount(), 0)
      dots = m.FeatureDots.createChildren(totalCount, "Poster")
      for i=0 to dots.count()-1
        dots[i].width = 8
        dots[i].height = 8
        dots[i].uri = "pkg:/images/dot.png"
        dots[i].blendColor = "0xffffff50"
        if m.CategoryGridList.cursorPosition[1] = i
          dots[i].blendColor = "0xff501a"
        end if
      end for

    else
      populateInfoPanel(m.InfoPanel, "item", focusedContent)
    end if
  end if

  ' If focus is on an empty category, leave the background as is.  This helps avoid
  ' background jank and keeps CPU usage down while categories are being fetched.
  if focusedContent <> invalid
    if focusedContent.backgrounds <> invalid and focusedContent.backgrounds.count() > 0 then
      m.top.backgroundUriList = focusedContent.backgrounds
    else
      m.top.backgroundUriList = [m.defaultBackgroundUri]
    end if
  end if

  'update the tracking URI
  m.top.trackingUri = updateTrackingUri(m.CategoryGridList.cursorPosition)
End Function

Function onGridItemSelected() As Void
  tubiLog("CategoryScreen.onGridItemSelected")
  m.top.trackingCount = 0
  selectedItem = m.CategoryGridList.itemSelected

  m.top.trackingUri = updateTrackingUri(m.CategoryGridList.selectedPosition)

  if selectedItem <> invalid then 
    m.top.contentSelected = selectedItem
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

  itemFocused = m.CategoryList.itemFocused
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
    ' TODO(Chris): This should move to a shim layer which hides specifics of the Tubi v4 API
    settings = m.global.constants.settings
    platform = m.global.constants.platform
    deviceInfo = m.global.constants.deviceInfo
    url = m.global.constants.urls.matrix.homescreen
    options = {
      params: {
        "app_id": settings.shortAppName
        platform: platform
        "device_id": deviceInfo.deviceId
        expand: 2
        includeEmpty: true
        limit: m.constants.performance.categoryGridList.initialBlockSize
      }
    }
    reqName = m.constants.reqNames.getHomescreen
    m.global.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("homescreen", m.top, "homescreenResponse", url, reqName, options)
    m.Spinner.visible = true
  end if
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


'@target: either the m.InfoPanel or m.FeatureInfo, depending on which panel is showing
'@mode: string, one of the valid info panel modes (see InfoPanel.brs for details)
'@contentNode: content node
Function populateInfoPanel(target, mode, contentNode)
  if contentNode <> invalid and target <> invalid
    if mode = "category"
      target.mode = "category"
      target.categoryContentCount = contentNode.totalCount
      target.title = contentNode.title
      target.description = contentNode.description
    else if mode = "item"
      target.mode = "item"
      target.title = contentNode.title
      target.description = contentNode.description
      target.releaseDate = contentNode.releaseDate
      target.length = contentNode.length
      target.rating = contentNode.rating
      target.genres = contentNode.genres
      target.hasCC = (contentNode.hasSubtitles or not m._.empty(contentNode.subtitleTracks))
    end if

    target.calculateHeight = true
  end if
End Function


' returns a tracking uri that can be added to CategoryScreen.trackingUri for navigation and page load tracking
' @position, 2d array, where index 0 is the category row index and index 1 is the column or position with the category
Function updateTrackingUri(position)
  catSlug = m.CategoryGridList.currCategoryId + "/"

  row = 1  'row is fixed at 1 for this design, it indicates the row within the category
  col = 0  'column is the column within the category, expect this to change
  catPos = 0  'catPos is the order of the category (Featured should be 1)
  if position[0] >= 0
    catPos = position[0] + 1
    col = position[1] + 1
  end if

  'set the user event tracking info
  row = row.toStr() + "/"
  col = col.toStr()
  catPos = catPos.toStr()
  trackingUri = "/home/" + catPos + "/cat/" + catSlug + row + col

  return trackingUri
End Function


Function onCategoryRefreshTimer()
  tubiLog("CategoryScreen.onCategoryRefreshTimer")
  loadAllCategories()
End Function