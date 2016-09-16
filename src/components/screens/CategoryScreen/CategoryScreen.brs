Function init()
  tubiLog("CategoryScreen.init")
  m.CategoryList = m.top.findNode("CategoryList")
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.SpecialCategories = m.top.findNode("SpecialCategories")
  m.Hero = m.top.findNode("HeroBackground")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("categoryResponse", "onCategoryContentReceived")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("dirtyUserCategories", "onDirtyUserCategories")
  m.top.observeField("categoryListResponse", "onCategoriesReceived")
  m.top.observeField("trackingUri", "onTrackingUriChange")
  m.CategoryList.observeField("itemFocused","onCategoryChange")
  m.authTask = m.top.findNode("CategoryAuthTask")

  'Content area
  m.PosterGrid = m.top.findNode("PosterGrid")
  m.PosterGrid.observeField("itemFocused","onGridFocusChange")
  m.PosterGrid.observeField("itemSelected","onGridItemSelected")
  m.FeatureGrid = m.top.findNode("FeatureGrid")
  m.FeatureGrid.observeField("itemFocused","onGridFocusChange")
  m.FeatureGrid.observeField("itemSelected","onGridItemSelected")
  m.SignInMenu = m.top.findNode("SearchSignInList")
  m.SignInMenu.observeField("itemSelected", "onSignInMenuItemSelected")
  m.ContentGrid = m.PosterGrid  ' alias to simplify the code
  m.Spinner = m.top.findNode("CategorySpinner")

  'Sign-in menu items
  m.SearchSignInContent = m.top.findNode("SearchSignInContent")
  m.SearchMenuItem = m.SearchSignInContent.findNode("SearchMenuItem")
  m.SignInMenuItem = m.SearchSignInContent.findNode("SignInMenuItem")
  m.SignOutMenuItem = m.SearchSignInContent.findNode("SignOutMenuItem")
  m.AboutMenuItem = m.SearchSignInContent.findNode("AboutMenuItem")

  'Special categories
  m.ContinueWatchingCategory = m.SpecialCategories.findNode("ContinueWatching")
  m.MyQueueCategory = m.SpecialCategories.findNode("MyQueue")
  m.SearchSignInCategory = m.SpecialCategories.findNode("SearchSignIn")
  m.SearchSignOutCategory = m.SpecialCategories.findNode("SearchSignOut")

  m.defaultHeroUri = "pkg:/images/grid-default-blurred.jpg"

  ' track the last focused screen component so that we can go back
  ' to it when focus is taken away
  m.lastFocusedComponent = m.CategoryList
  m.featureCategoryFocused = false

  onSignedInChange()  ' seed the search & sign in menu

  loadUserCategories()
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
      m.top.content = m.top.categoryListResponse.convertedMetadata
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
End Function

''''''''''''''''''''''''''''
' onDirtyUserCategories
'
' if one of the user categories is showing, reload it
Function onDirtyUserCategories()
  tubiLog("CategoryScreen.onDirtyUserCategories")
  category = m.CategoryList.content.getChild(m.CategoryList.itemFocused)
  if category.title = m.global.constants.ui.categoryNames.history
    m.ContentGrid.content = invalid  ' hide the current content so it doesn't jump when updated
    loadHistory(category.id)      
  else if category.title = m.global.constants.ui.categoryNames.queue
    m.ContentGrid.content = invalid  ' hide the current content so it doesn't jump when updated
    loadBookmarks(category.id)  
  end if
End Function

'''''''''''''''''''''''''''
' onSignInMenuItemSelected
'
Function onSignInMenuItemSelected()
  tubiLog("CategoryScreen.onSignInMenuItemSelected")
  selectedItem = m.SignInMenu.content.getChild(m.SignInMenu.itemSelected)
  if selectedItem.id = "SearchMenuItem" then
    m.top.searchSelected = true
  else if selectedItem.id = "SignInMenuItem" then
    m.top.signInSelected = true
  else if selectedItem.id = "SignOutMenuItem" then
    m.top.signOutSelected = true
  else if selectedItem.id = "AboutMenuItem" then
    m.top.aboutSelected = true
  end if
