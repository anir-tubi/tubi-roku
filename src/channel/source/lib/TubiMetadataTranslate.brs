Function TubiMetadataTranslate(constants As Object)
  return {
    ' public
    translateRecursive: tubiMetadataTranslate_translateRecursive
    getContentFromCategoryJson: tubiMetadataTranslate_getContentFromCategoryJson
    translateRelatedContent: tubiMetadataTranslate_translateRelatedContent
    
    ' private
    constants: constants
    contentTypes: constants.ui.contentTypes
    captionsMode: constants.deviceInfo.captionsMode
    creditsDuration: constants.player.creditsDuration
    allowAfterHours: constants.settings.allowAfterHours
    
    dedupeBackgrounds: tubiMetadataTranslate_dedupeBackgrounds
    setTotalCount: tubiMetadataTranslate_setTotalCount
  }
End Function

Function tubiMetadataTranslate_dedupeBackgrounds(backgroundsFromServer) as Object
  deduped = {}

  for each background in backgroundsFromServer
    deduped[background] = true
  end for

  return deduped.keys()
End Function

Function tubiMetadataTranslate_setTotalCount(metadata As Object)
  if metadata.totalCount = -1 and metadata.getChildCount() <> 0 then
    metadata.totalCount = metadata.getChildCount()
  end if
End Function


