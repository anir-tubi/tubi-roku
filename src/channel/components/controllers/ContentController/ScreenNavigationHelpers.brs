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
