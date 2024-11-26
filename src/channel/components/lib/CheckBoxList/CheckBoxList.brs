Function init()
  topRef = m.top
  topRef.update({
    itemComponentName: "CheckButton"
    focusFootprintBitmapUri: "pkg:/images/transparent.png"
    focusBitmapUri: "pkg:/images/menu-focus-$$RES$$.9.png"
    vertFocusAnimationStyle: "floatingFocus"
    drawFocusFeedbackOnTop: false
  })

  topRef.observeFieldScoped("itemSelected", "onItemSelectedChange")
  topRef.observeFieldScoped("defaultCheckedItemIndex", "onDefaultCheckedItemIndexChange")
  m.currentCheckedItemIndex = topRef.defaultCheckedItemIndex
End Function


Function onDefaultCheckedItemIndexChange(msg)
  m.currentCheckedItemIndex = msg.getData()
End Function


Function onItemSelectedChange(msg)
  selectedItemIndex = msg.getData()
  content = m.top.content

  if content <> invalid AND (m.currentCheckedItemIndex <> selectedItemIndex)
    contentCount = content.getChildCount()

    'Removes tick/check mark from all items on list
    for i = 0 to contentCount-1
      unCheckedContentItem = content.getChild(i)
      unCheckedContentItem.checked = false
    end for

    'Adds tick/check mark for item which user selected
    checkedContentItem = content.getChild(selectedItemIndex)
    checkedContentItem.checked = true
  end if

  ' Resetting the current checked item index to new item index.
  m.currentCheckedItemIndex = selectedItemIndex
End Function
