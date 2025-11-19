Function init()
  m.top.observeFieldScoped("focusedChild", "onFocusedChildChange")
End Function


Function onFocusedChildChange()
  ' If we do not set focus 4670X was forcing device reboot :|
  if m.top.hasFocus() = true then
    m.buttonList.setFocus(true)
  end if

  'if modal loses focus and we are not currently hidden (mainly because videoplayer gains focus or homescreen gains focus), Just close the modal
  if m.top.isHidden = false AND m.top.isInFocusChain() = false
    m.top.exitButton = "back"
  end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press = true
    ' Only gets executed if we have scrollable field at top and it is true.
    ' Mainly for default modals.
    if m.top.scrollable = true then
      if key = "up" AND m.buttonList.hasFocus() = true then
        m.scrollableMessage.scrollbarThumbBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"
        m.scrollableMessage.setFocus(true)
      else if (key = "down" OR key = "left" OR key = "right" OR key = "OK") AND m.scrollableMessage.hasFocus() = true then
        m.scrollableMessage.scrollbarThumbBitmapUri = "pkg:/images/menu-disabled-focus-$$RES$$.9.png"
        m.buttonList.setFocus(true)
      end if
    end if

    ' removed alias from xml and setting buttonSelected interface value here, to play default Roku positive audio sound when user press "OK" on any dialog modal button
    if key = "OK" AND m.buttonList.hasFocus() = true
      m.top.buttonSelected = m.buttonList.itemSelected
    end if

    if key = "back" OR key = "options" then
      m.top.exitButton = key
    end if

    return true
  end if

  return false
End Function

' Returns width of the horizontal seperated button list based on the input parameters.
' @buttonWidth: Integer, Width of the button. Since all buttons have same width.
' @totalButtons: Integer, Total number of buttons in the list.
' @spacing: Integer, Spacing between each buttons.
' @gutterWidth: Integer, Margin on the left and right side of the button list.
Function getHorizontalButtonListWidth(buttonWidth, totalButtons, spacing, gutterWidth)
  return (buttonWidth * totalButtons) + (spacing * (totalButtons - 1)) + (gutterWidth * 2)
End Function
