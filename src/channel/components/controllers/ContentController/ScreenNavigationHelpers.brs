Function navigateToCategoryDetailsScreen(categoryId)
  if (getExperimentResource("roku_category_redesign", "roku_category_redesign_v2", true).enabled = true)
    showCategoryPanelListScreen(m.constants, false, categoryId)
  else
    showCategoryListScreen(m.constants, false)
    contentNode = CreateObject("roSGNode", "CategoryContentNode")
    contentNode.id = categoryId
    showCategoryDetailsScreen(contentNode, false)
    categoryListScreen = getFromScreenCache(m.constants.ui.screenIds.categoryListScreen)
    if categoryListScreen <> invalid
      categoryListScreen.jumpToItemById = categoryId
    end if
  end if
End Function


Function navigateToNetworkDetailsScreen(networkId)
  if (getExperimentResource("roku_category_redesign", "roku_category_redesign_v2", true).enabled = true)
    showCategoryPanelListScreen(m.constants, false, m.constants.ui.categoryIds.networks)
  else
    showChannelListScreen(m.constants, false)
  end if
  contentNode = CreateObject("roSGNode", "CategoryContentNode")
  contentNode.id = networkId
  showCategoryDetailsScreen(contentNode, false)

  if (getExperimentResource("roku_category_redesign", "roku_category_redesign_v2", false).enabled = true)
    channelPanelListScreen = getFromScreenCache(m.constants.ui.screenIds.categoryPanelListScreen)
    if channelPanelListScreen <> invalid 
      channelPanelListScreen.jumpToCategoryItemByID = {id: m.constants.ui.categoryIds.networks, subId: networkId}
    end if
  else
    channelListScreen = getFromScreenCache(m.constants.ui.screenIds.channelListScreen)
    if channelListScreen <> invalid 
      channelListScreen.jumpToItemById = networkId
    end if
  end if
End Function
