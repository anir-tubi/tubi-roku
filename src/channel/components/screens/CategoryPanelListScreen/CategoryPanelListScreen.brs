Function init()
  m._ = rodash()
  '//This var is used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.contentLoadedAndFocused = false
  m.constants = getConstantsFromGlobal()
  '//keep track of the ID of the right panel that is in focus. invalid will mean the left panel is in focus
  '// This will be used to keep track of which panel was last in focus so when the screen is set to focus, then the correct panel will be set to focus
  m.rightPanelInFocusID = invalid

  m.top.instantResumeAction = m.constants.instantResumeActions.startChannel
  m.top.handlesTransportVoiceRequests = true
  m.leftPanelWidth = 495

  '//Hardcode the right panel width so the right panel's loading spinner is centered to the panel
  m.rightPanelWidth = 1062
  '//The offset sets the right panel to be placed at a different position than the menu list
  m.rightPanelOffset = [0, -36]

  m.Tracking = TubiTrackingInfo(m.constants)

  m.PageGroup = m.top.findNode("PageGroup")
  m.PageGroup.translation = [m.constants.ui.translations.marginX, 0]
  m.CategoryPanelGrid = m.top.findNode("PanelSet")

  ' Create the menu
  m.CategoryMenuPanel = createCategoryMenuPanel()
  m.CategoryMenuPanel.observeFieldScoped("createNextPanelIndex", "onCreateNextPanelIndex")
  m.CategoryMenuPanel.observeFieldScoped("itemSelected", "onItemSelected")
  m.CategoryMenuPanel.observeFieldScoped("itemFocused", "onItemFocused")
  m.CategoryPanelGrid.appendChild(m.CategoryMenuPanel)


  m.top.observeFieldScoped("reloadUserCategoriesResponse", "onReloadUserCategoriesResponse")
  m.top.observeFieldScoped("shouldLoadContent", "onLoadContent")
  m.top.observeFieldScoped("shouldLoadCategoryContent", "onLoadCategoryContent")
  m.top.observeFieldScoped("isLoading", "onIsLoading")
  m.top.observeFieldScoped("isCategoryLoading", "onIsCategoryLoading")
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("isCategoryFullyLoaded", "onIsFullyLoadedChange")
  m.top.observeFieldScoped("jumpToItemByID", "onJumpToItem")
  m.top.observeFieldScoped("jumpToCategoryItemByID", "onJumpToCategoryItem")
  m.top.observeFieldScoped("transportVoiceRequest", "onTransportVoiceRequest")

End Function


Function createCategoryMenuPanel()
  menuPanel = CreateObject("roSGNode", "CategoryMenuPanelList")
  menuPanel.width = m.leftPanelWidth
  menuPanel.leftPosition = 0
  menuPanel.focusable = true
  menuPanel.leftOnly = true
  '//::NOTE:: - The following line is used to hide the gradient. 
  '//     For some reason this is not necessary for the panelset on the Settings Screen. There is no visible gradient on that screen.
  menuPanel.maskUri = ""
  menuPanel.createNextPanelOnItemFocus = true
  menuPanel.selectButtonMovesPanelForward = true
  return menuPanel
End Function


Function onReloadUserCategoriesResponse()
  tubiLog("CategoryPanelListScreen.onReloadUserCategoriesResponse")
  newCategory = m.top.reloadUserCategoriesResponse

  if newCategory <> invalid
    bEmpty = true
    if newCategory.getChildCount() > 0
      '//this category has content
      bEmpty = false
    end if

    checkForContentAndRefresh(bEmpty, newCategory.id)
  end if
End Function


