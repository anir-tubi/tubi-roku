'See example metadata at "https://uapi.adrise.tv/cms/categories?app_id=tubitv&platform=roku&device_id=AABBCCDDEEFF&page_enabled=false"

''''''''''''''''''''''
' translateMetadata
'
' Translates content from server into format that roku understands
' contentToTranslate should be parsed from JSON before it hits this function
Function translateMetadata(contentToTranslate) As Object
  translated = CreateObject("roSGNode", "TubiContentNode")

  ' Cache a few values we don't want to look up from m.global each call to translateRecursive.
  ' Timings here were reduced from 33ms to 2ms per content item by not referencing m.global in
  ' the recursive function below.
  setTranslateGlobalsToLocal()

  node_count = 0

  if contentToTranslate <> invalid
    'expect a list of categories with one category filled with content or a list of contents
    if type(contentToTranslate) = "roArray"
      for each content in contentToTranslate
        node = translated.createChild("TubiContentNode")
        node_count = node_count + translateRecursive(content, node)
      end for

    'expect a single piece of content, or several (as an associative array)
    else if type(contentToTranslate) = "roAssociativeArray"

      'expect this to happen just for the search API
      if contentToTranslate.children <> invalid
        node_count = translateRecursive(contentToTranslate, translated)
      
      'expect this to happen for history/queue content
      else
        for each content in contentToTranslate
          if contentToTranslate[content] <> invalid
            node = translated.createChild("TubiContentNode")
            node_count = node_count + translateRecursive(contentToTranslate[content], node)
          end if
        end for
      end if
    end if
  end if

  setTotalCount(translated)
  tubiLog("TranslateMetadata converted " + stri(node_count) + " nodes")
  return translated
end Function


''''''''''''''''''''''
' translateDetailsMetadata
'
' Translates content from server into format that roku understands, specifically for details screen
' contentToTranslate should be parsed from JSON before it hits this function
Function translateDetailsMetadata(contentToTranslate) As Object
  translated = CreateObject("roSGNode", "TubiContentNode")
  setTranslateGlobalsToLocal()
  'will affect/update the translated node that is passed in
  translateRecursive(contentToTranslate, translated)

  setTotalCount(translated)
  return translated
End Function


