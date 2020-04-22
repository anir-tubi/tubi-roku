Function init()
  m.nodeHelpers = TubiNodeHelpers()
  m.top.observeField("pop", "onPop")
  m.top.observeField("push", "onPush")
  m.top.observeField("shrinkStack", "onShrinkStack")
  m.top.observeField("clearStack", "onClearStack")
  m.top.observeField("focusCurrent", "onSetCurrentFocusCommand")
End Function


' Indicates that the the current screen should gain focus
Function onSetCurrentFocusCommand()
  screen = m.top.current
  if screen.isInFocusChain() <> true
    screen.setFocus(true)
  end if
  screen.visible = true
End Function


Function onPop()
  tubiLog("ScreenStack.onPop")
  removeStackTop(m.top, m.nodeHelpers)
  newCurrent = getCurrent()
  if newCurrent <> invalid
    m.top.current = newCurrent
    newCurrent.setFocus(true)
    newCurrent.visible = true
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
        else if stackTop.screenLevel <> invalid and newChild.screenLevel <> invalid
          if newChild.screenLevel > stackTop.screenLevel
            exit while
          else if newChild.screenLevel = stackTop.screenLevel and stackTop.isStackable = true
            exit while
          else
            removeStackTop(m.top, m.nodeHelpers)
          end if
        end if

        stackTop = getCurrent()
      end while
    end if

    m.top.appendChild(newChild)
    m.top.current = newChild
    if newChild.shouldFocusWhenPushed <> false
      newChild.setFocus(true)
    end if
    newChild.visible = true

    if oldCurrent <> invalid and oldCurrent.isSameNode(newChild) = false
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


Function onClearStack()
  tubiLog("ScreenStack.onClearStack")
  while m.top.getChildCount() > 0
    removeStackTop(m.top, m.nodeHelpers)
  end while

  m.top.current = invalid
End Function


' Helper for removing the top most screen in the stack
Function removeStackTop(stack, nodeHelpers)
  size = stack.getChildCount()
  child = stack.getChild(size - 1)
  nodeHelpers.unobserveAllScoped(child)
  child.visible = false
  stack.removeChild(child)
  return stack
End Function