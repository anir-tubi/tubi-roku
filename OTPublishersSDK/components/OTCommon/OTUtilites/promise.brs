Function createTaskPromise(taskName as String, fields = invalid as Dynamic, returnSignalFieldValue = false as Boolean, signalField = "output" as String) as Object
  task = CreateObject("roSGNode", taskName)
  if fields <> invalid then task.setFields(fields)
  promise = createPromiseFromNode(task, returnSignalFieldValue, signalField)
  task.control = "run"
  return promise
End Function

Function createResolvedPromise(value as Dynamic, delay = 0.01 as Float) as Dynamic
  timer = CreateObject("roSGNode", "Timer")
  timer.duration = delay
  timer.repeat = false
  promise = createPromiseFromNode(timer, false, "fire")
  promise.value = value
  timer.control = "start"
  return promise
End Function

Function createObservablePromise(signalFieldType = "assocarray" as String, fields = invalid as Dynamic, returnSignalFieldValue = false as Boolean, signalField = "output" as String) as Object
  node = CreateObject("roSGNode", "Node")
  if fields <> invalid then node.addFields(fields)
  node.addField(signalField, signalFieldType, false)
  promise = createPromiseFromNode(node, returnSignalFieldValue, signalField)
  return promise
End Function

Function createManualPromise() as Object
  promise = __createPromise()
  promise.resolve = sub(value)
    m.context[m.id + "_callback"](value)
    m.complete = true
  end sub
  return promise
End Function

Function createOnAnimationCompletePromise(animation as Object, startAnimation = true as Boolean, unparentNode = true as Boolean) as Object
  promise = createPromiseFromNode(animation, false, "state")
  promise.shouldSendCallback = Function(node) as Boolean
    if node.state = "stopped" then return true
    return false
  End Function
  promise.unparent = unparentNode

  if startAnimation then animation.control = "start"
  return promise
End Function

Function createPromiseFromNode(node as Object, returnSignalFieldValue as Boolean, signalField as String) as Object
  promise = __createPromise()
  node.id = promise.id
  node.observeFieldScoped(signalField, "__nodePromiseResolvedHandler")
  promise.signalField = signalField
  promise.node = node
  promise.returnSignalFieldValue = returnSignalFieldValue
  return promise
End Function

'---------------------------------------------------------------------
' Everything below here is private and should not be called directly.
'---------------------------------------------------------------------

Function __createPromise() as Object
  id = StrI(rnd(2147483647), 36)
  promise = {
    then: sub(callback as Function)
      m.context[m.id + "_callback"] = callback
    end sub

    dispose: sub()
      if not m.doesExist("context") then return ' already disposed
      m.context.delete(m.id + "_callback")
      m.context.delete(m.id)
      m.delete("context")
      if m.doesExist("node")
        m.node.unobserveFieldScoped(m.signalField)
        m.delete("node")
      end if
    end sub
  }
  promise.context = m
  promise.id = id
  promise.complete = false
  m[id] = promise
  return promise
End Function

sub __nodePromiseResolvedHandler(e as Object)
  node = e.getRoSGNode()
  id = node.id
  promise = m[id]

  isFunc = Function(value)
    valueType = type(value)
    return (valueType = "roFunction") OR (valueType = "Function")
  End Function

  if isFunc(promise.shouldSendCallback) AND promise.shouldSendCallback(node) = false then return

  callback = promise.context[id + "_callback"]
  if isFunc(callback) then
    if promise.returnSignalFieldValue = true then
      callback(promise.node[promise.signalField])
    else if promise.doesExist("value")
      callback(promise.value)
      promise.delete("value")
    else
      callback(promise.node)
    end if
  end if

  'clean up properly properly
  if promise.suppressDispose = invalid then
    promise.dispose()
  end if

  promise.complete = true

  if promise.unparent = true then
    parent = node.getParent()
    if parent <> invalid then parent.removeChild(node)
  end if
end sub