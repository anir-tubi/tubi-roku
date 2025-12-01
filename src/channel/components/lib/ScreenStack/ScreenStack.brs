Function init()
  m.nodeHelpers = TubiNodeHelpers()
  m.top.observeField("pop", "onPop")
  m.top.observeField("push", "onPush")
  m.top.observeField("shrinkStack", "onShrinkStack")
  m.top.observeField("idToRemoveScreenFromStack", "onIdToRemoveScreenFromStack")
  m.top.observeField("screenToRemove", "onScreenToRemove")
  m.top.observeField("clearStack", "onClearStack")
  m.top.observeField("focusCurrent", "onSetCurrentFocusCommand")
End Function


' Indicates that the the current screen should gain focus
Function onSetCurrentFocusCommand()
  screen = m.top.current
  if screen <> invalid
    if screen.isInFocusChain() <> true
      screen.setFocus(true)
    end if
    screen.visible = true
  end if
End Function


Function onPop()
  tubiLog("ScreenStack.onPop")
  removeStackTop(m.top, m.nodeHelpers)
  newCurrent = getCurrent()
  if newCurrent <> invalid
    m.top.current = newCurrent
    newCurrent.setFocus(true)
    newCurrent.visible = true
    if newCurrent.hasField("enabled") = true
      newCurrent.enabled = true
    end if
    ' Setting the currentUpdated field to true after the new screen is setfocus.
    ' If we do not do it after the new screen recieves focus.
    ' Because if we set it before the newCurrent.setFocus(true) than if we use the currentUpdated and display a modal for example will result in modal loosing focus because we re-setting focus to screen.
    m.top.currentUpdated = true
  else
    m.top.isEmpty = true
  end if
End Function


Function onPush(msg)
  tubiLog("ScreenStack.onPush")
  newChild = msg.getData()

  'reset the field so any changes to the screen set on m.top.push don't trigger onPush() again
  m.top.push = invalid

  if newChild <> invalid
    oldCurrent = getCurrent()

    ' Remove any screens (to prevent screen looping) as necessary
    ' Screens cannot be pushed on top of a screen whose screenLevel is greater than theirs.
    ' For example, if the home screen is screenLevel = 10, and the search screen is screenLevel = 20,
    ' the search screen can be pushed on top of the home screen,
    ' but the home screen can not be pushed on top of the search screen.
    ' This is done to prevent screen looping where screen A calls screen B, which in turn calls screen A, etc.
    ' Screens can be flagged as isStackable = true, so that screens with the same screenLevel can stack on top of
    ' each other (for example, details screens when using You May Also Like).
    stackTop = getCurrent()
    if stackTop <> invalid
      while true
        if stackTop = invalid
          exit while
        else if stackTop.screenLevel <> invalid AND newChild.screenLevel <> invalid
          if newChild.screenLevel > stackTop.screenLevel
            exit while
          else if newChild.screenLevel = stackTop.screenLevel AND stackTop.isStackable = true
            exit while
          else
            removeStackTop(m.top, m.nodeHelpers)
          end if
        end if

        stackTop = getCurrent() 'bs:disable-line LINT1005
      end while
    end if

    m.top.appendChild(newChild)
    m.top.current = newChild
    m.top.currentUpdated = true
    if newChild.shouldFocusWhenPushed <> false
      newChild.setFocus(true)
    end if
    newChild.visible = true

    if oldCurrent <> invalid AND oldCurrent.isSameNode(newChild) = false
      oldCurrent.visible = false
    end if
  end if
End Function


Function getCurrent()
  size = m.top.getChildCount()
  return m.top.getChild(size - 1)
End Function


Function onShrinkStack(msg)
  stack = m.top
  stackCount = stack.getChildCount()
  keepAmt = msg.getData()
  removeAmt = stackCount - keepAmt
  if keepAmt < stackCount
    stack.removeChildrenIndex(removeAmt, 0)
  end if
End Function


Function onIdToRemoveScreenFromStack(msg)
  stack = msg.getRoSGNode()
  stackCount = stack.getChildCount()

  if stackCount > 1
    '//omly proceed to remove a screen if there are more than 1 screen in the stack.
    sRemoveID = msg.getData()

    nStartDepth = stackCount - 1

    '//go through the stack and find the top most screen with the given ID
    i = nStartDepth
    while i > 0
      screen = stack.getChild(i)
      if screen.id = sRemoveID
        stack.removeChildIndex(i)
        exit while
      end if
      i = i - 1
    end while

  end if
End Function


' Removes a specific screen node from the stack
' @param msg - Message containing the screen node to remove
Function onScreenToRemove(msg)
  screenToRemove = msg.getData()
  if screenToRemove <> invalid
    m.nodeHelpers.unobserveAllScoped(screenToRemove)
    m.top.removeChild(screenToRemove)
  end if
End Function


Function onClearStack()
  tubiLog("ScreenStack.onClearStack")
  while m.top.getChildCount() > 0
    removeStackTop(m.top, m.nodeHelpers)
  end while

  m.top.current = invalid
  m.top.currentUpdated = true
End Function


' Helper for removing the top most screen in the stack
Function removeStackTop(stack, nodeHelpers)
  size = stack.getChildCount()
  child = stack.getChild(size - 1)
  nodeHelpers.unobserveAllScoped(child)
  if child <> invalid
    child.visible = false
    stack.removeChild(child)
  end if
  return stack
End Function
