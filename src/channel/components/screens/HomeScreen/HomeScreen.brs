Function init()
  tubiLog("HomeScreen.init")
  m._ = rodash()
  m.NodeHelpers = TubiNodeHelpers()
  m.constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.trackingLoggingTask = m.global.trackingLoggingTask
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.ContentArea = m.top.findNode("ContentArea")
  m.NavSection = m.top.findNode("nav")
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.HintGroup = m.top.findNode("UpHintGroup")
  fades = m.top.findNode("Fades")
  m.HintGroupFade = fades.findNode("HintGroupFade")
  m.Spinner = m.top.findNode("CategorySpinner")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("reloadUserCategoriesResponse", "onReloadUserCategoriesResponse")
  m.top.observeField("categoryMenuVisible", "onCategoryMenuVisible")
  m.top.observeField("enabled", "onEnableChange")
  m.top.observeField("isLoading", "onLoadingChange")
  m.top.observeField("contentUpdated", "onCategoryContentUpdated")

  m.CategoryRefreshTimer = m.top.findNode("CategoryRefreshTimer")
  m.CategoryRefreshTimer.duration = m.constants.timers.categoryContentRefreshTimeout
  m.CategoryRefreshTimer.observeField("fire", "onCategoryRefreshTimer")
  m.CategoryRefreshTimer.control = "start"

  'Content area
  m.CategoryGridList = m.top.findNode("CategoryGridList")
  m.CategoryGridList.observeField("itemSelected", "onGridItemSelected")
  m.CategoryGridList.observeField("itemFocused", "onGridFocusChange")
  m.CategoryGridList.observeField("categoryTotalCounts", "onTotalCountsChange")

  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()

  'used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.gridHasFocus = false

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "home_page"
    pageValues: {}
  }

  m.top.screenLevel = m.constants.ui.screenLevels.homeScreen
End Function

Function onLoadingChange()
  m.Spinner.visible = m.top.isLoading
  bLoaded = (m.top.isLoading = false)
  m.CategoryGridList.visible = bLoaded
  if m.top.isLoading = true
    m.CategoryGridList.content = invalid
  end if
  m.InfoPanel.visible = bLoaded
End Function


Function onCategoryContentUpdated()
  m.InfoPanel.mode = "category"
  if m.top.content <> invalid
    populateInfoWithFirstItem(m.top.content)
  end if
  m.CategoryGridList.content = m.top.content  ' should be all categories with initial amounts of content in them
  m.top.isLoading = false
End Function