End Function

''''''''''''''''''''
' onScreenFocusChange
'
' Set focus back to category list or component group if the
' screen has lost focus, usually due to another screen or dialog
' being shown.
Function onScreenFocusChange()
  tubiLog("CategoryScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    ' defaulted to screen, move to a subcomponent
    if m.ContentGrid.visible = true then
      m.ContentGrid.setFocus(true)
    else if m.SignInMenu.visible = true then
      m.SignInMenu.setFocus(true)
    else
      m.CategoryList.setFocus(true)
    end if
  end if
End Function


''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("CategoryScreen.onKeyEvent")
  if press then
    if key = "right" and m.CategoryList.isInFocusChain() then
      if m.ContentGrid.visible = true then
        m.ContentGrid.setFocus(true)
      else if m.SignInMenu.visible = true then
        m.SignInMenu.setFocus(true)
      end if
      return true
    else if key = "left" and not m.CategoryList.isInFocusChain() then
      m.CategoryList.setFocus(true)
      return true
    else if (key = "down" or key = "up") and not m.CategoryList.isInFocusChain() then
      m.CategoryList.setFocus(true)
      if key = "up" then m.CategoryList.animateToItem = m.CategoryList.itemFocused - 1
      if key = "down" then m.CategoryList.animateToItem = m.CategoryList.itemFocused + 1
      return true
    end if
  end if

  return false
End Function


'''''''''''''''''''''
' onContentChange
'
' Handle category list received
Function onContentChange() As Void
  tubiLog("CategoryScreen.onContentChange")
  m.CategoryList.visible = false
  m.CategoryList.content = invalid  ' since alwaysNotify=false on scrollinglist
  ' Force Featured to the top of the list
  for i=0 to m.top.content.getChildCount()-1
    category = m.top.content.getChild(i)
    if category.title = "Featured"
      m.top.content.removeChild(category)
      m.top.content.insertChild(category, 0)
      exit for
    end if
  end for

  ' Prepend special categories, taking care to remove them if they already are there
  m.InfoPanel.mode = "category"
  if m.top.signedIn then
    m.top.content.removeChild(m.SearchSignInCategory)
    m.top.content.insertChild(m.SearchSignOutCategory, 0)
    m.top.content.insertChild(m.ContinueWatchingCategory, 1)
    m.top.content.insertChild(m.MyQueueCategory, 2)
  else
    m.top.content.removeChild(m.SearchSignOutCategory)
    m.top.content.removeChild(m.ContinueWatchingCategory)
    m.top.content.removeChild(m.MyQueueCategory)
    m.top.content.insertChild(m.SearchSignInCategory, 0)
  end if

  m.CategoryList.content = m.top.content
  if m.top.isInFocusChain() then m.CategoryList.setFocus(true)
  m.featureCategoryFocused = false
End Function


''''''''''''''''''''''''''
' onCategoryContentReceived
'
Function onCategoryContentReceived() As Void
  tubiLog("CategoryScreen.onCategoryContentReceived")
  response = m.top.categoryResponse.response
  if response.code >= 200 and response.code < 300 then 
    content = m.top.categoryResponse.convertedMetadata
    m.Spinner.visible = false

    if m.ContentGrid.isSameNode(m.PosterGrid) then
      if content.getChildCount() > 8 then
        m.ContentGrid.numRows = 2
      else
        m.ContentGrid.numRows = 1
      end if
    end if
    m.ContentGrid.content = content

    if m.CategoryList.isInFocusChain() then
      m.InfoPanel.content.totalCount = content.getChildCount()
    end if
  else
    testLog("Category content returned " + stri(response.code))
    if m.top.isInFocusChain() then showErrorModal(response.code, response.failReason, retryCategoryContent, cancelCategoryContent)
  end if
End Function

' try to reload the current category
Function retryCategoryContent()
  m.CategoryList.setFocus(true)
  m.ContentGrid.id = ""  ' won't retry unless this doesn't match
  onCategoryChange()
End Function

' Just set focus to category list
Function cancelCategoryContent()
  m.CategoryList.setFocus(true)
End Function


'''''''''''''''''''''
' onCategoryChange
'
' On category focus change, update the info panel
Function onCategoryChange() As Void
  tubiLog("CategoryScreen.onCategoryChange")
  if not m.CategoryList.isInFocusChain() or m.CategoryList.content = invalid then return

  ' Only on the first trigger of 'itemFocused' from the category list,
  ' set the focus to Featured.  This has to be done here and not when
  ' 'content' is set on ScrollingList due to a race condition.
  if m.featureCategoryFocused = false then
    for i=0 to m.CategoryList.content.getChildCount()-1
      category = m.CategoryList.content.getChild(i)
      if category.title = "Featured" then
        tubiLog("Setting focus on Featured category")
        m.CategoryList.animateToItem = i
        exit for
      end if
    end for
    m.featureCategoryFocused = true
    return
  else
    ' We keep the categorylist hidden until Feature is focused
    m.CategoryList.visible = true
  end if

  'unobserve historyOrder and bookmarkOrder fields since if we are changing category,
  'we are no longer concerned about any categories we may have been waiting for
  m.global.unobserveField("bookmarkOrder")
  m.global.unobserveField("historyOrder")

  newCategory = m.CategoryList.content.getChild(m.CategoryList.itemFocused)
  m.InfoPanel.content = newCategory
  m.InfoPanel.mode = "category"
  m.Hero.uri = m.defaultHeroUri

  if newCategory.id <> m.ContentGrid.id then
    m.SignInMenu.visible = false
    m.ContentGrid.content = invalid
    m.ContentGrid.visible = false

    ' Flip between feature grid, poster grid, and sign in menu
    if newCategory.title = m.global.constants.ui.categoryNames.topCategory
      m.ContentGrid = m.top.findNode("FeatureGrid")
      m.ContentGrid.visible = true
      m.Spinner.visible = true
      loadOneCategory(newCategory.id)

    'Search and Sign In
    else if newCategory.title = m.global.constants.ui.categoryNames.signedInTools or newCategory.title = m.global.constants.ui.categoryNames.signedOutTools
      m.SignInMenu.visible = true

    'Continue Watching
    else if newCategory.title = m.global.constants.ui.categoryNames.history
      m.ContentGrid = m.top.findNode("PosterGrid")
      m.ContentGrid.visible = true
      m.Spinner.visible = true
      loadHistory(newCategory.id)      

    'My Queue
    else if newCategory.title = m.global.constants.ui.categoryNames.queue
      m.ContentGrid = m.top.findNode("PosterGrid")
      m.ContentGrid.visible = true
      loadBookmarks(newCategory.id)  

    'any normal category
    else
      m.ContentGrid = m.top.findNode("PosterGrid")
      m.ContentGrid.visible = true
      m.Spinner.visible = true
      loadOneCategory(newCategory.id)
    end if

    m.ContentGrid.id = m.CategoryList.content.getChild(m.CategoryList.itemFocused).id

    'update the tracking URI for user tracking purposes
    catPos = (m.CategoryList.itemFocused + 1).toStr()
    catSlug = ""
    if newCategory.slug <> invalid
      catSlug = newCategory.slug
    end if
    m.top.trackingUri = "/home/" + catPos + "/cat/" + catSlug

  end if
End Function


'''''''''''''''''''''''''''
' onSignedInChange
'
' Create a new content node tree for the sign in menu, based on the template SearchSignInContent.
' We do this so that we can keep a reference to all possible menu options, even when the sign in
' menu is showing a subset.
Function onSignedInChange()
  tubiLog("CategoryScreen.onSignedInChange")
  content = CreateObject("roSGNode", "ContentNode")
  content.appendChild(m.SearchMenuItem)
  if m.top.signedIn = true then
    content.appendChild(m.SignOutMenuItem)
  else
    content.appendChild(m.SignInMenuItem)
  end if  
  content.appendChild(m.AboutMenuItem)
  m.SignInMenu.content = content

  if m.top.content <> invalid then
    onContentChange()
  end if

  ' Clear out the history and queue
  m.global.bookmarkIds = {}
  m.global.bookmarkOrder = []
  m.global.historyIds = {}
  m.global.historyOrder = []
  if m.top.signedIn = true then
    loadUserCategories()
  end if
End Function


'''''''''''''''''''''
' onGridFocusChange
'
' On grid focus change, update the info panel
Function onGridFocusChange() As Void
  tubiLog("CategoryScreen.onGridFocusChange")

  if not m.ContentGrid.isInFocusChain() then return
  focusedContent = m.ContentGrid.content.getChild(m.ContentGrid.itemFocused)
  m.InfoPanel.content = focusedContent
  m.InfoPanel.mode = "item"

  if focusedContent.backgrounds <> invalid and focusedContent.backgrounds.count() > 0 then
    m.Hero.uri = focusedContent.backgrounds[0]
  else
    m.Hero.uri = m.defaultHeroUri
  end if

  'update the tracking URI
  catSlug = ""
  if m.CategoryList.content.getChild(m.CategoryList.itemFocused) <> invalid
    if m.CategoryList.content.getChild(m.CategoryList.itemFocused).slug <> invalid
      catSlug = m.CategoryList.content.getChild(m.CategoryList.itemFocused).slug + "/"
    end if
  end if
  catPos = (m.CategoryList.itemFocused + 1).toStr()
  
  row = 0
  col = 0
  if m.CategoryList.itemFocused >= 0
    'row and column should be 1-indexed
    modulus = m.ContentGrid.itemFocused MOD m.ContentGrid.numRows
    row = modulus + 1 
    col = Int(m.ContentGrid.itemFocused / m.ContentGrid.numRows) + 1
  end if

  row = row.toStr() + "/"
  col = col.toStr()
  m.top.trackingUri = "/home/" + catPos + "/cat/" + catSlug + row + col

End Function

Function onGridItemSelected() As Void
  tubiLog("CategoryScreen.onGridItemSelected")
  m.top.contentSelected = m.ContentGrid.content.getChild(m.ContentGrid.itemSelected)
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
  request = {
    url: url
    node: m.top
    field: "categoryListResponse"
    name: "getAllCategories"
    options: {
      params: {
        "app_id": settings.shortAppName
        platform: platform
        "device_id": deviceInfo.deviceId
        page_enabled: false
      }
    }
  }
  m.global.metadataFetchTask.request = request
End Function

'''''''''''''''''''''
' loadOneCategory
'
' Load a single category's content
Function loadOneCategory(categoryId As String)
  tubiLog("CategoryScreen.loadOneCategory")
  settings = m.global.constants.settings
  url = m.global.constants.urls.cms.categories
  platform = m.global.constants.platform
  deviceInfo = m.global.constants.deviceInfo
  constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, constants)

  historyOrder = m.global.historyOrder
  bookmarkOrder = m.global.bookmarkOrder

  request = {
    url: url
    name: "getCategory"    
    node: m.top
    field: "categoryResponse"
    options: {
      params: {
        "app_id": settings.shortAppName
        platform: platform
        "device_id": deviceInfo.deviceId
        "cat_id": categoryId
        all: false
        page_enabled: false
      }
    }
  }

  if constants.deviceInfo.lowMemory then
    request.options.params.page_enabled = true
    request.options.params.per_page = 100
  end if

  ' first cancel any outstanding metadata requests for this screen
  m.global.metadataFetchTask.cancel = { node: request.node, field: request.field }
  m.global.metadataFetchTask.request = request
End Function


'''''''''''''''''''''
' loadHistory
'
' Load the user's history content for "Continue Watching"
Function loadHistory(categoryId As String)
  constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, constants)

  historyOrder = m.global.historyOrder

  if historyOrder <> invalid then
    if historyOrder.count() > 0 then
      'get the full user's bookmark category
      request = Bookmarks.getFullHistoryReq(historyOrder)

      request.node = m.top
      request.field = "categoryResponse"
    
      ' first cancel any outstanding metadata requests for this screen
      m.global.metadataFetchTask.cancel = { node: request.node, field: request.field }
      m.global.metadataFetchTask.request = request
    else
      m.Spinner.visible = false
    end if

  else
    'we haven't gotten a response for the initial bookmarks yet
    'so we're gonna listen and run this again once we get a response
    'we need to make sure we unobserve this field once the category changes though
    m.global.observeField("historyOrder", "loadHistory")
  end if

