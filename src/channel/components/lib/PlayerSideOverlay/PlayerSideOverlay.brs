Function init()
  m.overlayBackground = m.top.findNode("overlayBackground")

  m.top.observeFieldScoped("focusedChild", "onComponentFocus")
  m.top.observeFieldScoped("itemList", "onItemListChanged")

  ' This field indicates which menu is currently focused within the focusedArray. In this component, we may display one or more menu
  ' items based on the requirements. This field specifies which menu item should be focused when the overlay is first shown,
  ' as well as which component gains focus when a menu item is selected and the user presses the back button.
  m.focusIndex = 0

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  onThemeChange()
End Function


Function onItemListChanged(msg)
  itemlist = m.top.itemlist

  if itemlist <> invalid

    ' This field is used to store all the menu items within this component and determine which one should be focused on
    m.focusArray = []
    typographyConstants = getTypographyConstants()

    outerLayoutGroup = createObject("roSGNode", "LayoutGroup")
    outerLayoutGroup.layoutDirection = "vert"
    outerLayoutGroup.vertAlignment = "custom"
    outerLayoutGroup.itemSpacings = [40]
    outerLayoutGroup.translation = [60, 60]

    for i = 0 to itemlist.Count() - 1
      item = itemlist[i]
      if item <> invalid
        layoutGroup = createObject("roSGNode", "LayoutGroup")

        if item.title <> invalid
          titleLabel = createObject("roSGNode", "Label")
          titleLabel.id = item.title.trim()
          titleLabel.text = item.title
          titleLabel.height = 40
          layoutGroup.appendChild(titleLabel)
          setTypographyOfLabel(titleLabel, typographyConstants.ids.subheaderMedium)
        end if

        if item.subtitle <> invalid
          subTitleLabel = createObject("roSGNode", "Label")
          subTitleLabel.id = item.subtitle.trim()
          subTitleLabel.text = item.subtitle
          subTitleLabel.height = 40
          layoutGroup.appendChild(subTitleLabel)
          setTypographyOfLabel(subTitleLabel, typographyConstants.ids.bodyMedium)
        end if

        rectangle = createObject("roSGNode", "Rectangle")
        rectangle.width = 0
        rectangle.height = 44
        layoutGroup.appendChild(rectangle)

        if item.hasSubmenu = true
          checkBoxList = createObject("roSGNode", "CaretBoxList")
        else
          checkBoxList = createObject("roSGNode", "CheckBoxList")
        end if

        checkBoxList.id = item.id.trim()
        checkBoxList.itemSize = [510,72]
        checkBoxList.numRows = item.numrows
        checkBoxList.itemSpacing = [0,8]
        checkBoxList.content = item.content
        checkBoxList.defaultCheckedItemIndex = item.defaultcheckeditemindex
        checkBoxList.focusBitmapBlendColor = m.focusedColor
        checkBoxList.observeFieldScoped("itemSelected", "onWasItemSelectedFromMenu")
        layoutGroup.appendChild(checkBoxList)

        outerLayoutGroup.appendChild(layoutGroup)
        m.focusArray.push(checkBoxList)
      end if
    end for

    m.top.appendChild(outerLayoutGroup)
    if m.focusArray <> invalid AND m.focusArray.Count() > 0
      m.focusArray[0].setFocus(true)
    end if
  end if
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.overlayBackground.blendColor = theme.neutralSolidColor
    m.focusedColor = theme.focusedColor
  end if
End Function


' Callback triggered when the component gains focus.
Function onComponentFocus()
  if m.top.hasFocus() = true

    if m.focusArray <> invalid AND m.focusArray.Count() > 0 AND m.focusArray[m.focusIndex] <> invalid
      m.focusArray[m.focusIndex].setFocus(true)
    end if
  end if
End Function


Function onWasItemSelectedFromMenu(msg)
  index = msg.getData()
  list = msg.getROSGNode()
  if list <> invalid AND list.content <> invalid
    m.top.content = list.content.getChild(index)
    m.top.itemUpdated = true
  end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press = false
    return false
  end if

  if key = "down"
    ' If the focusIndex is at the last item in the array, pressing down will have no effect.
    ' If it is not the last item, the focusIndex will be incremented to focus on the next menu item
    if m.focusIndex < m.focusArray.count() - 1
      m.focusIndex++
      handleFocusUpdate()
      return true
    end if

    ' If the focusIndex is at the first item in the array, pressing up will have no effect.
    ' If it is not the first item, the focusIndex will be decremented to focus on the previous menu item in the array.
  else if key = "up"
    if m.focusIndex > 0
      m.focusIndex--
      handleFocusUpdate()
      return true
    end if

  else if key = "back"
    m.top.backOrLeftKeyPress = true
    return true
  end if

  return false
End Function


Function handleFocusUpdate()
  ' For safety, if m.focusIndex exceeds the number of items in focusArray, we reset it to the count - 1 of focusArray
  if m.focusIndex > m.focusArray.count() - 1
    m.focusIndex = m.focusArray.count() - 1
  end if

  ' For safety, if m.focusIndex is less than 0, we reset it to 0
  if m.focusIndex < 0
    m.focusIndex = 0
  end if

  if m.focusArray <> invalid AND m.focusArray.Count() > 0
    focusedNode = m.focusArray[m.focusIndex]
    if focusedNode <> invalid
      focusedNode.setFocus(true)
    end if
  end if
End Function