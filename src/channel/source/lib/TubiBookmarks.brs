' Creates queue/bookmark/my list and history/continue watching functionality for use in general task parsers
Function TubiBookmarks(constants)
  return {
    constants: constants

    'public methods
    translateQueueIds: tubiBookmarks_translateQueueIds
    translateHistoryIds: tubiBookmarks_translateHistoryIds
    addHistoryLocally: tubiBookmarks_addHistoryLocally
    updateLikesLocally: tubiBookmarks_updateLikesLocally
  }
End Function



'saves the resume point locally and does not communicate to the backend.
' @content: can be a content node from scene graph or a content object from the main thread - expect either a video/movie or episode, no series
' @position: position where user left off of video
' @global: The global object to be used to save the data
Function tubiBookmarks_addHistoryLocally(content as Object, position as Integer, global = invalid)
  if content <> invalid AND global <> invalid AND global.historyIds <> invalid

    nowDate = CreateObject("roDateTime")
    nLastSaved = nowDate.AsSeconds()
    if content.parentType = m.constants.uapiContentTypes.series
      '//if this TV content
      if content.parentId <> invalid

        historyNode = getHistory(content.parentId) 'bs:disable-line 1140 LINT1001

        if historyNode = invalid
          historyNode = global.historyIds.createChild("HistoryContentNode")
        end if
        historyNode.id = content.parentId
        historyNode.type = m.constants.uapiContentTypes.series
        historyNode.currentEpisodeId = content.id
        historyNode.lastSaved = nLastSaved

        childNode = historyNode.findNode(content.id)
        if childNode = invalid
          childNode = historyNode.createChild("HistoryContentNode")
        end if

        childNode.id = content.id
        childNode.lastSaved = nLastSaved
        childNode.nowPos = position
        childNode.type = content.type

        if isNonEmptyString(content.historyId) = true
          childNode.historyId = content.historyId
        end if
      end if
    else
      '//else if this movie content

      historyNode = getHistory(content.id) 'bs:disable-line 1140 LINT1001
      if historyNode = invalid
        historyNode = global.historyIds.createChild("HistoryContentNode")
      end if

      historyNode.id = content.id
      historyNode.lastSaved = nLastSaved
      historyNode.nowPos = position
      historyNode.type = content.type

      if isNonEmptyString(content.historyId) = true
        historyNode.historyId = content.historyId
      end if
    end if
  end if
End Function


' @param contentId, String: the ID of the title to change it's liking
' @param sRatingAction, String: The Action enum to alter the like state of the provided content ID. The possible values are all under m.constants.ui.likeDislikeActions
Function tubiBookmarks_updateLikesLocally(contentId as String, sRatingAction as String, global = invalid)
  if contentId <> invalid AND global <> invalid AND global.likeIds <> invalid
    likeNode = getLike(contentId) 'bs:disable-line 1140 LINT1001

    sState = ""
    if sRatingAction = m.constants.ui.likeDislikeActions.like
      sState = m.constants.ui.likeDislikeStates.liked
    else if sRatingAction = m.constants.ui.likeDislikeActions.dislike
      sState = m.constants.ui.likeDislikeStates.disliked
    end if

    if sState = ""
        '//remove the like
        if likeNode <> invalid
          global.likeIds.removeChild(likeNode)
        end if
    else
      '//update or add the like
      if likeNode = invalid
        likeNode = global.likeIds.createChild("LikeContentNode")
        likeNode.id = contentId
      end if
      likeNode.state = sState
    end if
  end if
End Function


' TODO move into parseGetQueueIdsSuccess parser directly
'@initialBookmarks: array, brightscript representation of backend's JSON response upon fetching a user's bookmarks/queue/MyList
'@returns: roSGNode, parent node with each child representing a content in the user's queue.
'                    Children nodes are ordered in the same order as returned by the backend.
Function tubiBookmarks_translateQueueIds(initialBookmarks)
  bookmarkIds = CreateObject("roSGNode", "BookmarkContentNode")

  if initialBookmarks <> invalid
    for each bookmark in initialBookmarks.queues
      if bookmark.content_id <> invalid
        child = bookmarkIds.createChild("BookmarkContentNode")
        childId = bookmark.content_id.toStr()
        child.bookmarkId = bookmark.id

        if bookmark.content_type = m.constants.uapiContentTypes.movie
          child.id = childId
          child.type = m.constants.ui.contentTypes.video
        else if bookmark.content_type = m.constants.uapiContentTypes.series
          child.id = "0" + childId
          child.type = m.constants.ui.contentTypes.series
        else if bookmark.content_type = m.constants.uapiContentTypes.sportsEvent
          child.id = childId
          child.type = m.constants.ui.contentTypes.sportsEvent
        end if
      end if
    end for
  end if

  return bookmarkIds
End Function


' TODO move into parseGetHistoryIdsSuccess parser directly
'@initialBookmarks: array, brightscript representation of backend's JSON response upon fetching a user's history/continue watching
'@returns: roSGNode, parent node with each child representing a content in the user's history.
'                    Series nodes have children representing episodes.
'                    Children nodes are ordered in the same order as returned by the backend.
Function tubiBookmarks_translateHistoryIds(initialHistory)
  historyIds = CreateObject("roSGNode", "HistoryContentNode")

  if initialHistory <> invalid then
    for each history in initialHistory.items
      if history.content_id <> invalid
        child = historyIds.createChild("HistoryContentNode")
        childId = history.content_id.toStr()
        if history.content_type = m.constants.uapiContentTypes.movie OR history.content_type = m.constants.uapiContentTypes.sportsEvent
          child.id = childId
          child.historyId = history.id
          child.nowPos = history.position
          child.type = m.constants.ui.contentTypes.video
        else if history.content_type = m.constants.uapiContentTypes.series
          child.id = "0" + childId
          child.historyId = history.id
          child.type = m.constants.ui.contentTypes.series

          if history.episodes <> invalid AND history.position <> invalid AND history.episodes[history.position] <> invalid
            currentEpisode = history.episodes[history.position]
            if currentEpisode.content_id <> invalid
              child.currentEpisodeId = currentEpisode.content_id.toStr()
            end if
          end if

          for each episode in history.episodes
            if episode.content_id <> invalid
              grandchild = child.createChild("HistoryContentNode")
              grandchild.id = episode.content_id.toStr()
              grandchild.historyId = episode.id
              grandchild.nowPos = episode.position
              grandchild.type = m.constants.ui.contentTypes.video
            end if
          end for
        end if
      end if
    end for
  end if

  return historyIds
End Function
