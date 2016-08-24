Function init()
  tubiLog("CategoryScreen.init")
  m.CategoryList = m.top.findNode("CategoryList")
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.SpecialCategories = m.top.findNode("SpecialCategories")
  m.Hero = m.top.findNode("HeroBackground")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.CategoryList.observeField("itemFocused","onCategoryChange")

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

  m.defaultHeroUri = "pkg:/images/background-not-on-selection.png"

  ' track the last focused screen component so that we can go back
  ' to it when focus is taken away
  m.lastFocusedComponent = m.CategoryList

  loadAllCategories()
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
  else if selectedItem.id = "AboutInMenuItem" then
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
  if m.top.hasFocus() then
    ' defaulted to screen, move to a subcomponent
    if m.ContentGrid.visible = true then
      m.ContentGrid.setFocus(true)
    else if m.SignInMenu.visible = true then
      m.SignInMenu.setFocus(true)
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

  ' Prepend special categories 
  while m.SpecialCategories.getChildCount() > 0
    m.top.content.insertChild(m.SpecialCategories.getChild(0), 0)
  end while

  m.CategoryList.content = m.top.content
  m.InfoPanel.content = m.top.content.getChild(m.CategoryList.itemFocused)
  m.CategoryList.setFocus(true)
  m.InfoPanel.mode = "category"

  ' bootstrap the grid content by finding the populated category
  for i=0 to m.top.content.getChildCount()-1
    category = m.top.content.getChild(i)
    if category.getChildCount() > 0 then
      m.ContentGrid.content = category
      m.ContentGrid.id = category.id
    end if
  end for
End Function

'''''''''''''''''''''
' onCategoryChange
'
' On category focus change, update the info panel
Function onCategoryChange() As Void
  tubiLog("CategoryScreen.onCategoryChange")
  if not m.CategoryList.isInFocusChain() or m.CategoryList.content = invalid then return
  newCategory = m.CategoryList.content.getChild(m.CategoryList.itemFocused)
  m.InfoPanel.content = newCategory
  m.InfoPanel.mode = "category"
  m.Hero.uri = m.defaultHeroUri

  if newCategory.id <> m.ContentGrid.id then
    m.SignInMenu.visible = false
    m.ContentGrid.content = invalid
    m.ContentGrid.visible = false

    ' Flip between feature grid, poster grid, and sign in menu
    if newCategory.title = "Featured"
      m.ContentGrid = m.top.findNode("FeatureGrid")
      m.ContentGrid.visible = true
    else if newCategory.title = "Recently Viewed"
      'TODO(Chris): Show recently viewed grid here
    else if newCategory.title = "My Queue"
      'TODO(Chris): Show user's queue here
    else if newCategory.title = "Search & Sign In"
      m.SignInMenu.visible = true
    else
      m.ContentGrid = m.top.findNode("PosterGrid")
      m.ContentGrid.visible = true
    end if

    m.ContentGrid.id = m.CategoryList.content.getChild(m.CategoryList.itemFocused).id
    ' Don't reload if the category id's match
    'TODO(Chris): We need a "loading experience here before content shows up
    loadOneCategory(newCategory.id)
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
  if focusedContent.heros <> invalid and focusedContent.heros.count() > 0 then 
    m.Hero.uri = focusedContent.heros[0]
  else
    m.Hero.uri = m.defaultHeroUri
  end if
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
  tubiLog("CategoryScreen.loadCategories")

  ' TODO(Chris): This should move to a shim layer which hides specifics of the Tubi v4 API
  settings = m.global.constants.settings
  urlBase = m.global.constants.urls.contents.urlBase
  platform = m.global.constants.platform
  deviceInfo = m.global.constants.deviceInfo
  url = urlBase + "/categories?app_id=" + settings.shortAppName + "&platform=" + platform + "&device_id=" + deviceInfo.deviceId + "&page_enabled=false"

  request = {
    url: url
    node: m.top
    field: "content"
    options: {}
    name: "getAllCategories"
  }
  m.global.metadataFetchTask.request = request
End Function

'''''''''''''''''''''
' loadOneCategory
'
' Load a single category's content
Function loadOneCategory(categoryId As String)
  settings = m.global.constants.settings
  urlBase = m.global.constants.urls.contents.urlBase
  platform = m.global.constants.platform
  deviceInfo = m.global.constants.deviceInfo
  request = {
    url: urlBase + "/categories?app_id=" + settings.shortAppName + "&platform=" + platform + "&device_id=" + deviceInfo.deviceId + "&cat_id=" + categoryId + "&all=false&page_enabled=false"
    node: m.ContentGrid
    field: "content"
    options: {}
    name: "getCategory"    
  }
  m.global.metadataFetchTask.request = request
End Function
