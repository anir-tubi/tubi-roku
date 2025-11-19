'@TestSuite [TubiCache] TubiCache.brs

'@Setup
Function TubiCacheSetup()
  m.constants = getConstants()
  nodeHelpers = TubiNodeHelpers()
  m.cache = TubiCache(nodeHelpers, m.constants.ui.cacheableScreenIds, m.constants.ui.permanentlyCachedContentIds)

  m.generateNodeTree = tubiNodeHelpersTest_generateNodeTree

  m.testScreenId = "UnitTestScreen"
End Function


'@BeforeEach
Function TubiCache_BeforeEach() as Void
  m.cache.emptyScreenCache()
  m.cache.emptyContentCache()
  m.cache.permanentContentIds = m.constants.ui.permanentlyCachedContentIds
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiCache.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test setInScreenCache unit tests
Function tubiCache_setInScreenCache_test()
  baseScreen = CreateObject("roSGNode", "BaseScreen")

  ' check if non cacheable screen is added to screen cache
  baseScreen.id = "base_screen_test"

  m.cache.setInScreenCache(baseScreen)
  cachedScreen = m.cache.screenCache["base_screen_test"]

  m.assertInvalid(cachedScreen)


  ' check if cacheable screen is added to screen cache
  baseScreen.id = m.constants.ui.screenIds.homeScreen

  m.cache.setInScreenCache(baseScreen)
  cachedScreen = m.cache.screenCache[m.constants.ui.screenIds.homeScreen]

  m.assertNotInvalid(cachedScreen)
  m.assertTrue(baseScreen.isSameNode(cachedScreen))
End Function


'@Test getFromScreenCache unit tests
Function tubiCache_getFromScreenCache_test()
  baseScreen = CreateObject("roSGNode", "BaseScreen")
  baseScreen.id = m.constants.ui.screenIds.homeScreen
  m.cache.setInScreenCache(baseScreen)
  cachedScreen = m.cache.getFromScreenCache(m.constants.ui.screenIds.homeScreen)

  ' check if screen is returned from screen cache
  m.assertTrue(baseScreen.isSameNode(cachedScreen))

  ' check if screen is still in the screen cache
  m.assertNotInvalid(m.cache.screenCache[m.constants.ui.screenIds.homeScreen])
End Function


'@Test deleteFromScreenCache unit tests
Function tubiCache_deleteFromScreenCache_test()
  baseScreen = CreateObject("roSGNode", "BaseScreen")
  baseScreen.id = m.constants.ui.screenIds.homeScreen

  baseScreen2 = CreateObject("roSGNode", "BaseScreen")
  baseScreen2.id = m.constants.ui.screenIds.movieScreen

  m.cache.setInScreenCache(baseScreen)
  m.cache.setInScreenCache(baseScreen2)
  m.assertTrue(m.cache.screenCache.count() = 2)

  isDeleted = m.cache.deleteFromScreenCache(m.constants.ui.screenIds.homeScreen)
  m.assertTrue(isDeleted)
  m.assertTrue(m.cache.screenCache.count() = 1)

  ' check if screen still in screen cache
  m.assertInvalid(m.cache.screenCache[m.constants.ui.screenIds.homeScreen])
End Function


'@Test emptyScreenCache unit tests
Function tubiCache_emptyScreenCache_test()
  baseScreen = CreateObject("roSGNode", "BaseScreen")
  baseScreen.id = m.constants.ui.screenIds.homeScreen

  baseScreen2 = CreateObject("roSGNode", "BaseScreen")
  baseScreen2.id = m.constants.ui.screenIds.movieScreen

  m.cache.setInScreenCache(baseScreen)
  m.cache.setInScreenCache(baseScreen2)

  m.cache.emptyScreenCache()

  cachedScreen1 = m.cache.getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  cachedScreen2 = m.cache.getFromScreenCache(m.constants.ui.screenIds.movieScreen)

  m.assertInvalid(cachedScreen1)
  m.assertInvalid(cachedScreen2)
  m.assertTrue(m.cache.screenCache.count() = 0)
End Function


