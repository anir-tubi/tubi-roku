Function init()
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("listHasFocus", "onFocusPercentChange")
  m.CategoryName = m.top.findNode("CategoryName")
  m.PosterGrid = m.top.findNode("PosterGrid")
  m.FeatureGrid = m.top.findNode("FeatureGrid")
  m.SignInGrid = m.top.findNode("SignInGrid")
  m.PosterGrid.focusChangeDuration = m.global.constants.performance.categoryGridList.gridAnimationDuration
  m.FeatureGrid.focusChangeDuration = m.global.constants.performance.categoryGridList.gridAnimationDuration
  m.SignInGrid.focusChangeDuration = m.global.constants.performance.categoryGridList.gridAnimationDuration
  m.ContentGrid = m.PosterGrid  ' this will change based on content title

  ' the count of contents on the top right of the category grid
  m.CategoryCount = m.top.findNode("CategoryCount")
  m.ItemCount = m.top.findNode("ItemCount")
  m.FocusIndex = m.top.findNode("FocusIndex")

  ' Set Rectangle attributes which force bounding box size, affecting 
  ' layout within the ScrollingList
  m.top.color = m.global.constants.ui.colors.transparent
  m.top.width = "1395"
  m.top.height = "369"
  
  ' initialize CategoryName visibility
  onFocusPercentChange()
End Function

Function onComponentFocusChange()
  tubiLog("CategoryContentGrid.onComponentFocusChange")
  if m.top.hasFocus() then
    m.ContentGrid.setFocus(true)
  end if
End Function

Function onFocusPercentChange()
  if m.top.focusPercent > 0 and not m.top.listHasFocus then
    m.CategoryName.opacity = 1.0 - m.top.focusPercent

  else if m.top.focusPercent > 0 and m.top.listHasFocus then
    fade(m.CategoryName, "in", 0.5)

  else
    m.CategoryName.opacity = 1.0
  end if

  m.CategoryCount.opacity = m.top.focusPercent
  m.top.opacity = 0.20 + (0.80 * m.top.focusPercent)
End Function

Function onContentChange()
  tubiLog("CategoryContentGrid.onContentChange")
  if m.top.content <> invalid then
    ' we have to release these first, they'll be set to to appropriate grid
    ' below
    m.ContentGrid.unobserveField("itemSelected")
    m.ContentGrid.unobserveField("itemFocused")
    m.ContentGrid.unobserveField("cursorIndex")
   
    m.CategoryName.text = m.top.content.title

    if m.top.content.title = "Featured" or m.top.content["type"] = m.global.constants.ui.contentTypes.season then
      m.top.removeChild(m.PosterGrid)
      m.PosterGrid = invalid
      m.top.removeChild(m.SignInGrid)
      m.SignInGrid = invalid
      m.ContentGrid = m.FeatureGrid
    else if m.top.content.id = "SearchSignIn" or m.top.content.id = "SearchSignOut" then
      m.top.removeChild(m.PosterGrid)
      m.PosterGrid = invalid
      m.top.removeChild(m.FeatureGrid)
      m.FeatureGrid = invalid
      m.ContentGrid = m.SignInGrid
    else
      m.top.removeChild(m.FeatureGrid)
      m.FeatureGrid = invalid
      m.top.removeChild(m.SignInGrid)
      m.SignInGrid = invalid
      m.ContentGrid = m.PosterGrid
    end if
    m.ContentGrid.visible = true

    m.ContentGrid.observeField("itemSelected", "onItemSelectedChange")
    m.ContentGrid.observeField("itemFocused", "onItemFocusedChange")
    m.ContentGrid.observeField("cursorIndex", "onCursorIndexChange")
    m.ContentGrid.content = m.top.content
    drawItemCount()
  end if
End Function

Function onItemSelectedChange()
  m.top.itemSelected = m.ContentGrid.itemSelected
End Function

Function onItemFocusedChange()
  'tubiLog("CategoryContentGrid.onItemFocusedChange")
  drawItemCount()
  m.top.itemFocused = m.ContentGrid.itemFocused
End Function

Function onCursorIndexChange()
  m.top.cursorIndex = m.ContentGrid.cursorIndex
End Function

Function drawItemCount()
  if m.top.content.totalCount <> invalid and m.top.content.totalCount > 0 and m.ContentGrid.cursorIndex <> -1 then
    m.ItemCount.text = " " + Chr(&hb7) + " " + stri(m.top.content.totalCount).trim()
    m.FocusIndex.text = stri(m.ContentGrid.cursorIndex + 1).trim()
  else 
    ' It's odd to see '0 of 0' so we hide the counter
    m.ItemCount.text = ""
    m.FocusIndex.text = ""
  endif
End Function