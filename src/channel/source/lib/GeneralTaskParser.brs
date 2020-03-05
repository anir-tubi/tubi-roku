' parseHomescreenSuccess 
'
' this is helper function for parsing home screen success data
' @response : AA / invalid
' returns success ContentNode
Function parseHomescreenSuccess(response as Object) as Dynamic

  contentNode = CreateObject("roSGNode", "ContentNode")
  
  if response <> invalid and response.data <> invalid
    ' read values from response object and set the required values to contentNode
  end if
  
  return contentNode

End Function


' parseHomescreenError 

' this is helper function for parsing home screen error data
' @error : AA / invalid
' returns error ContentNode
Function parseHomescreenError(error as Object) as Dynamic

  eContentNode = CreateObject("roSGNode", "ErroContentNode")

  if error <> invalid 
    if error.code <> invalid
      eContentNode.code = error.code
    end if
    if error.failreason <> invalid
      eContentNode.title = error.failreason 
    end if
    if error.data <> invalid
      eContentNode.description = error.data
    end if    
  end if
  
  return eContentNode  

End Function