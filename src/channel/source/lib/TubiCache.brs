' The module returned by TubiCache() provides functionality and data stores for caching both
' screens and individual content node trees. Screens and contents being stored must have a unique
' (within the entire app) id. Setting a screen or content in the cache with an id that already exists
' in the cache will overwrite the initially cached content with that id.

' @nodeHelpers: assocArray, an instance of the TubiNodeHelpers library
' @cacheableScreenIds: assocArray, keys are screen ids of screens that can be put into the screen cache
' @permanentContentIds: assocArray, keys are ids of content nodes that cannot be removed from the
'                                   content cache due to being the least recently used content
'                                   (an example might be the id for the homescreen content)
Function TubiCache(nodeHelpers, cacheableScreenIds, permanentContentIds)
  return {
    ' public methods
    setInScreenCache: tubiCache_setInScreenCache
    getFromScreenCache: tubiCache_getFromScreenCache
    deleteFromScreenCache: tubiCache_deleteFromScreenCache
    emptyScreenCache: tubiCache_emptyScreenCache

    setInContentCache: tubiCache_setInContentCache
    getFromContentCache: tubiCache_getFromContentCache
    deleteFromContentCache: tubiCache_deleteFromContentCache
    emptyContentCache: tubiCache_emptyContentCache

    ' private methods
    getCachedNodeCount: tubiCache_getCachedNodeCount
    getLruContentFromCache: tubiCache_getLruContentFromCache
    isOnlyPermanentCacheRemaining: tubiCache_isOnlyPermanentCacheRemaining
    addToContentCacheOrder: tubiCache_addToContentCacheOrder
    deleteContentFromCache: tubiCache_deleteContentFromCache
    deleteFromContentCacheOrder: tubiCache_deleteFromContentCacheOrder
    markContentNotValidOnCachedScreens: tubiCache_markContentNotValidOnCachedScreens

    ' private properties
    screenCache: {}
    contentCache: {}
    contentCacheOrder: [] 'each array item is an AA with keys: "id", "totalContentNodeCount", and "isPermanent"
    cacheableScreenIds: cacheableScreenIds
    permanentContentIds: permanentContentIds
    nodeHelpers: nodeHelpers
    maxContentNodes: 30000 'tested over 31,000 nodes on 3700X with no issue
  }
End Function


' a setter for the screen cache - can overwrite screens in the cache if the passed in screen has
' the same id as a screen already existing in the screen cache
'
' @screen: roSGNode, a screen node
'
' returns: boolean, true or false depending if the screen was successfully set
Function tubiCache_setInScreenCache(screen)
  if screen <> invalid and screen.id <> invalid and m.cacheableScreenIds[screen.id] = true
    m.screenCache[screen.id] = screen
    return true
  end if
  return false
End Function


' a getter for the screen cache - getting does not remove the screen from the cache
'
' @screenId: string, the id of the screen that is to be retrieved
'
' returns: roSGNode/invalid, the screen node or invalid if no screens were found with the passed in id
Function tubiCache_getFromScreenCache(screenId)
  if type(screenId) = "String" or type(screenId) = "roString"
    return m.screenCache[screenId] 
  end if
  return invalid
End Function


' a deleter for the screen cache - we may need to remove screens from the cache in the case of content loading errors
'
' @screenId: string, the id of the screen that is to be removed
'
' returns: boolean, true if the screen was successfully deleted, otherwise returns false
Function tubiCache_deleteFromScreenCache(screenId)
  if type(screenId) = "String" or type(screenId) = "roString"
    screen = m.getFromScreenCache(screenId)

    if screen <> invalid
      m.nodeHelpers.unobserveAllScoped(screen)
    end if

    return m.screenCache.delete(screenId)
  end if

  return false
End Function


' removes all screens from the screen cache (and unobserves them for good measure)
'
' returns: assocArray, the empty screen cache
Function tubiCache_emptyScreenCache()
  for each screenId in m.screenCache
    screen = m.getFromScreenCache(screenId)
    m.nodeHelpers.unobserveAllScoped(screen)
  end for

  m.screenCache = {}
  return m.screenCache
End Function


