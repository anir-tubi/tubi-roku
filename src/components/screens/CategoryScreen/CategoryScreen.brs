Function init()
  tubiLog("CategoryScreen.init")
  m.ContentArea = m.top.findNode("ContentArea")
  m.CategoryList = m.top.findNode("CategoryList")
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.SpecialCategories = m.top.findNode("SpecialCategories")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("categoryPreviewResponse", "onCategoryPreviewReceived")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("dirtyUserCategories", "onDirtyUserCategories")
  m.top.observeField("categoryListResponse", "onCategoriesReceived")
  m.top.observeField("trackingUri", "onTrackingUriChange")
  m.trackingCount = 0
  m.CategoryList.observeField("itemFocused","onCategoryMenuChange")
  m.CategoryList.observeField("preItemFocused","onPreCategoryMenuChange")
  m.CategoryList.observeFIeld("itemSelected", "onCategoryMenuSelected")
  m.authTask = m.top.findNode("CategoryAuthTask")

  'Content area
  m.CategoryGridList = m.top.findNode("CategoryGridList")
  m.CategoryGridList.observeField("itemFocused", "onGridFocusChange")
  m.CategoryGridList.observeField("itemSelected", "onGridItemSelected")
  m.CategoryGridList.observeField("preCategoryFocused", "onPreGridCategoryChange")

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
  m.top.setFocus(true)
End Function

''''''''''''''''''''''''''''
' onDirtyUserCategories
'
' if one of the user categories is showing, reload it
Function onDirtyUserCategories()
  tubiLog("CategoryScreen.onDirtyUserCategories")
  m.CategoryGridList.dirtyUserCategories = true
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
    m.CategoryGridList.setFocus(true)
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
    if (key = "right" or key = "ok") and m.CategoryList.isInFocusChain() then
      m.CategoryGridList.setFocus(true)
      slideTo(m.ContentArea, [85,m.ContentArea.translation[1]], 0.5)
      slideTo(m.CategoryList, [-380,m.CategoryList.translation[1]], 0.5)
      m.trackingCount = 0
      return true
    else if (key = "left" or key = "back") and not m.CategoryList.isInFocusChain() then
      m.CategoryList.setFocus(true)
      slideTo(m.ContentArea, [525,m.ContentArea.translation[1]], 0.5)
      slideTo(m.CategoryList, [85,m.CategoryList.translation[1]], 0.5)
      m.trackingCount = 0
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
    m.top.content.insertChild(m.SearchSignOutCategory, 0)
    m.SearchSignOutCategory.appendChild(m.SearchMenuItem)
    m.SearchSignOutCategory.appendChild(m.SignOutMenuItem)
    m.SearchSignOutCategory.appendChild(m.AboutMenuItem)
    m.top.content.insertChild(m.ContinueWatchingCategory, 1)
    m.top.content.insertChild(m.MyQueueCategory, 2)
    featureGridIndex = 3
  else
    m.top.content.insertChild(m.SearchSignInCategory, 0)
    m.SearchSignInCategory.appendChild(m.SearchMenuItem)
    m.SearchSignInCategory.appendChild(m.SignInMenuItem)
    m.SearchSignInCategory.appendChild(m.AboutMenuItem)
    m.top.content.removeChild(m.ContinueWatchingCategory)
    m.top.content.removeChild(m.MyQueueCategory)
    featureGridIndex = 0
  end if

  m.CategoryList.content = m.top.content
  m.CategoryGridList.content = m.top.content  ' should be the category list
  m.CategoryGridList.animateToCategory = featureGridIndex
  m.CategoryList.animateToItem = featureGridIndex  'CategoryList has one extra item
  if m.top.isInFocusChain() then m.CategoryGridList.setFocus(true)
End Function


' Use this trigger to synchronize menu and grid
Function onPreCategoryMenuChange()
  m.CategoryGridList.animateToCategory = m.CategoryList.preItemFocused
End Function

'''''''''''''''''''''
' onCategoryMenuChange
'
' On category focus change, update the info panel
Function onCategoryMenuChange() As Void
  tubiLog("CategoryScreen.onCategoryMenuChange")
  if not m.CategoryList.isInFocusChain() or m.CategoryList.content = invalid then return

  'unobserve historyOrder and bookmarkOrder fields since if we are changing category,
  'we are no longer concerned about any categories we may have been waiting for
  m.global.unobserveField("bookmarkOrder")
  m.global.unobserveField("historyOrder")

  newCategory = m.CategoryList.content.getChild(m.CategoryList.itemFocused)
  m.InfoPanel.content = newCategory
  m.InfoPanel.mode = "category"
  m.top.backgroundUriList = [m.defaultHeroUri]

  'update the tracking URI for user tracking purposes
  m.trackingCount = m.trackingCount + 1
  catPos = (m.CategoryList.itemFocused + 1).toStr()
  catSlug = ""
  if newCategory.slug <> invalid
    catSlug = newCategory.slug
  end if
  m.top.trackingUri = "/home/" + catPos + "/cat/" + catSlug
End Function


'''''''''''''''''''''''''''
' onSignedInChange
'
' Create a new content node tree for the sign in menu, based on the template SearchSignInContent.
' We do this so that we can keep a reference to all possible menu options, even when the sign in
' menu is showing a subset.
Function onSignedInChange()
  tubiLog("CategoryScreen.onSignedInChange")
  if m.top.content <> invalid then
    onContentChange()
  end if

  if m.top.signedIn = true then
    loadUserCategories()
  else
    'If user logged out, don't track their history or queue
    m.global.bookmarkIds = {series: {}, videos: {}}
    m.global.historyIds = {series: {}, videos: {}}
    m.global.bookmarkOrder = []
    m.global.historyOrder = []
  end if
End Function


Function onPreGridCategoryChange() As Void
  ' Don't sync if CategoryList has focus and most likely triggered the grid category change
  if m.CategoryGridList.isInFocusChain() and m.CategoryGridList.content <> invalid then
    m.CategoryList.animateToItem = m.CategoryGridList.preCategoryFocused ' CategoryList has one extra item
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
  m.InfoPanel.content = focusedContent
  m.InfoPanel.mode = "item"

  if focusedContent <> invalid and focusedContent.backgrounds <> invalid and focusedContent.backgrounds.count() > 0 then
    m.top.backgroundUriList = focusedContent.backgrounds
  else
    m.top.backgroundUriList = [m.defaultHeroUri]
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
    row = m.CategoryGridList.cursorPosition[0] + 1
    col = m.CategoryGridList.cursorPosition[1] + 1
  end if

  'set the user event tracking info
  m.trackingCount = m.trackingCount + 1
  row = row.toStr() + "/"
  col = col.toStr()
  m.top.trackingUri = "/home/" + catPos + "/cat/" + catSlug + row + col

End Function

Function onGridItemSelected() As Void
  tubiLog("CategoryScreen.onGridItemSelected")
  selectedItem = m.CategoryGridList.itemSelected
  if selectedItem = invalid then return
  if selectedItem.id = "SearchMenuItem" then
    m.top.searchSelected = true
  else if selectedItem.id = "SignInMenuItem" then
    m.top.signInSelected = true
  else if selectedItem.id = "SignOutMenuItem" then
    m.top.signOutSelected = true
  else if selectedItem.id = "AboutMenuItem" then
    m.top.aboutSelected = true
  else
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
    value: m.trackingCount
    ctx: m.top.trackingUri
  }
End Function