''''''''''''''''''''''
' translateBookmarkMetadata
'
' Translates content from server into format that roku understands, specifically for bookmarks AND history
' We need to run the logic a little different to keep the order as specified in m.global.bookmarkOrder or m.global.historyOrder
' contentToTranslate should be parsed from JSON before it hits this function
Function translateBookmarkMetadata(contentToTranslate, orderType) As Object
  translated = CreateObject("roSGNode", "TubiContentNode")
  setTranslateGlobalsToLocal()
  
  nodeCount = 0

  idOrder = []
  if orderType = "bookmarks" and m.global.bookmarkOrder <> invalid
    idOrder.append(m.global.bookmarkOrder)

  else if orderType = "history" and m.global.historyOrder <> invalid
    idOrder.append(m.global.historyOrder)

  end if

  for each cid in idOrder
    content = contentToTranslate[cid]
    if content <> invalid
      node = translated.createChild("TubiContentNode")
      nodeCount = nodeCount + translateRecursive(content, node)
    end if
  end for

  setTotalCount(translated)
  return translated
End Function



'''''''''''''''''''''
' translateRecursive
'
' This is a recursive function that does the heavy lifting for translateContentFromServer
'this is a recursive function that does the heavy lifting for translateContentFromServer
Function translateRecursive(contentFromServer As Object, translatedContent As Object) As Integer
  if contentFromServer = invalid then return 0

  count = 1

  typeVar = "type"
  if contentFromServer[typeVar] <> invalid
    if contentFromServer[typeVar] = "c"
      translatedContent[typeVar] = m.contentTypes.category
    else if contentFromServer[typeVar] = "v"
      translatedContent[typeVar] = m.contentTypes.video
    else if contentFromServer[typeVar] = "s"
      translatedContent[typeVar] = m.contentTypes.series
    else if contentFromServer[typeVar] = "a"
      translatedContent[typeVar] = m.contentTypes.season
    end if
  end if

  'record keeping needed for adding series to bookmarks and previously viewed
  parent = translatedContent.getParent()
  if parent.parentId <> invalid and parent.parentId <> "" then
    translatedContent.parentId = parent.parentId
  else
    translatedContent.parentId = parent.id
  end if
  ' No parent if the parent.id is the task node
  if translatedContent.parentId = "MetadataFetchTask" then translatedContent.parentId = invalid

  if parent.parentType <> invalid and parent.parentType <> "" then
    translatedContent.parentType = parent.parentType
  else
    translatedContent.parentType = parent[typeVar]
  end if

  if parent.parentTitle <> invalid and parent.parentTitle <> "" then
    translatedContent.parentTitle = parent.parentTitle
  else
    translatedContent.parentTitle = parent.title
  end if

  if parent.parentHistoryId <> invalid and parent.parentHistoryId <> "" then
    translatedContent.parentHistoryId = parent.parentHistoryId
  else
    translatedContent.parentHistoryId = parent.historyId
  end if
  
  'translate all the stuff from the server
  if contentFromServer.id <> invalid then translatedContent.id = contentFromServer.id
  if contentFromServer.title <> invalid then translatedContent.title = contentFromServer.title
  if contentFromServer.duration <> invalid then translatedContent.length = contentFromServer.duration
  if contentFromServer.actors <> invalid then translatedContent.actors = contentFromServer.actors 'array of actors
  if contentFromServer.tags <> invalid then 
    translatedContent.genres = contentFromServer.tags 'array of genres
    translatedContent.categories = contentFromServer.tags 'array of genres
  end if
  
  if contentFromServer.slug <> invalid then translatedContent.slug = contentFromServer.slug
  if contentFromServer.lang <> invalid then translatedContent.language = contentFromServer.lang
  if contentFromServer.publisher_id <> invalid then translatedContent.pubId = contentFromServer.publisher_id
  if contentFromServer.country <> invalid then translatedContent.country = contentFromServer.country
  if contentFromServer.year <> invalid and contentFromServer.year <> 0 then translatedContent.releaseDate = contentFromServer.year.ToStr()
  if contentFromServer.currentEpisodeId <> invalid then translatedContent.currentEpisodeId = contentFromServer.currentEpisodeId
  if contentFromServer.nowPos <> invalid then translatedContent.nowPos = contentFromServer.nowPos
  if contentFromServer.series_id <> invalid then translatedContent.seriesId = contentFromServer.series_id
  
  if contentFromServer.description <> invalid
    translatedContent.description = contentFromServer.description
    translatedContent.longDescription = contentFromServer.description
  end if
  
  if contentFromServer.directors <> invalid and contentFromServer.directors.count() > 0
    translatedContent.directors = contentFromServer.directors
  end if

  if contentFromServer.credit_cuepoints <> invalid
    if contentFromServer.credit_cuepoints.prologue <> invalid
      translatedContent.introCuepoint = contentFromServer.credit_cuepoints.prologue
    end if
    if contentFromServer.credit_cuepoints.postlude <> invalid
      translatedContent.creditsCuepoint = contentFromServer.credit_cuepoints.postlude
    end if
  end if

  'add fake credit cuepoints for episodes - we can remove this once we get actual credits cue points for content
  if translatedContent.parentId <> invalid and translatedContent[typeVar] = m.contentTypes.video and translatedContent.length <> invalid
    translatedContent.creditsCuepoint = translatedContent.length - m.creditsDuration
  end if

  if contentFromServer.hero_images <> invalid and type(contentFromServer.hero_images) = "roArray" and contentFromServer.hero_images.count() > 0
    translatedContent.landscape = contentFromServer.hero_images[0]
  else if contentFromServer.thumbnails <> invalid and type(contentFromServer.thumbnails) = "roArray" and contentFromServer.thumbnails.count() > 0
    translatedContent.landscape = contentFromServer.thumbnails[0]
  end if

  if contentFromServer.posterarts <> invalid and type(contentFromServer.posterarts) = "roArray" and contentFromServer.posterarts.count() > 0
    translatedContent.portrait = contentFromServer.posterarts[0]
    translatedContent.HDGRIDPOSTERURL = contentFromServer.posterarts[0]
  end if

  if contentFromServer.backgrounds <> invalid and type(contentFromServer.backgrounds) = "roArray" and contentFromServer.backgrounds.count() > 0
    translatedContent.backgrounds = dedupeBackgrounds(contentFromServer.backgrounds)
  end if

  if contentFromServer.ratings <> invalid and contentFromServer.ratings[0] <> invalid and contentFromServer.ratings[0].value <> invalid
    translatedContent.rating = contentFromServer.ratings[0].value
  end if

  if contentFromServer.url <> invalid
    translatedContent.url = contentFromServer.url
    if contentFromServer.url.instr(1,".m3u8") > 0
      translatedContent.streamformat = "hls"
    else if contentFromServer.url.instr(1,".mp4") > 0
      translatedContent.streamformat = "mp4"
    end if
  end if

  'take care of any subtitles if they exist - should only happen on videos
  if contentFromServer.subtitles <> invalid and type(contentFromServer.subtitles) = "roArray" and contentFromServer.subtitles.count() > 0
    subtitleLanguages = []
    subtitleUrls = []

    for each subtitle in contentFromServer.subtitles
      subtitleLanguages.push(subtitle.lang)
      subtitleUrls.push(subtitle.url)
    end for

    translatedContent.subtitleLanguages = subtitleLanguages
    translatedContent.subtitleUrls = subtitleUrls
    
    'set the default subtitles if there is only one set of subtitles
    if contentFromServer.subtitles.count() = 1
      translatedContent.subtitleDefault = contentFromServer.subtitles[0].url
      translatedContent.subtitleUrl = contentFromServer.subtitles.[0].url
    end if
  end if

  'set the inital subtitle on/off state for the video
  if translatedContent.type = "video"
    if m.captionsMode = "On"
      translatedContent.showSubtitles = true
    else
      translatedContent.showSubtitles = false
    end if
  end if

  'add the bookmarkId if it exists
  if m.bookmarkIds <> invalid
    if translatedContent[typeVar] = m.contentTypes.series
      if m.bookmarkIds.series[translatedContent.id] <> invalid
        translatedContent.bookmarkId = m.bookmarkIds.series[translatedContent.id]
      end if

    else if translatedContent[typeVar] = m.contentTypes.video
      if m.bookmarkIds.videos[translatedContent.id] <> invalid
        translatedContent.bookmarkId = m.bookmarkIds.videos[translatedContent.id]
      end if
    end if
  end if


  'add the history info (historyId, currentEpisodeId, nowPos) if it exists
  if m.historyIds <> invalid
    if translatedContent[typeVar] = m.contentTypes.series
      if m.historyIds.series[translatedContent.id] <> invalid
        translatedContent.historyId = m.historyIds.series[translatedContent.id].serverId
        translatedContent.currentEpisodeId = m.historyIds.series[translatedContent.id].currentEpisodeId
      end if

    else if translatedContent[typeVar] = m.contentTypes.video
      if m.historyIds.videos[translatedContent.id] <> invalid
        translatedContent.historyId = m.historyIds.videos[translatedContent.id].serverId
        translatedContent.nowPos = m.historyIds.videos[translatedContent.id].position
      end if      

    end if
  end if



  'if this content is actually just a paginated response, set pagination data
  if contentFromServer.total_count <> invalid then translatedContent.totalCount = contentFromServer.total_count

  if contentFromServer.more <> invalid then translatedContent.more = contentFromServer.more

  'take care of any children the content might have
  if contentFromServer.children <> invalid and contentFromServer.children.count() > 0

    if translatedContent.totalCount = 0
      translatedContent.totalCount = contentFromServer.children.count()
    end if

    for each childContent in contentFromServer.children
      node = translatedContent.createChild("TubiContentNode")
      count = count + translateRecursive(childContent, node)
    end for

  end if

  ' return the total number of children converted
  return count  
end Function


Function setTranslateGlobalsToLocal()
  if m.global.bookmarkIds <> invalid then
    m.bookmarkIds = {
      series: {}
      videos: {}
    }
    m.bookmarkIds.series.append(m.global.bookmarkIds.series)
    m.bookmarkIds.videos.append(m.global.bookmarkIds.videos)
  end if
  if m.global.historyIds <> invalid then
    m.historyIds = {
      series: {}
      videos: {}
    }
    m.historyIds.series.append(m.global.historyIds.series)
    m.historyIds.videos.append(m.global.historyIds.videos)
  end if
  m.captionMode = m.global.constants.deviceInfo.captionsMode
  m.contentTypes = {}
  m.contentTypes.append(m.global.constants.ui.contentTypes)
  m.creditsDuration = m.global.constants.player.creditsDuration
end Function


Function dedupeBackgrounds(backgroundsFromServer) as Object
  deduped = {}

  for each background in backgroundsFromServer
    deduped[background] = true
  end for

  return deduped.keys()

End Function

Function setTotalCount(metadata As Object)
  if metadata.totalCount = 0 and metadata.getChildCount() <> 0 then
    metadata.totalCount = metadata.getChildCount()
  end if
End Function