End Function


'''''''''''''''''''''
' loadBookmarks
'
' Load the user's history content for "Continue Watching"
Function loadBookmarks(categoryId As String)
  constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, constants)

  bookmarkOrder = m.global.bookmarkOrder

  if bookmarkOrder <> invalid then 
    if bookmarkOrder.count() > 0 then
      'get the full user's history category
      request = Bookmarks.getFullHistoryReq(bookmarkOrder)

      request.node = m.top
      request.field = "categoryResponse"

      ' first cancel any outstanding metadata requests for this screen
      m.global.metadataFetchTask.cancel = { node: request.node, field: request.field }
      m.global.metadataFetchTask.request = request
    else
      m.Spinner.visible = false
    end if
  
  else
    'we haven't gotten a response for the initial bookmarks yet
    'so we're gonna listen and run this again once we get a response
    'we need to make sure we unobserve this field once the category changes though
    m.global.observeField("bookmarkOrder", "loadBookmarks")
  end if

End Function


'''''''''''''''''''''
' loadUserCategories
'
' Load the Queue and View History user categories
Function loadUserCategories()
  tubiLog("CategoryScreen.loadUserCategories")
  'make the initial calls to the user's queue and view history
  m.authTask.observeField("initialBookmarks", "handleInitialBookmarks")
  m.authTask.observeField("initialHistory", "handleInitialHistory")

  m.authTask.functionName = "getInitialUserCategories"
  m.authTask.control = "RUN"
