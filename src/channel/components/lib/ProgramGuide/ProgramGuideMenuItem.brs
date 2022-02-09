Function init()
  m.timeString = m.top.findNode("timeString")
  m.programString = m.top.findNode("programString")
  m.cellRect = m.top.findNode("cellRect")
  m.staticOverlay = m.top.findNode("staticOverlay")
  m.top.observeField("rowFocusPercent", "onRowFocusPercentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("itemContent", "onContentChange")
End Function


Function onContentChange()
  item = m.top.itemContent
  if item <> invalid
    m.programString.text = item.title
    m.timeString.text = item.ShortDescriptionLine1
    m.cellRect.width = item.FHDItemWidth
    m.programString.width = item.FHDItemWidth - 24 'to provide some right margin
    m.timeString.width = item.FHDItemWidth - 24
    if item.selected = true
      if item.selectedItemAttributes <> invalid and item.selectedItemAttributes.title <> invalid
        m.timeString.text = item.selectedItemAttributes.title + item.ShortDescriptionLine1
        m.timeString.color = item.selectedItemAttributes.unFocusedColor ' "0xEB9C00FF"
      end if
    else
      if item.selectedItemAttributes <> invalid
        m.timeString.color = item.selectedItemAttributes.focusedColor ' "0x9699A3FF"
      end if
    end if
  end if

  if m.top.index = 0 
    m.staticOverlay.opacity = 1
  else 
    m.staticOverlay.opacity = 0
  end if
End Function


Function onFocusPercentChange()
  item = m.top.itemContent
  if m.top.focusPercent < 0.5
    if item.selected 
      if item.selectedItemAttributes <> invalid
        m.timeString.text = strReplace(item.ShortDescriptionLine1, item.selectedItemAttributes.title, "")
        ' color of the text has been passed along with string so that content Items need not to access global.
        m.timeString.color = item.selectedItemAttributes.focusedColor '"0x9699A3FF"
      end if
      item.selected = false
    end if
  else 
    m.cellRect.blendColor = "0x10141FFF"
  end if
End Function


Function onRowFocusPercentChange()
  if m.top.rowFocusPercent > 0.5
    m.programString.opacity = 1
    m.timeString.opacity = 1
    m.cellRect.blendColor = "0x9699A3FF"
  else
    m.programString.opacity = 0.24
    m.timeString.opacity = 0.24
    m.cellRect.blendColor = "0x1C1F29FF"
    m.timeString.color = "0x9699A3FF"
  end if
End Function
