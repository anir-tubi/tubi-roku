' make sure constants is set in the case that m.global is not immediately available
' limits the number of attempts so the while loop doesn't block into perpetuity.
Function getConstantsFromGlobal()
  return getFieldFromGlobal("constants")
End Function


' make sure theme is set in the case that m.global is not immediately available
' limits the number of attempts so the while loop doesn't block into perpetuity.
Function getThemeFromGlobal()
  return getFieldFromGlobal("theme")
End Function


' getFieldFromGlobal finds the value on global based on the key input
'
' @fieldName: string, the key on global variable
' returns fieldValue of the globalNode
Function getFieldFromGlobal(fieldName)
  fieldValue = invalid
  attempts = 0
  if fieldName <> invalid
    while fieldValue = invalid and attempts < 100
      globalAA = m.global
      if globalAA <> invalid and globalAA[fieldName] <> invalid
        fieldValue = globalAA[fieldName]
      end if
      attempts += 1
    end while
  end if
  return fieldValue
End Function


' getHistory finds the historyIds based on contentId provided
'
' @contentId: string, the id of any content
' returns history of the given content
Function getHistory(contentId)

  history = invalid
  if contentId <> invalid
    historyIds = getFieldFromGlobal("historyIds")
    if historyIds <> invalid
      history = historyIds.findNode(contentId)
    end if
  end if
  return history

End Function


' getBookmarks finds the bookmarks based on contentId provided
'
' @contentId: string, the id of any content
' returns bookmark of the given content
Function getBookmark(contentId)

  bookmark = invalid
  if contentId <> invalid
    bookmarkIds = getFieldFromGlobal("bookmarkIds")
    if bookmarkIds <> invalid
      bookmark = bookmarkIds.findNode(contentId)
    end if
  end if
  return bookmark

End Function