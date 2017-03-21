Function init()
  tubiLog("CategoryContentGrid.init")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("listHasFocus", "onListHasFocus")
  m.CategoryName = m.top.findNode("CategoryName")
  m.FocusedCategoryName = m.top.findNode("FocusedCategoryName")
  m.UnfocusedCategoryName = m.top.findNode("UnfocusedCategoryName")
  m.ContentGrid = m.top.findNode("ContentGrid")
  m.ContentGrid.observeField("itemFocused", "onItemFocusedChange")
  m.EmptyPlaceholder = m.top.findNode("EmptyPlaceholder")
  m.Spinner = m.top.findNode("Spinner")

  ' the count of contents on the top right of the category grid
  m.CategoryCount = m.top.findNode("CategoryCount")
  m.ItemCount = m.top.findNode("ItemCount")
  m.FocusIndex = m.top.findNode("FocusIndex")

  ' initialize CategoryName visibility
  onFocusPercentChange()
End Function

Function onComponentFocusChange()
  tubiLog("CategoryContentGrid.onComponentFocusChange")
  if m.top.hasFocus() and m.ContentGrid.visible then
    m.ContentGrid.setFocus(true)
  else if m.top.isInFocusChain() then
    m.top.itemFocused = m.top.content
  end if
End Function

Function onFocusPercentChange()
  tubiLog("CategoryContentGrid.onFocusPercentChange")
  if m.top.focusPercent > 0 and not m.top.listHasFocus then
    m.CategoryName.opacity = 1.0 - m.top.focusPercent

  else
    m.CategoryName.opacity = 1.0
  end if

  m.CategoryCount.opacity = m.top.focusPercent
  m.FocusedCategoryName.opacity = m.top.focusPercent
  m.UnfocusedCategoryName.opacity = 1.0 - m.top.focusPercent

  m.top.opacity = 0.20 + (0.80 * m.top.focusPercent)
End Function


Function onListHasFocus()
  tubiLog("CategoryContentGrid.onListHasFocus")
  if m.top.focusPercent = 1
    if m.top.listHasFocus = true
      fade(m.CategoryName, "in", 0.5)
      m.CategoryCount.opacity = 1.0
    else
      fade(m.CategoryName, "out", 0.5)
      m.CategoryCount.opacity = 0.0
    end if
  end if
End Function


Function onContentChange()
  tubiLog("CategoryContentGrid.onContentChange")
  if m.top.content <> invalid then
    m.FocusedCategoryName.text = m.top.content.title
    m.UnfocusedCategoryName.text = m.top.content.title

    if m.top.content.getChildCount() > 0 then
   
      if m.top.content.title = "Featured" or m.top.content["type"] = m.global.constants.ui.contentTypes.season then
        m.ContentGrid.scrollWidth = 430
        m.ContentGrid.itemSize = [430,256]
        m.ContentGrid.itemComponentName = "FeaturePoster"
      else if m.top.content.id = "ContinueWatching" then
        ' Regular poster size, but with resume bar overlay
        m.ContentGrid.scrollWidth = 210
        m.ContentGrid.itemSize = [210,300]
        m.ContentGrid.itemComponentName = "ResumePoster"
        
      else if m.top.content.id = "SearchSignIn" or m.top.content.id = "SearchSignOut" then
        m.ContentGrid.scrollWidth = 430
        m.ContentGrid.itemSize = [430,256]
        m.ContentGrid.itemComponentName = "SignInPoster"
      else
        m.ContentGrid.scrollWidth = 210
        m.ContentGrid.itemSize = [210,300]
        m.ContentGrid.itemComponentName = "Poster"
      end if
      m.ContentGrid.visible = true
      m.EmptyPlaceholder.visible = false

      m.ContentGrid.content = m.top.content
      if m.top.isInFocusChain() then m.ContentGrid.setFocus(true)  ' be careful when removing children that we don't remove a focused item
      drawItemCount()
      m.Spinner.visible = false
    else if m.top.content.totalCount <> invalid and m.top.content.totalCount = 0
      m.ContentGrid.visible = false
      m.EmptyPlaceholder.visible = true
      m.EmptyPlaceholder.text = m.top.content.placeholderText
      m.Spinner.visible = false
    else
      ' metadata is pending
      m.Spinner.visible = true
      m.ContentGrid.visible = false
      m.EmptyPlaceholder.visible = false
    end if
  end if
End Function

Function onItemFocusedChange()
  tubiLog("CategoryContentGrid.onItemFocusedChange")
  drawItemCount()
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
