Function navigateToCategoryDetailsScreen(categoryId)
  showCategoryListScreen(m.constants, m.constants.ui.terms.menu, false)
  contentNode = CreateObject("roSGNode", "CategoryContentNode")
  contentNode.id = categoryId
  showCategoryDetailsScreen(contentNode, false)
  categoryListScreen = getFromScreenCache(m.constants.ui.screenIds.categoryListScreen)
  if categoryListScreen <> invalid
    categoryListScreen.jumpToItemById = categoryId
  end if
End Function


Function navigateToNetworkDetailsScreen(networkId)
  showChannelListScreen(m.constants, m.constants.ui.terms.menu, false)
  contentNode = CreateObject("roSGNode", "CategoryContentNode")
  contentNode.id = networkId
  showCategoryDetailsScreen(contentNode, false)
  channelListScreen = getFromScreenCache(m.constants.ui.screenIds.channelListScreen)
  if channelListScreen <> invalid
    channelListScreen.jumpToItemById = networkId
  end if
End Function
