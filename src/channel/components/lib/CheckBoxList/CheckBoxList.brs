Function init()
  topRef = m.top
  topRef.update({
    itemComponentName: "CheckButton"
    focusFootprintBitmapUri: "pkg:/images/transparent.png"
    focusBitmapUri: "pkg:/images/menu-focus-$$RES$$.9.png"
    vertFocusAnimationStyle: "floatingFocus"
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
  topRef = m.top

  if m.currentCheckedItemIndex <> selectedItemIndex
    unCheckedContentItem = topRef.content.getChild(m.currentCheckedItemIndex)
    unCheckedContentItem.checked = false

    checkedContentItem = topRef.content.getChild(selectedItemIndex)
    checkedContentItem.checked = true
    ' Resetting the current checked item index to new item index.
    m.currentCheckedItemIndex = selectedItemIndex
  end if
End Function