''''''''''''''''''''''''''''
' populateInfoWithFirstItem
'
' When the content first loads, this is called to ensure the 1st item populates the info panel. 
' If this function were not called and the homescreen lost focus (i.e. side menu gained focus) then the info panel would be vacant.
Function populateInfoWithFirstItem(categoryContent)
  contentId = invalid
  if categoryContent <> invalid
    category = categoryContent.getChild(0)
    if category <> invalid
      content = category.getChild(0)
      if content <> invalid
        contentId = content.id
      end if
    end if
    if contentId <> invalid and contentId <> ""
      metadataTranslate = TubiMetadataTranslate(m.constants)
      item = metadataTranslate.getContentFromCategoryJson(category, contentId)
      populateInfoPanel("item", item)
      if item <> invalid
        m.top.backgroundUriList = determineBackgroundImage(item)
      end if
    end if
  end if
End Function


Function onEnableChange()
  if m.top.enabled = true
    fade(m.NavSection, "in", 0.3)
  else
    fade(m.NavSection, "out", 0.3)
  end if
End Function


Function onReloadUserCategoriesResponse()
  handledRequest = m.top.reloadUserCategoriesResponse
  tubiLog("HomeScreen.onReloadUserCategoriesResponse")
  if handledRequest.response <> invalid then
    response = handledRequest.response
    if response.code >= 200 and response.code < 300 then
      newCategory = handledRequest.convertedMetadata

      if m.top.content <> invalid
        oldCategory = invalid
        if newCategory <> invalid and newCategory.id <> invalid
          oldCategory = m.top.content.findNode(newCategory.id)
        else if handledRequest.context.id <> invalid
          oldCategory = m.top.content.findNode(handledRequest.context.id)
        end if

        ' there are 4 options here
        ' 1) new category and old category both have content in them - replace the old with the new
        ' 2) new category has content, old category doesn't exist - add the new category
        ' 3) new category doesn't have content (will be invalid), old category does have content - remove old category
        ' 4) new category doesn't have content (will be invalid), old category doesn't exist - do nothing
        if newCategory <> invalid and oldCategory <> invalid
          'replace old category with new category
          m.top.content.replaceChild(newCategory, m.NodeHelpers.getChildIndex(m.top.content, oldCategory))
        else if newCategory <> invalid and oldCategory = invalid
          'add new category
          'if new category is history, put it one before queue, or if queue doens't exist put it in 2nd position
          'if new category is queue put it one after history, or if history doesn't exist, put it in 2nd position
          if newCategory.id = m.constants.ui.categoryIds.history
            queueIndex = m.NodeHelpers.getChildIndexById(m.top.content, m.constants.ui.categoryIds.queue)
            insertPos = 1
            if queueIndex > -1
              insertPos = queueIndex
            end if
            m.top.content.insertChild(newCategory, insertPos)
          else if newCategory.id = m.constants.ui.categoryIds.queue
            historyIndex = m.NodeHelpers.getChildIndexById(m.top.content, m.constants.ui.categoryIds.history)
            insertPos = 1
            if historyIndex > -1
              insertPos = historyIndex + 1
            end if
            m.top.content.insertChild(newCategory, insertPos)
          end if
        else if newCategory = invalid and oldCategory <> invalid
          'remove old category
          m.top.content.removeChild(oldCategory)
        else if newCategory = invalid and oldCategory = invalid
          'do nothing
        end if

        'reset the categoryGridList content so the changes display in the RowList
        categoryContent = m.top.content
        m.CategoryGridList.content = categoryContent
      end if

      m.top.isLoading = false

      ' if m.CategoryGridList.content <> invalid
      '   ' Make sure any user categories which didn't get newly added are reloaded
      '   for each userCategory in [m.constants.ui.categoryIds.history, m.constants.ui.categoryIds.queue]
      '     childNode = m.CategoryGridList.content.findNode(userCategory)
      '     if childNode <> invalid
      '       m.CategoryGridList.content.replaceChild(childNode.clone(false), m.NodeHelpers.getChildIndex(m.CategoryGridList.content, childNode))
      '     end if
      '   end for
      ' else
      '   m.CategoryGridList.content = m.top.content  ' should be all categories with initial amounts of content in them
      ' end if
      ' if m.top.isInFocusChain() then m.CategoryGridList.setFocus(true)
    else
      ' if we were loading in the background, don't show an error modal
      if m.top.isInFocusChain()
        errorMessage = "Unable to load some categories."
        errorCode = getUserFacingErrorCode(m.constants.errors.context.homeScreen, m.constants.errors.subtypes.fetchError, response.code)
        dialogEvent = getHomescreenDialogAnalyticsEvent("NETWORK_ERROR", errorCode, m.Tracking)
        
        modalInfo = {
          message: getErrorMessage(errorMessage, errorCode)
          openTrackEvent: dialogEvent
          trackingTask: m.trackingLoggingTask
        }

        showErrorModal(modalInfo, onUserCategoriesFailed, invalid, invalid, invalid, ["Continue"])
      end if
    end if
  end if
End Function


Function onUserCategoriesFailed()
  tubiLog("Homescreen.onUserCategoriesFailed")
  if m.top.content = invalid
    m.top.loadAllCategories = true
  end if
End Function


''''''''''''''''''''
' onScreenFocusChange
'
' Set focus back to category list or component group if the
' screen has lost focus, usually due to another screen or dialog
' being shown.
Function onScreenFocusChange()
  tubiLog("HomeScreen.onScreenFocusChange " + focusState(m.top))
  if m.top.hasFocus()
    m.CategoryGridList.setFocus(true)
    m.gridHasFocus = true
    if m.CategoryGridList.content <> invalid and shouldRefresh(m.CategoryGridList.content) = true
      m.top.loadAllCategories = true
    end if
  else if m.top.isInFocusChain() = false
    m.gridHasFocus = false
  end if
End Function


'''''''''''''''''''''''''''
' onSignedInChange
'
' When signed in/out changes, we need to reload all categories to 
' reflect changes in parental controls between guest and signed-in
' users
Function onSignedInChange()
  tubiLog("HomeScreen.onSignedInChange")
  m.top.loadAllCategories = true
End Function


'''''''''''''''''''''
' onGridFocusChange
'
' On grid focus change, update the info panel
Function onGridFocusChange() As Void
  tubiLog("HomeScreen.onGridFocusChange")
  if not m.CategoryGridList.isInFocusChain() or m.top.isLoading = true then return

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
End Function

Function onGridItemSelected() As Void
  tubiLog("HomeScreen.onGridItemSelected")
  if m.top.isLoading <> true
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
  end if
End Function


Function onTotalCountsChange(msg)
  tubiLog("HomeScreen.onTotalCountsChange")
  totalCountInfo = msg.getData()

  for i=totalCountInfo.count()-1 to 0 Step -1
    categoryInList = m.top.content.getChild(i)
    categoryInList.totalCount = totalCountInfo[i]

    'category has no content, so we delete it here
    if categoryInList.totalCount = -1
      m.top.content.removeChildIndex(i)
    end if
  end for

  m.CategoryGridList.content = m.top.content
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


Function getHomescreenDialogAnalyticsEvent(dialogType, dialogSubtype, trackingLib)
  return {
    type: "dialog"
    values: {
      dialog_type: dialogType 'DialogType enum - TODO: Update this when a "PLAYER_ERROR" value becomes available in protos
      pageOneof: trackingLib.getAnalyticsPage("home_page", {})
      dialog_action: "SHOW"
      dialog_sub_type: dialogSubtype
    }
  }
End Function


Function onCategoryRefreshTimer()
  tubiLog("HomeScreen.onCategoryRefreshTimer")
  m.top.loadAllCategories = true
End Function


Function determineBackgroundImage(focusedContent)
  if focusedContent <> invalid and focusedContent.backgrounds <> invalid and focusedContent.backgrounds.count() > 0
   return focusedContent.backgrounds
  else
    return [m.defaultBackgroundUri]
  end if
End Function