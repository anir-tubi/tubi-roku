Function init()
  m.top.observeField("show", "onShow")
  m.top.observeField("addView", "onAdd")
  m.top.observeField("removeView", "onRemove")
  m.top.observeField("pushView", "onPush")
  m.top.observeField("popView", "onPop")

  ' Create this dynamically so it doesn't show up as a child node in getChildCount()
  ' this allows for static declaration of NavigationGroup children in XML files
  m.animation = CreateObject("roSGNode", "Animation")
  m.animation.duration = 1.0
  m.animation.easeFunction = "linear"
  m.animation.observeField("state", "onAnimationState")
  m.animateIn = m.animation.createChild("FloatFieldInterpolator")
  m.animateIn.key = [0, 0.5, 1.0]
  m.animateIn.keyValue = [0, 0.5, 1.0]
  m.animateOut = m.animation.createChild("FloatFieldInterpolator")
  m.animateOut.key = [0, 0.5, 1.0]
  m.animateOut.keyValue = [1.0, 0.5, 0]
  m.views = m.top
  m.deviceInfo = CreateObject("roDeviceInfo")

  ' State
  m.currentView = invalid
  m.previousView = invalid
  m.transitioning = false
  m.removeAfterTransition = false ' for remove events where a transition needs to complete first
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

'''''''''''''''''''
' onAnimationState
Function onAnimationState()
  ' Check if there is a queued animation to start
  if m.animation.state = "stopped"
    transitionComplete()
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
  while m.transitioning = false and m.queuedEvents.count() > 0
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
        transition(event.value, m.top.transition, m.top.transitionDuration)

      else if event.event = "push"
        addViewHelper(event.value)
        transition(event.value.id, m.top.transition, m.top.transitionDuration)

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
    transition(nextViewId, m.top.transition, m.top.transitionDuration, true)
  else
    m.views.removeChild(removeView)
  end if
End Function


'''''''''''''''
'
' Transitions
'
'''''''''''''''

Function transition(newId, method, duration, removeAfter=false)
  nextView = invalid
  if newId <> invalid
    nextView = m.views.findNode(newId)
  end if
  currentId = ""
  if m.currentView <> invalid
    currentId = m.currentView.id
  end if
  m.transitioning = true
  m.previousView = m.currentView
  m.currentView = nextView
  m.removeAfterTransition = removeAfter
  if method = "focusPercent"
    transitionFocusPercent(m.previousView, m.currentView, duration)
  else if method = "fade"
    transitionFade(m.previousView, m.currentView, duration)
  else if method = "cascade"
    transitionCascade(m.previousView, m.currentView, duration)
  else
    transitionVisible(m.previousView, m.currentView)
    transitionComplete()
  end if
End Function

' Use 'visible' to transition from one view to another immediately
Function transitionVisible(old, new)
  if old <> invalid
    old.visible = false
  end if
  if new <> invalid
    new.visible = true
  end if
End Function

' Use 'opacity' to transition from one view to another
Function transitionFade(old, new, duration)
  if old <> invalid
    m.animateOut.fieldToInterp = old.id + ".opacity"
    m.animateOut.keyValue = [old.opacity, old.opacity/2, 0]
  else
    m.animateOut.fieldToInterp = ""
  end if
  if new <> invalid
    new.opacity = 0
    new.visible = true
    m.animateIn.fieldToInterp = new.id + ".opacity"
    m.animateIn.keyValue = [0, 0.5, 1]
  else
    m.animateIn.fieldToInterp = ""
  end if
  m.animation.duration = duration
  m.animation.control = "start"
End Function

Function transitionCascade(old, new, duration)
  if old <> invalid
    m.animateOut.fieldToInterp = old.id + ".opacity"
    m.animateOut.keyValue = [old.opacity, 0, 0]
  else
    m.animateOut.fieldToInterp = ""
  end if
  if new <> invalid
    new.opacity = 0
    new.visible = true
    m.animateIn.fieldToInterp = new.id + ".opacity"
    m.animateIn.keyValue = [0, 0, 1]
  else
    m.animateIn.fieldToInterp = ""
  end if
  m.animation.duration = duration
  m.animation.control = "start"
End Function

' Use 'focusPercent' to transition from one view to another
Function transitionFocusPercent(old, new, duration)
  ' make sure that there isn't already an animation happening
  ' TODO: Find the right way to verify that focusPercent is a float field
  if old <> invalid and old.focusPercent <> invalid
    m.animateOut.fieldToInterp = old.id + ".focusPercent"
    m.animateOut.keyValue = [old.focusPercent, 0]
  end if
  if new <> invalid and new.focusPercent <> invalid
    new.focusPercent = 0
    new.visible = true
    m.animateIn.fieldToInterp = new.id + ".focusPercent"
    m.animateIn.keyValue = [0, 1]
  else
    m.animateIn.fieldToInterp = ""
  end if
  m.animation.duration = duration
  m.animation.control = "start"
End Function

Function transitionComplete()
  if m.previousView <> invalid
    m.previousView.visible = false
    if m.removeAfterTransition = true
      m.views.removeChild(m.previousView)
    end if
    m.previousView = invalid
  end if
  if m.currentView <> invalid
    m.top.currentViewId = m.currentView.id
  end if
  m.removeAfterTransition = false
  m.transitioning = false
End Function
