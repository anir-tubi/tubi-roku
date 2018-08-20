Function TubiMetadataTranslate(constants As Object)
  return {
    ' public
    translateRecursive: tubiMetadataTranslate_translateRecursive
    getContentFromCategoryJson: tubiMetadataTranslate_getContentFromCategoryJson
    translateRelatedContent: tubiMetadataTranslate_translateRelatedContent
    translate: tubiMetadataTranslate_translate
    translateContainer: tubiMetadataTranslate_translateContainer
    translateChannel: tubiMetadataTranslate_translateChannel
    translateHomescreen: tubiMetadataTranslate_translateHomescreen
    
    ' private
    constants: constants
    contentTypes: constants.ui.contentTypes
    captionsMode: constants.deviceInfo.captionsMode
    creditsDuration: constants.player.creditsDuration
    allowAfterHours: constants.settings.allowAfterHours
    
    dedupeBackgrounds_: tubiMetadataTranslate_dedupeBackgrounds
    setTotalCount_: tubiMetadataTranslate_setTotalCount
    getContentsJson_: tubiMetadataTranslate_getContentsJson
    buildCategoryAA_: tubiMetadataTranslate_buildCategoryAA
    generateChannelPosterUrl: tubiMetadataTranslate_generateChannelPosterUrl
    fetchedAtTimestamp_: tubiMetadataTranslate_fetchedAtTimestamp
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
Function tubiMetadataTranslate_translateRecursive(contentFromServer As Object, translatedContent As Object, fetchedAt=invalid) As Integer
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
    else if contentFromServer[typeVar] = "channel"
      translatedContent[typeVar] = m.contentTypes.channel
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
    translatedContent.backgrounds = m.dedupeBackgrounds_(contentFromServer.backgrounds)
  end if

  if contentFromServer.ratings <> invalid and contentFromServer.ratings[0] <> invalid and contentFromServer.ratings[0].value <> invalid
    translatedContent.rating = contentFromServer.ratings[0].value
  end if

  if contentFromServer.url <> invalid
    if Lcase(contentFromServer.url).instr(1,".m3u8") > 0
      translatedContent.url = contentFromServer.url
      translatedContent.streamformat = "hls"
    else if Lcase(contentFromServer.url).instr(1,".mp4") > 0
      translatedContent.url = contentFromServer.url
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

  ' Channels
  if contentFromServer.channel_id <> invalid then translatedContent.channelId = contentFromServer.channel_id
  if contentFromServer.channel_logo <> invalid then translatedContent.inlineLogoUri = contentFromServer.channel_logo
  if contentFromServer.logo <> invalid then translatedContent.titleLogoUri = contentFromServer.logo
  if contentFromServer.channel_title <> invalid then translatedContent.channelTitle = contentFromServer.channel_title

  ' Allow this to be passed in, so for cases where we lazily translate it can contain
  ' the right time
  if fetchedAt <> invalid then
    translatedContent.fetchedAt = fetchedAt
  else
    translatedContent.fetchedAt = m.fetchedAtTimestamp_()
  end if

  'take care of any children the content might have
  if contentFromServer.children <> invalid and contentFromServer.children.count() > 0

    if translatedContent.totalCount = -1
      translatedContent.totalCount = contentFromServer.children.count()
    end if

    for each childContent in contentFromServer.children
      node = translatedContent.createChild("TubiContentNode")
      ' pass the resolved fetchedAt time so that it doesn't have to be generated again for every child
      count = count + m.translateRecursive(childContent, node, translatedContent.fetchedAt)
    end for

  end if

  ' return the total number of children converted
  return count  
end Function


''''''''''''''
' getContentFromCategoryJson
'
' returns the full metadata of a single piece of content as stored within the json for all contents as returned from matrix APIs.
' may invalid if json does not exist or cannot be parsed
'
' @category: a category tubiContentNode with full category content stored in json format on the .json field
' @contentId: string, an id for a piece of content (movie or series)
Function tubiMetadataTranslate_getContentFromCategoryJson(category, contentId)
  if category <> invalid and category.json <> invalid and category.json <> ""
    parsed = ParseJson(category.json)
    if parsed <> invalid
      fullContent = parsed[contentId]
      translated = CreateObject("roSGNode", "TubiContentNode")
      m.translateRecursive(fullContent, translated, category.fetchedAt)
      return translated
    end if
  end if
  return invalid
End Function



''''''''''''''''''''''
' translateRelatedContent
'
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


''''''''''''''''''''''
' translateHomescreen
' Translate the initial homescreen call to matrix api
'
' @contentToTranslate: roAssocArray, should have a form like:
'                     {
'                        containers: [
'                           {
'                             id: "featured"
'                             children: ["37108", "337825", "304771"]
'                             ...
'                           }
'                           {
'                             id: "most_popular"
'                             children: ["346629", "407698", "300175"]
'                             ...
'                           }
'                        ],
'                        contents: {
'                           "37108": {
'                               id: "37108"
'                               title: ...
'                           },
'                           "337825": {
'                               id: "337825"
'                               title: ...
'                           },
'                           ...
'                        }
'                     }
'
' Returns a set of content meta data in the form below.
' The ContentNodes will have a limited set of meta data, just enough to propagate the category grid.
' The outer most CategoryContentNode's json field will be filled with the contents json
' <CategoryContentNode json={...all contents info...}>
'   <CategoryContentNode id="featured">
'     <ContentNode id="37108" />
'     <ContentNode id="337825" />
'      ...
'   </CategoryContentNode>
'   <CategoryContentNode id="most_popular" />
'     <ContentNode id="346629" />
'     <ContentNode id="407698" />
'      ...
'   </CategoryContentNode>
' </CategoryContentNode>
'
Function tubiMetadataTranslate_translateHomescreen(contentToTranslate) As Object
  translated = CreateObject("roSGNode", "CategoryContentNode")
  fetchedAt = m.fetchedAtTimestamp_()
  homescreenAA = {
    id: ""
    title: ""
    fetchedAt: fetchedAt
    children: []    'categories
  }

  containers = contentToTranslate.containers
  contents = contentToTranslate.contents

  'set up AAs for all categories including any nested categories
  for i=0 to containers.count()-1
    container = containers[i]
    if container.type <> "complex"
      categoryAA = m.buildCategoryAA_(container, contents, invalid, fetchedAt)
      if categoryAA <> invalid
        homescreenAA.children.push(categoryAA)
      end if
    else
      for j=0 to container.children.count()-1
        nestedContainer = container.children[j]
        categoryAA = m.buildCategoryAA_(nestedContainer, contents, invalid, fetchedAt)
        if categoryAA <> invalid
          categoryAA.parentId = container.id
          homescreenAA.children.push(categoryAA)
        end if
      end for
    end if
  end for

  translated.update(homescreenAA)
  node_count = 1 + translated.getChildCount()
  tubiLog("TranslateMetadata converted " + stri(node_count) + " nodes")
  return translated
End Function


''''''''''''''''''''
' translateContainer
'
' Translate content specifically targeted at CategoryGridList.  This is aimed at PERFORMANCE
' above ease of use so it only translates the minimal necessary fields.  The performance
' tricks used here, found through measurement are:
' 1) Use ContentNode instead of TubiContentNode
' 2) Use ifSGNodeChildren.update() to leverage native code for node creation and setting fields
' 3) Avoid custom fields in favor of ContentNode's defined fields, this avoiding addField() calls in a loop
Function tubiMetadataTranslate_translateContainer(contentToTranslate, fullJson) As Object
  translated = CreateObject("roSGNode", "CategoryContentNode")
  container = contentToTranslate.container
  contents = contentToTranslate.contents
  fetchedAt = m.fetchedAtTimestamp_()
  contentsJson = m.getContentsJson_(contents, fullJson)

  node_count = 0
  categoryMetadata = m.buildCategoryAA_(container, contents, contentsJson, fetchedAt)
  if categoryMetadata = invalid  'happens if a container has no valid content in it (ie. all content is out of window)
    return invalid
  end if

  if type(categoryMetadata) = "roAssociativeArray"
    ' buildCategoryAA always returns AA.state = "partial", 
    ' but any single category request should be considered fully loaded
    categoryMetadata.state = "loaded"
    translated.update(categoryMetadata)
    node_count = 1 + translated.getChildCount()
  end if

  ' Set a flag only on content with landscape posters.  We do it here manually
  ' to avoid having to define a custom content node which have
  ' proven to be much slower to instantiate.  Could use some testing,
  ' though.
  if container.id = m.constants.ui.categoryIds.featured and m.singleFeaturePoster <> true
    for i = 0 to translated.getChildCount()-1
      child = translated.getChild(i)
      child.addField("isLandscape", "boolean", false)
      child.isLandscape = true
    end for
  end if

  tubiLog("TranslateMetadata converted " + stri(node_count) + " nodes")
  return translated
End Function


''''''''''''''''''''''
' buildCategoryAA
'
' @container: assocArray, a single container as found in the matrix API
' @contents: assocArray, a set of content meta data as found in the matrix API
' @contentsJson: string, the JSON string of just the contents portion of the matrix API
'
' returns an associative array that can be passed to ContentNode.udpate() to populate the ContentNode and it's children
Function tubiMetadataTranslate_buildCategoryAA(container, contents, contentsJson=invalid, fetchedAt=invalid)
  updateMetadata = {}
  if type(container) = "roAssociativeArray" and type(contents) = "roAssociativeArray"
    updateMetadata = {
      id: container.id
      title: container.title
      description: container.description
      totalCount: 0
      offset: m.constants.performance.categoryGridList.initialBlockSize
      fetchedAt: fetchedAt
      json: ""
      state: "partial"
    }

    if container.type = "channel" and container.children.count() > 0
      withPrepend = true
      updateMetadata.type = m.contentTypes.channel
      updateMetadata.logoUri = container.logo
    else
      withPrepend = false
      updateMetadata.type = m.contentTypes.category
    end if
    jsonAA = {}
    validCount = 0
    children = []
    if withPrepend = true
      children.push(container.id)
      ' new content item
      prependContent = {}
      prependContent.append(container)
      prependContent.delete("children")  ' need to make sure there isn't a recursion later when getContentFromCategoryJson is called
      prependContent.posterarts = [m.generateChannelPosterUrl(container.id)]
      ' new category content group
      prependedContents = {}
      prependedContents[container.id] = prependContent
      prependedContents.append(contents)
      contents = prependedContents
      contentsJson = invalid  ' force it to be regenerated
    end if
    children.append(container.children)
    updateMetadata.children = CreateObject("roArray", children.count(), false)
    for each child in children 
      ' contents[child].valid is "true" or "false" for user categories and is invalid for all other categories.
      ' For all other categories, assume all contents are valid.
      if contents[child] <> invalid and contents[child].valid <> false
        fullChild = contents[child]

        childAA = {
          id: fullChild.id
          title: fullChild.title
          description: fullChild.description
          length: fullChild.duration
          subtype: "ContentNode"
        }
        if container.id = m.constants.ui.categoryIds.featured and m.singleFeaturePoster <> true and fullChild.hero_images <> invalid then
          childAA.hdgridposterurl = fullChild.hero_images[0]
        else if fullChild.posterarts <> invalid then
          childAA.hdgridposterurl = fullChild.posterarts[0]
        end if

        ' normalize ids for series, should always be zero-prefixed
        if fullChild.type = "s" or fullChild.type = "a"
          childAA.id = "0" + fullChild.id
        end if
        jsonAA[childAA.id] = fullChild
        validCount += 1
        updateMetadata.children.push(childAA)
      end if
    end for

    ' if all the content is out of window, do not return category metadata aa
    ' container.cursor = 0 for limitedUI matrix/homescreen calls
    ' container.cursor = invalid for matrix/containers/{id} calls
    ' if we are getting category from matrix/containers/{id} and it returns no valid content,
    ' we want to remove that category from the category screen
    if container.cursor = invalid and validCount = 0
      return invalid
    end if

    updateMetadata.totalCount = validCount
    if contentsJson <> invalid
      updateMetadata.json = contentsJson
    else
      updateMetadata.json = FormatJSON(jsonAA)
    end if
  end if

  return updateMetadata
End Function


''''''''''''''''''''''
' getContentsJson
'
'helper function to encapsulate getting the contents JSON from a matrix single container response
Function tubiMetadataTranslate_getContentsJson(contents, fullJson)
  contentsJson = invalid

  'Doing string operations to isolate the contents portion of the JSON matrix response is considerably faster than re-formatting the JSON
  contentsIdentifier =  Chr(34) + "contents" + Chr(34) + ":{"
  contentsPos = Instr(0, fullJson, contentsIdentifier)
  if contentsPos > 0
    contentsJsonLength = fullJson.len() - contentsPos - contentsIdentifier.len() + 1
    contentsJson = Mid(fullJson, contentsPos + contentsIdentifier.len()-1, contentsJsonLength)
  else
    'Do a Format JSON since we can't find the contents with our string search
    tubiLog("Formatted JSON for category metadata", "warn", "clientWarn", "category-metadata-format-json")
    contentsJson = FormatJSON(contents)
  end if

  return contentsJson
End Function


'See example metadata at "https://uapi.adrise.tv/cms/categories?app_id=tubitv&platform=roku&device_id=AABBCCDDEEFF&page_enabled=false"

''''''''''''''''''''''
' translate
'
' Translates content from server into format that roku understands
' contentToTranslate should be parsed from JSON before it hits this function
Function tubiMetadataTranslate_translate(contentToTranslate) As Object
  translated = CreateObject("roSGNode", "TubiContentNode")
  fetchedAt = m.fetchedAtTimestamp_()
  translated.fetchedAt = fetchedAt  ' This is probably just an ignored object, but we
                                    ' should mark it's fetch time for consistency
  node_count = 0

  if contentToTranslate <> invalid
    'expect a list of categories with one category filled with content or a list of contents
    if type(contentToTranslate) = "roArray"
      for each content in contentToTranslate
        if content.title <> "After Hours" or m.allowAfterHours = true
          node = translated.createChild("TubiContentNode")
          node_count = node_count + m.translateRecursive(content, node, fetchedAt)
        end if
      end for

    'expect a single piece of content, or several (as an associative array)
    else if type(contentToTranslate) = "roAssociativeArray"

      'expect this to happen just for the search API
      if contentToTranslate.children <> invalid
        node_count = m.translateRecursive(contentToTranslate, translated, fetchedAt)
      
      'expect this to happen for history/queue content
      else
        for each content in contentToTranslate
          if contentToTranslate[content] <> invalid
            node = translated.createChild("TubiContentNode")
            node_count = node_count + m.translateRecursive(contentToTranslate[content], node, fetchedAt)
          end if
        end for
      end if
    end if
  end if

  m.setTotalCount_(translated)
  tubiLog("TranslateMetadata converted " + stri(node_count) + " nodes")
  return translated
end Function


Function tubiMetadataTranslate_translateChannel(contentToTranslate)
  translated = CreateObject("roSGNode", "CategoryContentNode")
  fetchedAt = m.fetchedAtTimestamp_()
  node_count = 0
  container = contentToTranslate.container
  if container <> invalid
    translated.id = container.id
    translated.title = container.title
    translated.description = container.description
    translated.offset = 0
    translated.json = ""
    translated.state = "loaded"
    translated.logoUri = container.logo
    translated.type = m.contentTypes.channel
    translated.slug = container.slug
    translated.fetchedAt = fetchedAt

    for i=0 to container.children.count()-1
      child = contentToTranslate.contents[contentToTranslate.container.children[i]]
      node = translated.createChild("TubiContentNode")
      node_count += m.translateRecursive(child, node, fetchedAt)
    end for
  end if
  m.setTotalCount_(translated)
  tubiLog("TranslateMetadata converted " + stri(node_count) + " nodes")
  return translated
End Function


Function tubiMetadataTranslate_generateChannelPosterUrl(channelId)
  if (type(channelId) = "String" or type(channelId) = "roString") and channelId <> ""
    return m.constants.urls.channelPosterBrandedPrefix + channelId + m.constants.urls.channelPosterBrandedSuffix
  else
    return m.constants.urls.channelPosterUnbranded
  end if
End Function

' The fetchedAt field in various content nodes should be seconds since epoch and
' only be used locally (not intended to be synchronized with any server-side timestamps)
Function tubiMetadataTranslate_fetchedAtTimestamp()
  return CreateObject("roDateTime").AsSeconds()
End Function