' checkForContentAndRefresh()
' @param bContentEmpty - Does the passed category have NO content?
' @param sCategoryID - The ID of the channel/category that is changing,
'
' When the content of a channel/category is known to have changed outside of this file, then this Function should be called
' to see if the content should be refreshed. If it should, then validUntil will be set to 0 so the next time this screen
' is on screen, then the content will be reloaded.
Function checkForContentAndRefresh(bContentEmpty, sCategoryID)
  tubiLog("CategoryPanelListScreen.checkForContentAndRefresh")

  '//Go thru the content and see if category associated with sCategoryID should be hidden or not
  if m.top.content <> invalid
    bRefresh = true
    bCategoryDisplayingOnScreen = false
    for i = 0 to m.top.content.getChildCount() - 1
      category = m.top.content.getChild(i)
      sID = category.id

      if sID = sCategoryID
        bCategoryDisplayingOnScreen = true
        exit for
      end if
    end for

    if bCategoryDisplayingOnScreen = true AND bContentEmpty = false
      '//no need to refresh the screen if the category is already displaying AND the category isn't empty
      bRefresh = false
    else if bCategoryDisplayingOnScreen = false AND bContentEmpty = true
      '//no need to refresh the screen if the empty category is already not displaying
      bRefresh = false
    end if

    if bRefresh = true
      m.top.content.validUntil = 0
    end if

    '//refresh the right panel
    if m.top.categoryContent <> invalid AND m.top.categoryContent.id = sCategoryID
      nextPanel = m.CategoryMenuPanel.nextPanel
      if nextPanel <> invalid
        nextPanel.content.validUntil = 0
      end if
    end if

  end if
End Function


' @content: roSGnode, ContentNode used to create the items in the Categories menu. Should be one
'                 of the DetailMenuItemContentNodes in CategoryPanelGrid.CategoryMenuPanel
Function createNextPanel(content)
  nextPanel = invalid
  if content <> invalid
    categoryDetailsPanel = CreateObject("roSGNode", "CategoryDetailsPanel")
    m.top.categoryTrackingLoadStartTime = UpTime(0)
    categoryDetailsPanel.observeFieldScoped("contentSelected", "onCategoryContentSelected")
    categoryDetailsPanel.observeFieldScoped("backgroundUriList", "onCategoryPanelBackgroundChange")
    categoryDetailsPanel.observeFieldScoped("backButtonPressed", "onBackButtonPressed")
    categoryDetailsPanel.observeFieldScoped("itemFocused", "onCategoryPanelFocusChanged")
    categoryDetailsPanel.observeFieldScoped("navigateWithinPageInfo", "onCategoryPanelNavigateWithinPageInfoChange")
    categoryDetailsPanel.observeFieldScoped("categoryBatchIndex", "onCategoryBatchIndexChange")
    categoryDetailsPanel.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
    categoryDetailsPanel.observeFieldScoped("contentToPlay", "onContentToPlay")

    categoryDetailsPanel.categoryId = content.id
    categoryDetailsPanel.isLoading = true

    categoryDetailsPanel.width = m.rightPanelWidth
    categoryDetailsPanel.focusable = true
    categoryDetailsPanel.hasNextPanel = false
    categoryDetailsPanel.leftOnly = false
    categoryDetailsPanel.selectButtonMovesPanelForward = false
    categoryDetailsPanel.offset = m.rightPanelOffset

    categoryDetailsPanel.trackingPageInfo = {
      pageType: "category_page"
      pageValues: {
        category_slug: content.id
      }
    }

    nextPanel = categoryDetailsPanel
  end if

  return nextPanel
End Function


Function onCategoryPanelFocusChanged(msg)
  TubiLog("CategoryPanelListScreen.onCategoryPanelFocusChanged")
  panel = msg.getRoSGNode()
  
  sOldRightPanelInFocusID = m.rightPanelInFocusID
  m.rightPanelInFocusID = panel.categoryID

  if sOldRightPanelInFocusID = invalid AND isNonEmptyString(m.rightPanelInFocusID) = true 
    '//The right-side category details panel gained focus by the user pressing the OK or RIGHT keys from the left-side Category List Menu

    '//Report a toggle_off from the category list menu
    pageInfo = m.top.trackingPageInfo
    item = m.CategoryMenuPanel.itemFocused
    categoryItem = m.top.content.getChild(item)
    trackingComponentInfo = {
      componentType: "browse_menu_component"
      componentValues: getTrackingCategoryComponent(item, m.CategoryMenuPanel.numColumns, categoryItem)
    }
    m.top.componentInteractionInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent(trackingComponentInfo.componentType, trackingComponentInfo.componentValues)
      user_interaction: "TOGGLE_OFF"
    }

    
    '//Report a toggle_on to the category detail panel
    pageInfo = m.CategoryMenuPanel.nextPanel.trackingPageInfo
    trackingComponentInfo = m.CategoryMenuPanel.nextPanel.trackingComponentInfo
    m.top.componentInteractionInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent(trackingComponentInfo.componentType, trackingComponentInfo.componentValues)
      user_interaction: "TOGGLE_ON"
    }

  end if
