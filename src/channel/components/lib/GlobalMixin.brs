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
    while fieldValue = invalid AND attempts < 100
      nodeGlobal = m.global
      if nodeGlobal <> invalid
        fieldValue = nodeGlobal[fieldName]
      end if
      attempts += 1
    end while
  end if
  return fieldValue
End Function


' getHistory finds the historyIds based on contentId provided
'
' @contentId: string, the id of any content
' returns history of the passed content id or invalid if there is no history for the content id
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



' Remove the local version copy of the resume position for a particular video.
' @contentId: String, ContentNode to be removed from local history
Function removeHistoryLocally(contentId)
  if contentId <> invalid
    historyNode = getHistory(contentId)
    historyIds = getFieldFromGlobal("historyIds")
    if historyIds <> invalid AND historyNode <> invalid
      historyIds.removeChild(historyNode)
    end if
  end if
End Function


' getLike finds the like/dislike node based on contentId provided
'
' @contentId: string, the id of any content
' returns a LikeContentNode of the given content
Function getLike(contentId)

  likeNode = invalid
  if contentId <> invalid
    likeIds = getFieldFromGlobal("likeIds")
    if likeIds <> invalid
      likeNode = likeIds.findNode(contentId)
    end if
  end if
  return likeNode

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