'@Test setInContentCache unit tests
Function tubiCache_setInContentCache_test()
  ' temporarily use a smaller max content nodes for running the test so we don't have to
  ' generate so many content nodes to surpass the maximum
  maxContentNodes = m.cache.maxContentNodes
  m.cache.maxContentNodes = 100

  content = m.generateNodeTree(2, 1) 'creates 2 nodes
  content.id = "test_content"

  isCached = m.cache.setInContentCache(content, m.testScreenId)

  ' check if content is in the content cache
  cachedContent = m.cache.contentCache["test_content"]
  m.assertTrue(isCached)
  m.assertNotInvalid(cachedContent)
  m.assertTrue(cachedContent.isSameNode(content))

  ' check if content is kicked out of the cache if max nodes are reached
  subMaxContent = m.generateNodeTree(2, 99) ' creates 100 nodes
  subMaxContent.id = "submax_content"
  isSubMaxedCached = m.cache.setInContentCache(subMaxContent, m.testScreenId)

  m.assertTrue(isSubMaxedCached)
  m.assertNotInvalid(m.cache.contentCache["submax_content"])

  ' initial content should be kicked out of the cache
  m.assertInvalid(m.cache.contentCache["test_content"])

  ' check if content is kicked out of the cache if attempting to add more nodes than allowed in cache
  maxContent = m.generateNodeTree(2, 100) ' creates 101 nodes
  maxContent.id = "max_content"
  isMaxedCached = m.cache.setInContentCache(maxContent, m.testScreenId)

  ' maxContent should not be added because it has too many content nodes
  m.assertFalse(isMaxedCached)
  m.assertInvalid(m.cache.contentCache["max_content"])

  ' subMaxContent should not be kicked out if maxContent is not added
  m.assertNotInvalid(m.cache.contentCache["submax_content"])

  m.cache.maxContentNodes = maxContentNodes
End Function


'@Test getFromContentCache unit tests
Function tubiCache_getFromContentCache_test()
  content1 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content1.id = "test_content1"
  content1.addField("validUntil", "integer", false)
  content1.validUntil = Uptime(0) + 1000

  content2 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content2.id = "test_content2"

  isCached1 = m.cache.setInContentCache(content1, m.testScreenId)
  m.assertTrue(isCached1)

  isCached2 = m.cache.setInContentCache(content2, m.testScreenId)
  m.assertTrue(isCached2)

  ' get content from content cache
  cachedContent1 = m.cache.getFromContentCache("test_content1")

  m.assertNotInvalid(cachedContent1)
  m.assertTrue(cachedContent1.isSameNode(content1))

  ' check if the first content added is at the top of the content cache order after it has been
  ' fetched via the getter
  m.assertTrue(m.cache.contentCacheOrder.count() = 2)
  topCache = m.cache.contentCacheOrder[1]
  m.assertEqual(topCache.id, "test_content1")

  ' check if gets invalid if the content in the cache is no longer valid
  cachedContent1.validUntil = 0
  cachedContent1 = m.cache.getFromContentCache("test_content1")
  m.assertInvalid(cachedContent1)

  ' check if content is returned from the cache if it has no validUntil field
  cachedContent2 = m.cache.getFromContentCache("test_content2")
  m.assertNotInvalid(cachedContent2)
  m.assertTrue(cachedContent2.isSameNode(content2))
End Function


'@Test addToContentCacheOrder unit tests
Function tubiCache_addToContentCacheOrder_test()
  content1 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content1.id = "test_content1"

  content2 = m.generateNodeTree(2, 4) 'creates 5 nodes
  content2.id = "test_content2"

  m.cache.permanentContentIds["test_content1"] = true

  isAdded1 = m.cache.addToContentCacheOrder(content1)
  isAdded2 = m.cache.addToContentCacheOrder(content2)

  m.assertTrue(isAdded1)
  m.assertTrue(isAdded2)

  m.assertEqual(m.cache.contentCacheOrder[0].id, "test_content1")
  m.assertEqual(m.cache.contentCacheOrder[1].id, "test_content2")
  m.assertEqual(m.cache.contentCacheOrder[0].totalContentNodeCount, 2)
  m.assertEqual(m.cache.contentCacheOrder[1].totalContentNodeCount, 5)
  m.assertEqual(m.cache.contentCacheOrder[0].isPermanent, true)
  m.assertEqual(m.cache.contentCacheOrder[1].isPermanent, false)
  m.cache.emptyContentCache()

  ' test edge case when content is added with no id
  content1 = m.generateNodeTree(2, 1) 'creates 2 nodes
  isAdded1 = m.cache.addToContentCacheOrder(content1)
  m.assertFalse(isAdded1)
  m.assertEqual(m.cache.contentCacheOrder.count(), 0)
End Function


