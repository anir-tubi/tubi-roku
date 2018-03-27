Function init()
  m.categoryText = m.top.findNode("categoryText")
  m.categoryCountGroup = m.top.findNode("categoryCountGroup")
  m.categoryCountText = m.top.findNode("categoryCountText")
  m.top.observeField("itemContent", "onItemContentChange")
End Function


''''''''''''''''''''
' onItemContentChange
'
' Set the label text on receiving the category name
Function onItemContentChange()
  tubiLog("CategoryListItem.onItemContentChange")
  if m.top.itemContent <> invalid then
    m.categoryText.text = m.top.itemContent.title
    if m.top.itemContent.totalCount <> invalid and m.top.itemContent.totalCount > 0 then
      m.categoryCountText.text = stri(m.top.itemContent.totalCount)
    end if
  end if
End Function
