Function navigateToCategoryDetailsScreen(categoryId)
  showCategoryPanelListScreen(m.constants, false, categoryId)
End Function


Function navigateToNetworkDetailsScreen(networkId)
  showCategoryPanelListScreen(m.constants, false, m.constants.ui.categoryIds.networks)

  contentNode = CreateObject("roSGNode", "CategoryContentNode")
  contentNode.id = networkId
  showCategoryDetailsScreen(contentNode, false)

  channelPanelListScreen = getFromScreenCache(m.constants.ui.screenIds.categoryPanelListScreen)
  if channelPanelListScreen <> invalid
    channelPanelListScreen.jumpToCategoryItemByID = { id: m.constants.ui.categoryIds.networks, subId: networkId }
  end if

End Function


' Makes a lightweight getCollectionInfo API call to determine the app content type,
' then routes to CollectionScreen (CREATOR) or PivotDetailScreen (all other types).
' @param content - roSGNode, the app content item selected by the user
Function fetchAppContentTypeAndNavigate(content) as Void
  reqInfo = m.cmsApi.createGetCollectionInfo(content.id, { params: { group_size: 1, contents_limit: 1 } })
  if reqInfo = invalid then
    return
  end if

  showHideSpinner(true)

  reqInfo.requestType = m.constants.reqNames.getCollection
  reqInfo.responseType = "node"
  reqInfo.responseContext = { id: content.id, title: content.title }
  reqInfo.successCallback = onFetchAppContentTypeSuccess
  reqInfo.errorCallback = onFetchAppContentTypeError
  m.makeRequest(reqInfo)
End Function


' Handles success response from getCollectionInfo for app content type routing.
' Routes to CollectionScreen for CREATOR type, PivotDetailScreen for all others.
' @param response - roSGNode, parsed collection response containing app metadata and responseContext
Function onFetchAppContentTypeSuccess(response) as Void
  showHideSpinner(false)

  if response <> invalid AND response.responseContext <> invalid
    ctx = response.responseContext

    appType = ""
    if response.app <> invalid AND response.app.type <> invalid
      appType = response.app.type
    end if

    if UCase(appType) = m.constants.ui.appTypes.creator OR appType = ""
      showCollectionScreen(ctx.id)
    else
      showPivotDetailScreen({ id: ctx.id, title: ctx.title })
    end if
  end if
End Function


' Handles error response from getCollectionInfo for app content type routing.
' Falls back to CollectionScreen on error.
' @param response - assocarray, contains code and responseContext
Function onFetchAppContentTypeError(response) as Void
  showHideSpinner(false)

  if response <> invalid AND response.responseContext <> invalid
    showCollectionScreen(response.responseContext.id)
  end if
End Function
