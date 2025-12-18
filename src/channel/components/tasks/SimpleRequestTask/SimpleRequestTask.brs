Function init()
  m.top.functionName = "execSimpleRequestTask"
End Function

Function execSimpleRequestTask()
  tubiLog("SimpleRequestTask.execSimpleRequestTask " + m.top.uri)
  constants = getConstantsFromGlobal()
  requestInstance = TubiRequest(constants.settings)
  response = requestInstance.createAsync(m.top.uri).runSynchronous()
  if m.top.node <> invalid AND m.top.field <> "" then
    m.top.node.setField(m.top.field, response)
  end if
  m.top.response = response
End Function