'@Test deleteContentFromCache unit tests
Function tubiCache_deleteContentFromCache_test()
  content1 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content1.id = "test_content1"

  content2 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content2.id = "test_content2"

  m.cache.setInContentCache(content1, m.testScreenId)
  m.cache.setInContentCache(content2, m.testScreenId)
  m.assertTrue(m.cache.contentCache.count() = 2)

  isDeleted1 = m.cache.deleteContentFromCache("test_content1")
  m.assertTrue(isDeleted1)
  m.assertTrue(m.cache.contentCache.count() = 1)
  m.assertInvalid(m.cache.contentCache["test_content1"])
  m.assertNotInvalid(m.cache.contentCache["test_content2"])

  isDeleted2 = m.cache.deleteContentFromCache("test_content2")
  m.assertTrue(isDeleted2)
  m.assertTrue(m.cache.contentCache.count() = 0)
  m.assertInvalid(m.cache.contentCache["test_content2"])
End Function


'@Test deleteFromContentCacheOrder unit tests
Function tubiCache_deleteFromContentCacheOrder_test()
  ' check deleting the top of the order
  content1 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content1.id = "test_content1"

  content2 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content2.id = "test_content2"

  content3 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content3.id = "test_content3"

  m.cache.setInContentCache(content1, m.testScreenId)
  m.cache.setInContentCache(content2, m.testScreenId)
  m.cache.setInContentCache(content3, m.testScreenId)
  m.assertTrue(m.cache.contentCacheOrder.count() = 3)

  isDeleted3 = m.cache.deleteFromContentCacheOrder("test_content3")
  m.assertTrue(isDeleted3)
  m.assertTrue(m.cache.contentCacheOrder.count() = 2)
  m.assertTrue(m.cache.contentCacheOrder[0].id <> "test_content3")
  m.assertTrue(m.cache.contentCacheOrder[1].id <> "test_content3")

  ' check deleting the bottom of the order
  m.cache.emptyContentCache()
  content1 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content1.id = "test_content1"

  content2 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content2.id = "test_content2"

  content3 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content3.id = "test_content3"

  m.cache.setInContentCache(content1, m.testScreenId)
  m.cache.setInContentCache(content2, m.testScreenId)
  m.cache.setInContentCache(content3, m.testScreenId)
  m.assertTrue(m.cache.contentCacheOrder.count() = 3)

  isDeleted1 = m.cache.deleteFromContentCacheOrder("test_content1")
  m.assertTrue(isDeleted1)
  m.assertTrue(m.cache.contentCacheOrder.count() = 2)
  m.assertTrue(m.cache.contentCacheOrder[0].id <> "test_content1")
  m.assertTrue(m.cache.contentCacheOrder[1].id <> "test_content1")

  ' check deleting the middle of the order
  m.cache.emptyContentCache()
  content1 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content1.id = "test_content1"

  content2 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content2.id = "test_content2"

  content3 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content3.id = "test_content3"

  m.cache.setInContentCache(content1, m.testScreenId)
  m.cache.setInContentCache(content2, m.testScreenId)
  m.cache.setInContentCache(content3, m.testScreenId)
  m.assertTrue(m.cache.contentCacheOrder.count() = 3)

  isDeleted2 = m.cache.deleteFromContentCacheOrder("test_content2")
  m.assertTrue(isDeleted2)
  m.assertTrue(m.cache.contentCacheOrder.count() = 2)
  m.assertTrue(m.cache.contentCacheOrder[0].id <> "test_content2")
  m.assertTrue(m.cache.contentCacheOrder[1].id <> "test_content2")
End Function


'@Test emptyContentCache unit tests
Function tubiCache_emptyContentCache_test()
  content1 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content1.id = "test_content1"

  content2 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content2.id = "test_content2"

  content3 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content3.id = "test_content3"

  m.cache.setInContentCache(content1, m.testScreenId)
  m.cache.setInContentCache(content2, m.testScreenId)
  m.cache.setInContentCache(content3, m.testScreenId)
  m.assertTrue(m.cache.contentCache.count() = 3)
  m.assertTrue(m.cache.contentCacheOrder.count() = 3)

  m.cache.emptyContentCache()
  m.assertTrue(m.cache.contentCache.count() = 0)
  m.assertTrue(m.cache.contentCacheOrder.count() = 0)
End Function


'@Test getCachedNodeCount unit tests
Function tubiCache_getCachedNodeCount_test()
  cachedNodeCount = m.cache.getCachedNodeCount()
  m.assertEqual(cachedNodeCount, 0)

  content1 = m.generateNodeTree(3, 2) 'generates 7 nodes
  content1.id = "content1"
  content2 = m.generateNodeTree(2, 5) 'generates 6 nodes
  content2.id = "content2"
  content3 = m.generateNodeTree(7, 1) 'generates 7 nodes
  content3.id = "content3"

  m.cache.setInContentCache(content1, m.testScreenId)
  m.cache.setInContentCache(content2, m.testScreenId)
  m.cache.setInContentCache(content3, m.testScreenId)

  cachedNodeCount = m.cache.getCachedNodeCount()
  m.assertEqual(cachedNodeCount, 20)
