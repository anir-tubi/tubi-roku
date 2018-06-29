Function init()
  m.top.observeField("show", "onShow")
  m.top.observeField("addView", "onAdd")
  m.top.observeField("removeView", "onRemove")
  m.top.observeField("pushView", "onPush")
  m.top.observeField("popView", "onPop")

  m.views = m.top
  m.deviceInfo = CreateObject("roDeviceInfo")

  ' State
  m.currentView = invalid
  m.previousView = invalid
  m.queuedEvents = [] ' queuing events guarantees that we don't have visual artifacts
                      ' when events come in during an active transition.
End Function


'''''''''''''
'
' OBSERVERS
'
'''''''''''''


''''''''''''
' onShow
Function onShow(msg)
  m.queuedEvents.push({
    event: "show"
    value: msg.GetData() ' view id
  })
  processQueuedEvents()
End Function

'''''''''''''
' onAdd
Function onAdd(msg)
  newView = msg.GetData()
  if newView <> invalid
    m.top.addView = invalid ' to clear reference and avoid triggering this again
    m.queuedEvents.push({
      event: "add"
      value: newView
    })
    processQueuedEvents()
  end if
End Function

'''''''''''''
' onRemove
Function onRemove(msg)
  if msg.GetData() <> invalid
    m.queuedEvents.push({
      event: "remove"
      value: msg.GetData()  ' view id
    })
    processQueuedEvents()
  end if
End Function

'''''''''''''
' onPush
Function onPush(msg)
  newView = msg.GetData()
  if newView <> invalid
    m.top.pushView = invalid ' to clear reference and avoid triggering this again
    m.queuedEvents.push({
      event: "push"
      value: newView
    })
    processQueuedEvents()
  end if
End Function

'''''''''''''
' onPop
Function onPop(msg)
  popValue = msg.GetData()
  if popValue = true
    m.queuedEvents.push({ event: "pop" })
    processQueuedEvents()
  end if
End Function

'''''''''''''''''
' onKeyEvent
Function onKeyEvent(key, press)
  if press = true and key = "back" and m.top.backToPop = true
    m.queuedEvents.push({ event: "pop" })
    processQueuedEvents()
    return true
  end if
  return false
End Function


'''''''''''''''
'
' ACTIONS
'
'''''''''''''''

Function processQueuedEvents()
  ' do this in a while loop since some events are immediate, like "add"
  while m.queuedEvents.count() > 0
    event = m.queuedEvents.shift()
    if event <> invalid
      if event.event = "pop"
        ' TODO(Chris): add a special case here where we can collapse adjacent 
        ' 'pop' events to go immediately to the final screen
        viewCount = m.views.getChildCount()
        if viewCount > 0
          removeView = m.views.getChild(viewCount-1)
          removeViewHelper(removeView)
        end if

      else if event.event = "show"
        ' TODO(Chris): add a special case here where we can collapse adjacent 
        ' 'show' events to go immediately to the final show
        transition(event.value, false)

      else if event.event = "push"
        addViewHelper(event.value)
        transition(event.value.id, false)

      else if event.event = "add"
        addViewHelper(event.value)

      else if event.event = "remove"
        removeView = m.views.findNode(event.value)
        if removeView <> invalid
          removeViewHelper(removeView)
        end if
      end if
    end if
  end while
End Function

'''''''''''''''''''
' addViewHelper
Function addViewHelper(newView)
  ' always add invisible so it doesn't show on top of current view
  newView.visible = false
  if newView.id = ""
    newView.id = m.deviceInfo.GetRandomUUID()
    print "WARN: empty id for view, generating unique id " + newView.id
  end if
  duplicateCheck = m.views.findNode(newView.id)
  if duplicateCheck <> invalid and duplicateCheck.isSameNode(newView)
    print "WARN: Ignoring attempt to add a view which was previously added: "; newView.id
  else
    if duplicateCheck <> invalid
      ' This case will break because the animations need to target
      ' a node by id
      print "WARN: Adding a view with non-unique id: "; newView.id
    end if
    m.views.appendChild(newView)
  end if
End Function

'''''''''''''''''''
' removeViewHelper
Function removeViewHelper(removeView)
  if m.currentView <> invalid and m.currentView.isSameNode(removeView) = true
    ' transition away, then remove
    nextViewId = ""
    viewCount = m.views.getChildCount()
    for i=viewCount-1 to 0 step -1
      candidateView = m.views.getChild(i)
      if candidateView.isSameNode(removeView) = false
        nextViewId = candidateView.id
        exit for
      end if
    end for
    transition(nextViewId, true)
  else
    m.views.removeChild(removeView)
  end if
End Function


'''''''''''''''
'
' Transitions
'
'''''''''''''''

Function transition(newId, removeAfter)
  nextView = invalid
  if newId <> invalid
    nextView = m.views.findNode(newId)
  end if

  ' swap internal references
  m.previousView = m.currentView
  m.currentView = nextView

  ' Set visibility
  if m.previousView <> invalid
    m.previousView.visible = false
  end if
  if m.currentView <> invalid
    m.currentView.visible = true
    m.top.currentViewId = m.currentView.id
  end if

  ' remove old view for pop/remove actions
  if m.previousView <> invalid and removeAfter = true
    m.views.removeChild(m.previousView)
    m.previousView = invalid
  end if
End Function