'''''''''''''''''''''
' translateRecursive
'
' This is a recursive function that does the heavy lifting for translateContentFromServer
'this is a recursive function that does the heavy lifting for translateContentFromServer
Function tubiMetadataTranslate_translateRecursive(contentFromServer As Object, translatedContent As Object) As Integer
  if contentFromServer = invalid then return 0

  count = 1

  if contentFromServer.id <> invalid then translatedContent.id = contentFromServer.id

  typeVar = "type"
  if contentFromServer[typeVar] <> invalid
    if contentFromServer[typeVar] = "c"
      translatedContent[typeVar] = m.contentTypes.category
    else if contentFromServer[typeVar] = "v" or contentFromServer[typeVar] = "clip"
      translatedContent[typeVar] = m.contentTypes.video
    else if contentFromServer[typeVar] = "s"
      translatedContent[typeVar] = m.contentTypes.series
      ' prefix "0" to series
      if translatedContent.id <> "" then translatedContent.id = "0" + translatedContent.id
    else if contentFromServer[typeVar] = "a"
      translatedContent[typeVar] = m.contentTypes.season
      ' prefix "0" to series
      if translatedContent.id <> "" then translatedContent.id = "0" + translatedContent.id
    end if
  end if

  'record keeping needed for adding series to bookmarks and previously viewed

  ' NOTE: getParent() can return invalid due to Rendezvous error.  If it's the root TubiContentNode
  '       it will by default have a parent of this Task node.  Apparently there is a rendezvous copy
  '       of the parent task node made when getParent() is called, and that can end up being invalid
  '       if the primary thread is stuck.
  '
  parent = translatedContent.getParent()
  parentWhiteList = {}
  parentWhiteList[m.constants.ui.contentTypes.series] = true
  parentWhiteList[m.constants.ui.contentTypes.season] = true

  if parent <> invalid and parent.type <> invalid and parentWhiteList.DoesExist(parent.type) then
    if parent.parentId <> invalid and parent.parentId <> "" then
      translatedContent.parentId = parent.parentId
    else
      translatedContent.parentId = parent.id
    end if
    
    'this happens on deep link with mediaType = episode
    if contentFromServer.series_id <> invalid
      translatedContent.parentId = "0" + contentFromServer.series_id
    end if

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
    else if parent.historyId <> invalid and parent.historyId <> ""
      translatedContent.parentHistoryId = parent.historyId
    end if

  else if contentFromServer.series_id <> invalid
    translatedContent.parentId = "0" + contentFromServer.series_id

  else
    translatedContent.parentId = invalid
  end if
  
  'translate all the stuff from the server
  if contentFromServer.title <> invalid then translatedContent.title = contentFromServer.title
  if contentFromServer.duration <> invalid then translatedContent.length = contentFromServer.duration
  if contentFromServer.actors <> invalid then translatedContent.actors = contentFromServer.actors 'array of actors
  if contentFromServer.roku_genres <> invalid then translatedContent.rokuGenres = contentFromServer.roku_genres 'array of roku genres
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
  if contentFromServer.series_id <> invalid then translatedContent.seriesId = "0" + contentFromServer.series_id
  if contentFromServer.isLiveTV <> invalid then translatedContent.isLiveTV = contentFromServer.isLiveTV
  if contentFromServer.liveTvChannelType <> invalid then translatedContent.liveTvChannelType = contentFromServer.liveTvChannelType
  
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

  'add default credit cuepoints if missing, or skip it if content is very short
  if translatedContent.creditsCuepoint = 0 and translatedContent.length > m.creditsDuration
    cuepoint = translatedContent.length - m.creditsDuration
    if cuepoint >= 0
      translatedContent.creditsCuepoint = cuepoint
    end if
  end if

  ' if credits duration is less than m.creditsDuration, force it to be at least that long
  if translatedContent.creditsCuepoint > 0 and (translatedContent.length - translatedContent.creditsCuePoint) < m.creditsDuration
    cuepoint = translatedContent.length - m.creditsDuration
    if cuePoint >= 0
      translatedContent.creditsCuepoint = cuepoint
    else
      ' if the cuepoint was adjusted, but it ended up being negative
      translatedContent.creditsCuepoint = 0
    end if
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
    translatedContent.backgrounds = m.dedupeBackgrounds(contentFromServer.backgrounds)
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
  if contentFromServer.has_subtitle <> invalid then translatedContent.hasSubtitles = contentFromServer.has_subtitle
  if contentFromServer.subtitles <> invalid and type(contentFromServer.subtitles) = "roArray" and contentFromServer.subtitles.count() > 0
    subtitleTracks = []
    for each subtitle in contentFromServer.subtitles
      ' Firmware 8.0+ scene graph native CC dialog
      subtitleTracks.push({
        description: subtitle.lang
        trackname: subtitle.url
      })
    end for
    translatedContent.subtitleTracks = subtitleTracks
    ' This is needed to make subtitles work on Roku 3 (and other models... 3900, 3800, etc.)
    translatedContent.subtitleConfig = {trackname: contentFromServer.subtitles[0].url}
  end if

  'set the inital subtitle on/off state for the video
  if translatedContent["type"] = "video"
    if m.captionsMode = "On"
      translatedContent.showSubtitles = true
    else
      translatedContent.showSubtitles = false
    end if
  end if

  ' trailers
  if contentFromServer.trailers <> invalid and type(contentFromServer.trailers) = "roArray" and contentFromServer.trailers.count() > 0
    trailer = contentFromServer.trailers[0]
    if trailer.url <> invalid and (type(trailer.url) = "roString" or type(trailer.url) = "String") then translatedContent.trailerUrls = [trailer.url]
  end if
  if contentFromServer.has_trailer = true then translatedContent.hasTrailer = true

  'if this content is actually just a paginated response, set pagination data
  if contentFromServer.total_count <> invalid then translatedContent.totalCount = contentFromServer.total_count

  if contentFromServer.more <> invalid then translatedContent.more = contentFromServer.more

  'take care of any children the content might have
  if contentFromServer.children <> invalid and contentFromServer.children.count() > 0

    if translatedContent.totalCount = -1
      translatedContent.totalCount = contentFromServer.children.count()
    end if

    for each childContent in contentFromServer.children
      node = translatedContent.createChild("TubiContentNode")
      count = count + m.translateRecursive(childContent, node)
    end for

  end if

  ' return the total number of children converted
  return count  
end Function


' returns the full metadata of a single piece of content as stored within the category json returned from UAPI cms/categories endpoint
' may return limited metadata for the single piece of content if json does not exist or cannot be parsed
'
' @category: a category tubiContentNode with full category content stored in json format on the .json field
' @index: the index at which the desired content resides within the category
Function tubiMetadataTranslate_getContentFromCategoryJson(category, index)
  if category <> invalid and category.json <> invalid and category.json <> "" then
    parsed = ParseJson(category.json)
    if parsed <> invalid then
      fullContent = parsed.children[index]
      translated = CreateObject("roSGNode", "TubiContentNode")
      m.translateRecursive(fullContent, translated)
      return translated
    end if
  end if
  ' just return the abbreviated content.  This happens for user categories every time
  return category.getChild(index)
End Function



' Expect content from the /related API, structured as an array of assocarrays
Function tubiMetadataTranslate_translateRelatedContent(contentFromServer)
  translated = CreateObject("roSGNode", "TubiContentNode")
  if type(contentFromServer) = "roArray"
    for each content in contentFromServer
      node = translated.createChild("TubiContentNode")
      m.translateRecursive(content, node)
    end for
  end if
  return translated
End Function
