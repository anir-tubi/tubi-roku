' Generate propertly structured DTOs for the MetadataFetchTask
'
' https://martinfowler.com/eaaCatalog/dataTransferObject.html
Function MetadataFetchTaskDTO()
 return {
   createRequest: metadataFetchTaskClient_createRequest
   createBatchRequest: metadataFetchTaskClient_createBatchRequest
   createCancel: metadataFetchTaskClient_createCancel
  }
End Function

' MetadataFetchTask.request

Function metadataFetchTaskClient_createRequest(id, node, field, name, searchText=invalid)
  if id = invalid or id = "" then
    id = CreateObject("roDeviceInfo").GetRandomUUID()
  end if
  if type(node) <> "roSGNode" then
    node = invalid
  end if
  if type(field) <> "String" and type(field) <> "roString"
    field = ""
  end if
  if type(name) <> "String" and type(name) <> "roString"
    name = ""
  end if
  if type(options) <> "roAssociativeArray" then
    options = {}
  end if

  return {
    id: id
    node: node
    field: field
    name: name
    batch: false
    searchText: searchText
  }
End Function


' MetadataFetchTask.batchRequest
Function metadataFetchTaskClient_createBatchRequest(node, field, requests)
  responses = {}
  if type(node) <> "roSGNode" then
    node = invalid
  end if
  if type(field) <> "String" and type(field) <> "roString"
    field = ""
  end if
  if type(requests) <> "roArray" then
    requests = []
  end if

  batchRequest = {
    node: node
    field: field
    requests: {}  ' indexed by request id
  }

  for each r in requests
    ' force a unique id so that we can use it as a key in the response hash
    if r.id = invalid or r.id = "" then
      r.id = CreateObject("roDeviceInfo").GetRandomUUID()
    end if
    r.node = node
    r.field = field
    r.responses = responses
    r.batch = true
    ' TODO(Chris): later use a deep clone here to avoid references to the caller's object
    batchRequest.requests[r.id] = r
  end for
  return batchRequest
End Function

' MetadataFetchTask.cancel
Function metadataFetchTaskClient_createCancel(id, node, field)
  return {
    id: id
    node: node
    field: field
  }
End Function