End Function


Function onCategoryPanelNavigateWithinPageInfoChange(msg)
  TubiLog("CategoryPanelListScreen.onCategoryPanelNavigateWithinPageInfoChange")
  navigateWithinPageInfo = msg.getData()
  m.top.navigateWithinPageInfo = navigateWithinPageInfo
End Function


Function onCategoryPanelBackgroundChange(msg)
  TubiLog("CategoryPanelListScreen.onCategoryPanelBackgroundChange")
  m.top.backgroundUriList = msg.getData() 
End Function


'// If the nextPanel shows the back button is pressed, focus goes back to the panelList
'// This happens when the nextPanel gets focus while still loading
'// Since there's nothing to focus on during loading, the panel signals the back button has been pressed.
Function onBackButtonPressed(msg)
  TubiLog("CategoryPanelListScreen.onBackButtonPressed")
  categoryDetailsPanel = msg.getRoSGNode()
  categoryDetailsPanel.setFocus(false)
  m.CategoryMenuPanel.setFocus(true)
End Function


Function onCategoryContentSelected(msg)
  TubiLog("CategoryPanelListScreen.onCategoryContentSelected")
  m.top.categoryContentSelected = msg.getData()
End Function


Function onContentToPlay(msg)
  TubiLog("CategoryPanelListScreen.onContentToPlay")
  m.top.contentToPlay = msg.getData()
End Function


Function onTransportVoiceResponse(msg)
  TubiLog("CategoryPanelListScreen.onTransportVoiceResponse")
  m.top.transportVoiceResponse = msg.getData()
End Function


Function onCategoryBatchIndexChange(msg)
  TubiLog("CategoryPanelListScreen.onCategoryBatchIndexChange")
  m.top.categoryBatchIndex = msg.getData()
End Function


Function onScreenFocusChange()
  tubiLog("CategoryPanelListScreen.onScreenFocusChange")
  if m.top.hasFocus() = true
    
    bRightPanelHasFocus = false
    if m.top.content <> invalid AND m.top.content.getChildCount() > 0
      if shouldRefresh(m.top.content) = true 'cacheValidationMixin
        m.top.refreshContent = true
      else if m.CategoryMenuPanel.nextPanel <> invalid AND m.rightPanelInFocusID = m.CategoryMenuPanel.nextPanel.categoryId
        bRightPanelHasFocus = true
      end if
    end if
    
    if bRightPanelHasFocus = true
      setFocusOnRightPanel()
    else
      m.CategoryMenuPanel.setFocus(true)
      if m.CategoryMenuPanel.nextPanel <> invalid
        '//If the left panel needs to be refreshed, then there is no need to check if the right panel needs to be refreshed
        '//If the right panel has focus, then there is no need to check if it needs to be refreshed as the check is done 
        '// upon the right panel gaining focus - just as it is done for the left panel in this function.
        m.CategoryMenuPanel.nextPanel.checkOnRefreshed = true
      end if
      ' Resetting the previous screens background if any present.
      m.top.backgroundUriList = []
    end if

  else if m.top.isInFocusChain() = false
    m.contentLoadedAndFocused = false
  end if
End Function


Function setFocusOnRightPanel()
  if m.CategoryMenuPanel.nextPanel <> invalid
    m.CategoryMenuPanel.nextPanel.shouldAnimateOnFocus = false
    '//temporarilly turn off the nextPanel's animated transition while it regains focus.
    '//   We can assume the user is coming back to this screen/panel from a detail screen judging by the value of the rightPanelInFocusID property
    m.CategoryMenuPanel.nextPanel.setFocus(true)
    m.CategoryMenuPanel.nextPanel.shouldAnimateOnFocus = true
  end if
End Function


Function onIsFullyLoadedChange(msg)
  tubiLog("CategoryPanelListScreen.onIsFullyLoadedChange")
  if m.CategoryMenuPanel <> invalid AND m.CategoryMenuPanel.nextPanel <> invalid
    m.CategoryMenuPanel.nextPanel.isFullyLoaded = msg.getData()
  end if
End Function


Function onLoadContent()
  tubiLog("CategoryPanelListScreen.onLoadContent")
  if m.top.content <> invalid
    m.CategoryMenuPanel.content = m.top.content
    onJumpToItem()
  end if
