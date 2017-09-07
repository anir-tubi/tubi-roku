Function init()
  m.categoryText = m.top.findNode("categoryText")
  m.top.observeField("content", "onContentChange")
End Function


''''''''''''''''''''
' onContentChange
'
' Set the label text on receiving the category name
Function onContentChange()
  if m.top.content <> invalid then
    m.categoryText.text = m.top.content.title
    if m.top.content.totalCount <> invalid and m.top.content.totalCount > 0 then
      m.categoryCountText.text = stri(m.top.content.totalCount)
    end if
  end if
End Function
