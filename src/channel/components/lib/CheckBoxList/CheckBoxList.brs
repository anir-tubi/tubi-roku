Function init()
  topRef = m.top
  topRef.update({
    itemComponentName: "CheckButton"
    focusFootprintBitmapUri: "pkg:/images/transparent.png"
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

  if content <> invalid
    if content.id <> "sendFeedbackMenu" AND (m.currentCheckedItemIndex <> selectedItemIndex)
      contentCount = content.getChildCount()

      'Removes tick/check mark from all items on list
      for i = 0 to contentCount-1
        unCheckedContentItem = content.getChild(i)
        unCheckedContentItem.checked = false
      end for

      'Adds tick/check mark for item which user selected
      checkedContentItem = content.getChild(selectedItemIndex)

      if checkedContentItem <> invalid
        checkedContentItem.checked = true
      end if

      ' Resetting the current checked item index to new item index.
      m.currentCheckedItemIndex = selectedItemIndex
    end if
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) As Boolean
  if press then
    if key = "OK"
      m.top.itemSelected = m.top.itemFocused
      return true
    end if
  end if

  return false
End Function