End Function


'''''''''''
' handleInitialBookmarks
'
' Use the metadataFetchTask to populate the content for the user's "My Queue" category
Function handleInitialBookmarks()
  tubiLog("CategoryScreen.handleInitialBookmarks")
  constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, constants)

  if m.authTask.initialBookmarks <> invalid
    initialBookmarks = m.authTask.initialBookmarks
    bookmarkData = Bookmarks.handleInitialBookmarks(initialBookmarks)

    m.global.bookmarkIds = bookmarkData.bookmarkIds
    m.global.bookmarkOrder = bookmarkData.bookmarkOrder

  end if
End Function


'''''''''''
' handleInitialHistory
'
' Use the metadataFetchTask to populate the content for the user's "My Queue" category
Function handleInitialHistory()
  tubiLog("CategoryScreen.handleInitialHistory")
  constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, constants)

  if m.authTask.initialHistory <> invalid

    initialHistory = m.authTask.initialHistory
    historyData = Bookmarks.handleInitialHistory(initialHistory)

    m.global.historyIds = historyData.historyIds
    m.global.historyOrder = historyData.historyOrder

  end if
End Function


'''''''''''
' onTrackingUriChange
'
' send the navigateInPage (navigate_within_page) tracking event
Function onTrackingUriChange()
  m.global.trackingTask.trackEvent = {
    trackType: "navigateInPage"
    value: 0
    ctx: m.top.trackingUri
  }
End Function