' a setter for the content cache - can overwrite top level contents in the cache if the passed 
' in content has the same id as a content already existing in the content cache.
'
' @content: roSGNode, a ContentNode or a node that extends ContentNode
'           It is possible for the content to be a parent with many children
'           (ex. the content for the homescreen). This may create a situation where a ContentNode with
'           the same id may exists multiple times as children of different parent content nodes.
'           This is ok and expected.
' returns: boolean, true or false depending if the content was successfully set
Function tubiCache_setInContentCache(content)
  if type(content) = "roSGNode" and content.isSubtype("ContentNode") = true and content.id <> invalid

    ' determine how many content nodes in incoming content
    incomingNodeCount = m.nodeHelpers.countNodes(content)

    ' don't attempt to add the content to the cache if it contains more nodes than are allowed in the cache
    if incomingNodeCount <= m.maxContentNodes

      ' determine how many content nodes exist in cache already
      cachedNodeCount = m.getCachedNodeCount()

      ' remove any least recently used (LRU) content from the cache if the cache is too full
      ' to add the new content we want to set in the cache
      while (cachedNodeCount + incomingNodeCount > m.maxContentNodes) and m.isOnlyPermanentCacheRemaining() = false
        leastRecentlyUsedContent = m.getLruContentFromCache()

        if leastRecentlyUsedContent <> invalid
          leastRecentlyUsedNodeCount = m.nodeHelpers.countNodes(leastRecentlyUsedContent)

          ' remove the content from any cached screens, the content cache, and the cache order data
          m.deleteFromContentCache(leastRecentlyUsedContent.id)

          ' calculate the number of nodes in the cache after we've removed the least recently used node.
          ' a simple subtraction is faster than re-counting all the nodes by iterating the node trees.
          cachedNodeCount -= leastRecentlyUsedNodeCount
        end if
      end while

      ' It may be the case that the while loop exited because there are only "permanent" content nodes
      ' left in the cache that should not be removed (ex. homescreen content nodes), but 
      ' adding the incoming content nodes would still take us over the max content nodes.
      ' Only cache if there is still room.
      if cachedNodeCount + incomingNodeCount <= m.maxContentNodes
        m.contentCache[content.id] = content
        m.addToContentCacheOrder(content)
        return true
      end if
    end if
  end if

  return false
End Function


' a getter for the content cache - getting does not remove the content from the cache
'
' @contentId: string, the id of the content that is to be retrieved
' 
' returns: roSGNode/invalid, the content node or invalid if no content was found with the passed in id
'                            or the content node is found to no longer be valid based on the validUntil field.
' 
' side effects: 1) If a content is found in the cache with the passed in contentId, the content
'               is moved in the cachedOrder, since has been recently accessed.
'               2) If a content is found in the cache and has a validUntil field with a value that
'               is no longer valid, the content is removed from the cache. Content without a validUntil
'               field is not removed from the cache.
Function tubiCache_getFromContentCache(contentId)
  if type(contentId) = "String" or type(contentId) = "roString"
    cachedContent = m.contentCache[contentId]

    if cachedContent <> invalid
      if cachedContent.validUntil <> invalid and cachedContent.validUntil < UpTime(0)
        cachedContent = invalid
        m.deleteFromContentCache(contentId)
        m.deleteFromContentCacheOrder(contentId)
      else
        ' move the cached content to most recently used status
        m.addToContentCacheOrder(cachedContent)
      end if
    end if

    return cachedContent
  end if

  return invalid
End Function


' a helper function to do all the actions necessary to remove content from all cached locations
' @content: string, the id of the content node to be removed from the content cache
Function tubiCache_deleteFromContentCache(contentId)
  m.markContentNotValidOnCachedScreens(contentId)
  m.deleteContentFromCache(contentId)
  m.deleteFromContentCacheOrder(contentId)
End Function


