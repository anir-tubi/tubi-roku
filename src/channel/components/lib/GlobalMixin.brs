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


' make sure external config is set in the case that m.global is not immediately available
' limits the number of attempts so the while loop doesn't block into perpetuity.
Function getExternalConfigInfoFromGlobal(fallback = {})
  externalConfigInfo = getFieldFromGlobal("externalConfigInfo")
  if externalConfigInfo = invalid then
    externalConfigInfo = fallback
  end if

  return externalConfigInfo
End Function


' Used to get an external config value at the specified key, falling back to the provided fallback value if the value is invalid.
Function getExternalConfigValueFromGlobal(key, fallback)
  externalConfigInfo = getExternalConfigInfoFromGlobal()
  if externalConfigInfo[key] <> invalid then
    return externalConfigInfo[key]
  end if

  return fallback
End Function


' Returns whether OneTrust consent is enabled based on external config
' Default value is determined by country code:
' - UK (GB), CA: defaults to true
' - All other countries: defaults to false
Function isOneTrustConsentEnabled() as Boolean
  constants = getConstantsFromGlobal()
  if constants <> invalid AND constants.deviceInfo <> invalid AND constants.deviceInfo.countryCode <> invalid
    countryCode = UCase(constants.deviceInfo.countryCode)
    defaultValue = (countryCode = "GB" OR countryCode = "UK" OR countryCode = "CA")
  else
    defaultValue = false
  end if

  return getExternalConfigValueFromGlobal("enable_onetrust_consent", defaultValue)
End Function


' make sure theme is set in the case that m.global is not immediately available
' limits the number of attempts so the while loop doesn't block into perpetuity.
Function getExperimentsInfoFromGlobal()
  return getFieldFromGlobal("experimentsInfo")
End Function


' make sure theme is set in the case that m.global is not immediately available
' limits the number of attempts so the while loop doesn't block into perpetuity.
Function getStatsigExperimentsInfoFromGlobal()
  return getFieldFromGlobal("statsigExperimentsInfo")
End Function


Function getSoTStaticConfigFromGlobal()
  return getFieldFromGlobal("soTStaticConfig")
End Function


' make sure client error config is set in the case that m.global is not immediately available
' limits the number of attempts so the while loop doesn't block into perpetuity.
Function getClientErrorConfigFromGlobal(fallback = {})
  clientErrorConfig = getFieldFromGlobal("clientErrorConfig")
  if clientErrorConfig = invalid then
    clientErrorConfig = fallback
  end if

  return clientErrorConfig
End Function


' getGlobal gets the value of m.global, default invalid
'
Function getGlobal()
  nodeGlobal = invalid
  attempts = 0
  while nodeGlobal = invalid AND attempts < 100
    nodeGlobal = m.global
    attempts += 1
  end while
  return nodeGlobal
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
      ' TODO optimize search by indexing historyIds by contentId
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


' Remove the local version copy of the resume position for a particular video.
' @content: ContentNode, ContentNode to be added or removed from local bookmarks
' @shouldAdd: Boolean, true if the content should be added, false if the content should be removed
Function updateBookmarkLocally(content, shouldAdd = true)
  if content <> invalid
    bookmarkIds = getFieldFromGlobal("bookmarkIds")
    if bookmarkIds <> invalid
      if shouldAdd = true
        bookmarkIds.appendChild(content)
      else
        bookmark = bookmarkIds.findNode(content.id)
        if bookmark <> invalid
          bookmarkIds.removeChild(bookmark)
        end if
      end if
    end if
  end if
End Function
