Function init()
  tubiLog("TopNavItem.init() ")
  m.Label = m.top.findNode("Label")
  m.LabelSelectedFocus = m.top.findNode("LabelSelectedFocus")
  m.LabelSelectedFocus.color = "0xFFFFFFFF"

  m.nLabelXSpacing = m.Label.translation[0]
  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeField("itemHasFocus", "onItemFocus")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("gridHasFocus", "onGridHasFocusChange")
End Function


Function onGridHasFocusChange()
  itemContent = m.top.itemContent
  if itemContent <> invalid
    if m.top.gridHasFocus = true
      m.LabelSelectedFocus.visible = true
      if m.top.itemHasFocus = true
        m.LabelSelectedFocus.opacity = 1
      end if
      onItemFocus()
    else
      m.LabelSelectedFocus.opacity = 0
      m.LabelSelectedFocus.visible = false
      if itemContent.selected = true
        m.Label.color = "0xFFFFFFFF"
      else 
        m.Label.color = "0x9699A3FF"
      end if
    end if
  end if
End Function


Function onItemFocus()
  itemContent = m.top.itemContent
  if itemContent <> invalid
    if itemContent.selected = true
      m.Label.color = m.global.theme.focused
    else 
      m.Label.color = "0x585B66FF"
    end if
  end if
End Function

Function onFocusPercentChange()
  itemContent = m.top.itemContent
  focusPercent = m.top.focusPercent
  m.LabelSelectedFocus.opacity = focusPercent
End Function


'//When the content of the item is changed.
Function onItemContentChange()
  itemContent = m.top.itemContent
  if itemContent <> invalid
    m.Label.width = 0
    m.LabelSelectedFocus.width = 0
    m.Label.text = itemContent.title
    m.LabelSelectedFocus.text = itemContent.title
    '//Ensure the width the button varies depending on the width of the label
    boundingRect = {}
    boundingRect.width = m.Label.boundingRect().width + (m.nLabelXSpacing * 2)
    boundingRect.height = m.Label.height
    m.Label.width = boundingRect.width - m.nLabelXSpacing
    m.LabelSelectedFocus.width = m.Label.width
    m.top.boundingRect = boundingRect

    '//Call the following functions to set the initial look of the component depending on focus, selection and other states
    onItemFocus()
    onGridHasFocusChange()
  end if
End Function