End Function



'@Test getLruContentFromCache unit tests
Function tubiCache_getLruContentFromCache_test()
  content1 = m.generateNodeTree(2, 1)
  content1.id = "content1"
  content2 = m.generateNodeTree(2, 1)
  content2.id = "content2"
  content3 = m.generateNodeTree(2, 1)
  content3.id = "content3"

  m.cache.permanentContentIds["content2"] = true

  m.cache.setInContentCache(content1, m.testScreenId)
  m.cache.setInContentCache(content2, m.testScreenId)
  m.cache.setInContentCache(content3, m.testScreenId)

  ' test last added content is LRU
  lruCachedContent = m.cache.getLruContentFromCache()
  m.assertNotInvalid(lruCachedContent)
  m.assertTrue(lruCachedContent.isSameNode(content1))

  ' getting content from cache moves the content to the most recently used position in the cache
  ' as long as it is not "permanent" (content2 is "permanent")
  m.cache.getFromContentCache("content1")
  lruCachedContent = m.cache.getLruContentFromCache()
  m.assertTrue(lruCachedContent.isSameNode(content3))
End Function


'@Test markContentNotValidOnCachedScreens unit tests
Function tubiCache_markContentNotValidOnCachedScreens_test()
  content = m.generateNodeTree(2, 1)
  content.addField("validUntil", "integer", false)
  content.id = "screen_content"
  content.validUntil = 200

  baseScreen = CreateObject("roSGNode", "BaseScreen")
  baseScreen.addField("content", "node", false)
  baseScreen.id = m.constants.ui.screenIds.homeScreen
  baseScreen.content = content

  m.cache.setInScreenCache(baseScreen)

  isMarkedNotValid = m.cache.markContentNotValidOnCachedScreens("z_content")
  m.assertFalse(isMarkedNotValid)

  isMarkedNotValid = m.cache.markContentNotValidOnCachedScreens("screen_content")
  m.assertTrue(isMarkedNotValid)

  m.assertEqual(baseScreen.content.validUntil, 0)
End Function


'@Test isOnlyPermanentCacheRemaining unit tests
Function tubiCache_isOnlyPermanentCacheRemaining_test()
  ' test with no content in cache
  m.assertFalse(m.cache.isOnlyPermanentCacheRemaining())

  ' test with one cached content as "permanent"
  m.cache.permanentContentIds["content1"] = true

  content1 = m.generateNodeTree(2, 1)
  content1.id = "content1"
  content2 = m.generateNodeTree(2, 1)
  content2.id = "content2"
  content3 = m.generateNodeTree(2, 1)
  content3.id = "content3"

  m.cache.setInContentCache(content1, m.testScreenId)
  m.cache.setInContentCache(content2, m.testScreenId)
  m.cache.setInContentCache(content3, m.testScreenId)
  m.assertFalse(m.cache.isOnlyPermanentCacheRemaining())

  ' test with all cached content as "permanent"
  m.cache.permanentContentIds["content1"] = true
  m.cache.permanentContentIds["content2"] = true
  m.cache.permanentContentIds["content3"] = true

  content1 = m.generateNodeTree(2, 1)
  content1.id = "content1"
  content2 = m.generateNodeTree(2, 1)
  content2.id = "content2"
  content3 = m.generateNodeTree(2, 1)
  content3.id = "content3"

  m.cache.setInContentCache(content1, m.testScreenId)
  m.cache.setInContentCache(content2, m.testScreenId)
  m.cache.setInContentCache(content3, m.testScreenId)

  m.assertTrue(m.cache.isOnlyPermanentCacheRemaining())
  m.cache.emptyContentCache()
End Function


'@Test deleteScreenContentCache unit tests
Function tubiCache_deleteScreenContentCache_test()
  content1 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content1.id = "test_content1"

  content2 = m.generateNodeTree(2, 1) 'creates 2 nodes
  content2.id = "test_content2"

  m.cache.setInContentCache(content1, m.testScreenId)
  m.cache.setInContentCache(content2, m.testScreenId)
  m.assertTrue(m.cache.contentCache.count() = 2)

  m.cache.deleteScreenContentCache(m.testScreenId)
  m.assertTrue(m.cache.contentCache.count() = 0)
End Function
