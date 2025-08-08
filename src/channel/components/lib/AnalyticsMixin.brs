' Appends additional context values to the event values.
' @eventValues: assocArray, the event values to append the context values too
' @content: assocArray, the content object
' @isAdultParentalLevel: boolean, true if the user is an adult parental level
Function appendContentUserContextValues(eventValues, content, isAdultParentalLevel)
  eventValues.isCdc = content <> invalid AND content.isCdc = true
  eventValues.isAdultParentalLevel = isAdultParentalLevel
End Function