End Function


Function onLoadCategoryContent()
  tubiLog("CategoryPanelListScreen.onLoadCategoryContent")
  if m.top.categoryContent <> invalid AND m.top.contentFocused <> invalid AND m.top.contentFocused.id = m.top.categoryContent.id
    items = m.top.categoryContent
    categoryDetailsPanel = m.CategoryMenuPanel.nextPanel
    categoryDetailsPanel.content = items
    categoryDetailsPanel.isLoading = false
    categoryDetailsPanel.shouldLoadContent = true
    onJumpToCategoryItem()
  end if
End Function


Function onIsLoading(msg)
  tubiLog("CategoryPanelListScreen.onIsLoading")
  if msg.getData() = true
    m.top.content = invalid
    m.CategoryMenuPanel.content = invalid
    m.CategoryPanelGrid.visible = false
    if m.top.categoryContent <> invalid
      '//if the category list is loading, ensure the detail panel has to reload too.
      m.top.categoryContent.validUntil = 0
    end if
  else
    m.CategoryPanelGrid.visible = true
  end if
End Function


Function onIsCategoryLoading(msg)
  tubiLog("CategoryPanelListScreen.onIsCategoryLoading")
  isCategoryLoading = msg.getData()
  m.CategoryMenuPanel.selectButtonMovesPanelForward = not isCategoryLoading
  if m.CategoryMenuPanel <> invalid AND m.CategoryMenuPanel.nextPanel <> invalid
    m.CategoryMenuPanel.nextPanel.isLoading = isCategoryLoading
  end if
End Function


' Called when the panel needs to be called for the very 1st time
Function onCreateNextPanelIndex(msg)
  tubiLog("CategoryPanelListScreen.onCreateNextPanelIndex")
  nextIndex = msg.getData()
  createNextPanelAtIndex(nextIndex)
End Function


Function createNextPanelAtIndex(nIndex)
  tubiLog("CategoryPanelListScreen.createNextPanelAtIndex")
  if m.top.content <> invalid
    nextPanel = invalid

    buttonContent = m.top.content.getChild(nIndex)
    
    if m.CategoryMenuPanel.nextPanel = invalid OR (buttonContent.id <> m.CategoryMenuPanel.nextPanel.categoryId)
      nextPanel = createNextPanel(buttonContent)
      if nextPanel <> invalid
        m.CategoryMenuPanel.nextPanel = nextPanel
        m.top.categoryTrackingPageInfo = nextPanel.trackingPageInfo
        m.top.categoryId = buttonContent.id
        m.top.categoryContent = invalid
        m.top.contentFocused = buttonContent
      end if
    end if
    
  end if
End Function


Function onItemFocused(msg)
  tubiLog("CategoryPanelListScreen.onItemFocused")
  if m.top.content <> invalid
    CategoryMenuPanel = msg.getRoSGNode()
    m.rightPanelInFocusID = invalid
    item = CategoryMenuPanel.itemFocused
    m.top.itemFocused = item

    numColumns = CategoryMenuPanel.numColumns
    category = m.top.content.getChild(item)
    if m.contentLoadedAndFocused = true
      ' Do not send out tracking when the grid is initially loaded. When an item 1st gain focus, this indicates that the grid was just loaded.
      ' trigger navigate_within_page events in ContentController
      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("browse_menu_component", m.oldCategoryComponent)
        means_of_navigation: "SCROLL"  'MeansOfNavigation enum
        vertical_location: CategoryMenuPanel.list.currFocusRow + 1 ' Since focused index starts from zero.
        horizontal_location: 1
      }

      ' category component is used even though this is not an actual category, it can be modeled as a category
      ' of categories or a category of channels
      m.oldCategoryComponent = getTrackingCategoryComponent(item, numColumns, category)
    else
      m.oldCategoryComponent = getTrackingCategoryComponent(item, numColumns, category)
    end if

    m.contentLoadedAndFocused = true
  end if
End Function



Function onItemSelected()
  item = m.CategoryMenuPanel.itemSelected
  categoryItem = m.top.content.getChild(item)

  'Set the tracking component of the item that was selected so it can be accessed as part of the navigateToPage event
  m.top.trackingComponentInfo = {
    componentType: "category_component"
    componentValues: getTrackingCategoryComponent(item, m.CategoryMenuPanel.numColumns, categoryItem)
  }
  m.contentLoadedAndFocused = false