' iterates over each screen in the screen cache and if the content of the screen has the same
' id as the passed in content, sets the validUntil field of the content on the screen to 0
' 
' @contentId: string, the id of the content to which the validUntil field will be updated
'
' returns: boolean, true if a content node with the passed in contentID was found on any screen in
' the screen cache and false if no cached screens contained content with the passed in content id.
Function tubiCache_markContentNotValidOnCachedScreens(contentId)
  isContentFound = false

  if type(contentId) = "String" or type(contentId) = "roString"
    for each screenId in m.screenCache
      screen = m.screenCache[screenId]

      if screen.content <> invalid and screen.content.id = contentId
        isContentFound = true
        screen.content.validUntil = 0
      end if
    end for
  end if

  return isContentFound
End Function


' a deleter for the content cache
'
' @contentId: string, the id of the content that is to be deleted from the contentCache AA
'
' returns: boolean, true if the content was successfully deleted, otherwise returns false
Function tubiCache_deleteContentFromCache(contentId)
  if type(contentId) = "String" or type(contentId) = "roString"
    return m.contentCache.delete(contentId)
  end if

  return false
End Function


' Deletes the content cache order information from the content cache order store based
' on the passed in content id.
' 
' @contentId: string, the id of the content that is to be deleted from the contentCacheOrder array
' 
' returns: boolean, true if the cacheOrderInfo was successfully deleted from the contentCacheOrder
'                   or false if not successfully deleted
Function tubiCache_deleteFromContentCacheOrder(contentId)
  if type(contentId) = "String" or type(contentId) = "roString"
    for i = 0 to m.contentCacheOrder.count() - 1
      cacheOrderInfo = m.contentCacheOrder[i]

      if cacheOrderInfo.id = contentId
        return m.contentCacheOrder.delete(i)
      end if
    end for
  end if

  return false
End Function


' removes all content from the content cache INCLUDING any "permanent" contents
Function tubiCache_emptyContentCache()
  m.contentCacheOrder = []
  m.contentCache = {}
End Function


' returns: integer, the number of content nodes that are currently in the cache
Function tubiCache_getCachedNodeCount()
  cachedNodesCount = 0

  for each id in m.contentCache
    cachedNode = m.contentCache[id]
    cachedNodesCount += m.nodeHelpers.countNodes(cachedNode)
  end for

  return cachedNodesCount
End Function


' returns: roSGNode/invalid, the least recently used content node from the cache that is not
'                            a "permanent" node (ex. home screen content) or invalid if there
'                            are only "permanent" contents in the cache.
'
' Note: This function does not remove content from the cache.
Function tubiCache_getLruContentFromCache()
  lruContent = invalid
  for i = 0 to m.contentCacheOrder.count()
    cacheOrderInfo = m.contentCacheOrder[i]
    if cacheOrderInfo.isPermanent <> true
      if cacheOrderInfo.id <> invalid
        lruContent = m.contentCache[cacheOrderInfo.id]
        exit for
      end if
    end if
  end for

  return lruContent
End Function


' returns: boolean, true if there are only items in the content cache that are considered "permanent".
'                   false if there is at least one item in the content cache that is not permanent.
Function tubiCache_isOnlyPermanentCacheRemaining()
  if m.contentCacheOrder.count() > 0
    for each cacheOrderInfo in m.contentCacheOrder
      if cacheOrderInfo <> invalid and cacheOrderInfo.isPermanent = false
        return false
      end if
    end for

    return true
  else
    return false
  end if
End Function


' least recently used content is at the "bottom" of the content cache order (0 index)
' most recently used content is at the "top" of the content cache order (high index)
'
' @content: roSGNode, a ContentNode or node of type that extends ContentNode (like TubiContentNode)
'
' returns: boolean, true if content was successfully added to the contentCacheOrder, otherwise false
Function tubiCache_addToContentCacheOrder(content)
  if type(content) = "roSGNode" and content.id <> ""
    cacheOrderInfo = {
      id: content.id
      totalContentNodeCount: m.nodeHelpers.countNodes(content)
      isPermanent: false
    }

    if m.permanentContentIds[content.id] <> invalid
      cacheOrderInfo.isPermanent = true
    end if

    ' in case the content had previously existed in the cache, and we are overwriting it in
    ' the cache, make sure to delete the previous instance from the order so we can add it back to
    ' the top of the stack
    m.deleteFromContentCacheOrder(content.id)
    m.contentCacheOrder.push(cacheOrderInfo)
    return true
  end if

  return false
End Function

