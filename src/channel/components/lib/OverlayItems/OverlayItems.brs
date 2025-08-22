Function init()
  m.overLayItemsLayoutGroup = m.top.findNode("OverLayItemsLayoutGroup")
  m.top.observeFieldScoped("itemsInfo", "onItemInfoChanged")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.focusedColor = theme.focusedColor
  end if
End Function


Function onItemInfoChanged(msg)
  items = msg.getData()
  typographyConstants = getTypographyConstants()

  if items.title <> invalid
    titleLabel = createObject("roSGNode", "Label")
    titleLabel.id = items.id.trim()
    titleLabel.text = items.title
    titleLabel.height = 40
    m.overLayItemsLayoutGroup.appendChild(titleLabel)
    setTypographyOfLabel(titleLabel, typographyConstants.ids.subheaderMedium)
  end if

  if items.subtitle <> invalid
    subTitleLabel = createObject("roSGNode", "Label")
    subTitleLabel.id = items.subtitle.trim()
    subTitleLabel.text = items.subtitle
    subTitleLabel.height = 40
    m.overLayItemsLayoutGroup.appendChild(subTitleLabel)
    setTypographyOfLabel(subTitleLabel, typographyConstants.ids.bodySmall)
  end if

  if items.id <> "sendFeedbackOnPlayer"
    rectangle = createObject("roSGNode", "Rectangle")
    rectangle.width = 0
    rectangle.height = 44
    m.overLayItemsLayoutGroup.appendChild(rectangle)
  else
    m.overLayItemsLayoutGroup.itemSpacings = [15, 30]
  end if

  if items.hasSubmenu = true
    checkBoxList = createObject("roSGNode", "CaretBoxList")
    itemComponentName = "CaretButton"
  else
    checkBoxList = createObject("roSGNode", "CheckBoxList")
    itemComponentName = "CheckButton"
  end if

  checkBoxList.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"
  checkBoxList.id = items.id.trim()
  checkBoxList.itemSize = [510, 69]
  checkBoxList.numRows = items.numRows
  checkBoxList.itemComponentName = itemComponentName
  checkBoxList.rowSpacings = [8]
  checkBoxList.content = items.content

  if items.defaultCheckedItemIndex <> invalid
    checkBoxList.defaultCheckedItemIndex = items.defaultCheckedItemIndex
  end if

  checkBoxList.focusBitmapBlendColor = m.focusedColor
  checkBoxList.observeFieldScoped("itemSelected", "onWasItemSelectedFromMenu")

  m.overLayItemsLayoutGroup.appendChild(checkBoxList)
End Function
