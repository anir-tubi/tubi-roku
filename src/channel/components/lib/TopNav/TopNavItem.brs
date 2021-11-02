Function init()
  tubiLog("TopNavItem.init() ")
  m.Label = m.top.findNode("Label")
  m.LabelSelectedFocus = m.top.findNode("LabelSelectedFocus")
  m.LabelSelectedFocus.color = "0xFFFFFFFF"

  m.nLabelXSpacing = m.Label.translation[0]
  m.top.observeField("itemContent", "onItemContentChange")
  m.underline =  CreateObject("roSGNode","Rectangle")
  m.underline.id = "underline"
  m.underline.translation = [36, 40]
  m.underline.height = 2
  m.underline.width = 150
  m.underline.color = "0xFF501AFF" 'Golden gate Orange
  m.underline.visible="false"
  m.top.appendChild(m.underline)
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
        m.underline.visible = false
      end if
      onItemFocus()
    else
      m.LabelSelectedFocus.opacity = 0
      m.LabelSelectedFocus.visible = false    
      m.underline.visible = false
      if itemContent.selected = true
        m.Label.color = itemContent.selectedItemColor
      else
        m.Label.color = "0xFFFFFFFF"
      end if
      
    end if
  end if
End Function


Function onItemFocus()
  itemContent = m.top.itemContent
  if itemContent <> invalid
    if itemContent.selected = true
      m.Label.color = m.global.theme.focused
      m.underline.visible = true
    else 
      m.Label.color = "0xFFFFFFFF"
    end if
  end if
End Function

Function onFocusPercentChange()
  itemContent = m.top.itemContent
  focusPercent = m.top.focusPercent
  m.LabelSelectedFocus.opacity = focusPercent
  m.underline.opacity = 1 - focusPercent
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
    m.underline.width = m.Label.width - m.nLabelXSpacing
    '//Call the following functions to set the initial look of the component depending on focus, selection and other states
    onItemFocus()
    onGridHasFocusChange()
  end if
End Function