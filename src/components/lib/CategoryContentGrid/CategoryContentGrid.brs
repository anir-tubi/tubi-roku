Function init()
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.PosterGrid = m.top.findNode("PosterGrid")
  m.FeatureGrid = m.top.findNode("FeatureGrid")
  m.SignInGrid = m.top.findNode("SignInGrid")
  m.PosterGrid.focusChangeDuration = m.global.constants.performance.categoryGridList.gridAnimationDuration
  m.FeatureGrid.focusChangeDuration = m.global.constants.performance.categoryGridList.gridAnimationDuration
  m.SignInGrid.focusChangeDuration = m.global.constants.performance.categoryGridList.gridAnimationDuration
  m.ContentGrid = m.PosterGrid  ' this will change based on content title
  m.Spinner = m.top.findNode("Spinner")

  ' Set Rectangle attributes which force bounding box size, affecting 
  ' layout within the ScrollingList
  m.top.color = m.global.constants.ui.colors.transparent
  m.top.width = "1395"
  m.top.height = "624"
End Function

Function onComponentFocusChange()
  tubiLog("CategoryContentGrid.onComponentFocusChange")
  if m.top.hasFocus() then
    m.ContentGrid.setFocus(true)
  end if
End Function

Function onFocusPercentChange()
  ' The 'visible' flag is key to keeping the number of Poster instances in memory low.
  ' When a grid is not being shown on screen it can keep the metadata intact while
  ' freeing VRAM used for posters
  if m.top.focusPercent > 0 and m.ContentGrid.visible = false then
    m.ContentGrid.visible = true
  else if m.top.focusPercent = 0 and m.ContentGrid.visible = true then
    m.ContentGrid.visible = false
  end if
End Function

Function onContentChange()
  tubiLog("CategoryContentGrid.onContentChange")
  if m.top.content <> invalid and m.top.content.getChildCount() > 0 then
    ' we have to release these first, they'll be set to to appropriate grid
    ' below
    m.ContentGrid.unobserveField("itemSelected")
    m.ContentGrid.unobserveField("itemFocused")
    m.ContentGrid.unobserveField("cursorIndex")
    if m.top.content.title = "Featured" then
      m.ContentGrid = m.FeatureGrid
    else if m.top.content.id = "SearchSignIn" or m.top.content.id = "SearchSignOut" then
      m.ContentGrid = m.SignInGrid
    else
      m.ContentGrid = m.PosterGrid

      ' For the 2-row poster grid, collapse to 1 row if fewer than 8 items come back
      ' Be careful of a category which may not have totalCount set, such as error or special category
      if m.top.content.totalCount <> invalid and m.top.content.totalCount > 0 and m.top.content.totalCount <= 8 then
        m.ContentGrid.numRows = 1
      else if m.top.content.totalCount = invalid or m.top.content.totalCount = 0 and m.top.content.getChildCount() <= 8 then
        m.ContentGrid.numRows = 1
      else
        m.ContentGrid.numRows = 2
      end if
    end if

    m.ContentGrid.observeField("itemSelected", "onItemSelectedChange")
    m.ContentGrid.observeField("itemFocused", "onItemFocusedChange")
    m.ContentGrid.observeField("cursorIndex", "onCursorIndexChange")
    m.ContentGrid.content = m.top.content

    ' make sure it becomes visible; there's a race condition between setting content and setting focus percent above
    if m.top.focusPercent > 0 then  m.ContentGrid.visible = true
    if m.top.isInFocusChain() then m.ContentGrid.setFocus(true)  ' be careful when removing children that we don't remove a focused item
    m.Spinner.visible = false
  else
    m.Spinner.visible = true
  end if
End Function

Function onItemSelectedChange()
  m.top.itemSelected = m.ContentGrid.itemSelected
End Function

Function onItemFocusedChange()
  'tubiLog("CategoryContentGrid.onItemFocusedChange")
  m.top.itemFocused = m.ContentGrid.itemFocused
End Function

Function onCursorIndexChange()
  m.top.cursorIndex = m.ContentGrid.cursorIndex
End Function