End Function


Function getTrackingCategoryComponent(item, numColumns, category)
  col = 1 + (item mod numColumns)
  row = 1 + (item \ numColumns)

  slug = ""
  if category <> invalid
    slug = category.slug
  end if

  return {
    category_row: row
    category_col: col
    category_slug: slug
  }
End Function


Function onJumpToItem()
  tubilog("CategoryPanelListScreen.onJumpToItem")
  sCategoryID = m.top.jumpToItemByID
  content = m.top.content
  
  if m.top.isLoading = false AND content <> invalid AND sCategoryID <> ""
    nodeHelpers = TubiNodeHelpers()
    index = nodeHelpers.getChildIndexById(content, sCategoryID)
    if index <> -1

      '//Get a copy of rightPanelInFocusID before it is reset when jumpToItem is called,
      tempRightPanelInFocusID = m.rightPanelInFocusID
      m.CategoryMenuPanel.jumpToItem = index
      m.top.jumpToItemByID = ""

      '//see if the right panel should be in focus. This may because the left panel needed to be reloaded and this function is called to go the previous focused item. 
      '// in this case, the right panel may have been in focus before the left panel was refreshed.
      if m.CategoryMenuPanel.nextPanel <> invalid AND tempRightPanelInFocusID = m.CategoryMenuPanel.nextPanel.categoryId
        setFocusOnRightPanel()
      end if

    else
      '//Reset the jumpToItem id when the content is loaded but the category id couldn't be found.
      m.top.jumpToItemByID = ""
    end if
  end if
End Function


Function onJumpToCategoryItem()
  tubilog("CategoryPanelListScreen.onJumpToCategoryItem")
  if m.top.jumpToCategoryItemByID <> invalid
    sCategoryID = m.top.jumpToCategoryItemByID.categoryId
    sTitleID = m.top.jumpToCategoryItemByID.contentId
    nextPanel = m.CategoryMenuPanel.nextPanel
    content = m.top.categoryContent
    
    if isNonEmptyString(sCategoryID) = true AND isNonEmptyString(sTitleID) = true AND nextPanel <> invalid

      if nextPanel.categoryId = sCategoryID
        if m.top.isCategoryLoading = false AND content <> invalid
          nodeHelpers = TubiNodeHelpers()
          index = nodeHelpers.getChildIndexById(content, sTitleID)
          if index <> -1
            nextPanel.jumpToItem = index
          end if
          '//ensure the right panel gains focus when the screen loads.
          if m.top.isInFocusChain() = true
            nextPanel.setFocus(true)
          else
            '//::TODO::JHAND - this looks wrong. it should be an AA unless jumpToItemByID was meant to be used
            '//If the screen is not yet in focus, then set jumpToCategoryItemByID in anticipation of when it will
            m.top.jumpToCategoryItemByID = sCategoryID
          end if
        else
          m.rightPanelInFocusID = sCategoryID
        end if
      else
        '//::TODO::JHAND - this looks wrong. it should be an AA unless jumpToItemByID was meant to be used
        '//The next panel has to match with the intended target
        m.top.jumpToCategoryItemByID = ""
      end if
    end if
  end if
End Function


Function onTransportVoiceRequest(msg)
  response = "unhandled"
  inputInfo = msg.getData()
  command = ""
  if inputInfo <> invalid AND inputInfo.command <> invalid
    command = inputInfo.command
  end if
  tubiLog("CategoryPanelListScreen.onTransportVoiceRequest " + command)

  bSendResponse = true
  if m.CategoryMenuPanel.nextPanel <> invalid AND m.CategoryMenuPanel.nextPanel.isLoading = false
    if m.CategoryMenuPanel.isInFocusChain() = true
      if command = "ok"
        m.CategoryMenuPanel.nextPanel.setFocus(true)
        response = "success"
      end if
    else if m.CategoryMenuPanel.nextPanel.isInFocusChain() = true
      bSendResponse = false
      m.CategoryMenuPanel.nextPanel.transportVoiceRequest = inputInfo
    end if
  end if

  if bSendResponse = true
    inputInfo.response = response
    m.top.transportVoiceResponse = inputInfo
  end if
End Function