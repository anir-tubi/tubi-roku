Function TubiMetadataTranslate(constants, experiments = invalid)
  return {
    ' public
    translateBackendTypeToClientSideType: tubiMetadataTranslate_translateBackendTypeToClientSideType
    translateRecursive: tubiMetadataTranslate_translateRecursive
    getContentFromCategoryJson: tubiMetadataTranslate_getContentFromCategoryJson
    translateRelatedContent: tubiMetadataTranslate_translateRelatedContent
    translate: tubiMetadataTranslate_translate
    translateContainer: tubiMetadataTranslate_translateContainer
    translateChannel: tubiMetadataTranslate_translateChannel
    translateHomescreen: tubiMetadataTranslate_translateHomescreen
    translateChannelsCategories: tubiMetadataTranslate_translateChannelsCategories

    ' private
    constants: constants
    contentTypes: constants.ui.contentTypes
    creditsDuration: constants.player.creditsDuration
    allowAfterHours: constants.settings.allowAfterHours
    dedupeBackgrounds: tubiMetadataTranslate_dedupeBackgrounds
    setTotalCount: tubiMetadataTranslate_setTotalCount
    getContentsJson: tubiMetadataTranslate_getContentsJson
    buildCategoryAA: tubiMetadataTranslate_buildCategoryAA
    buildUtilityCategoryAA: tubiMetadataTranslate_buildUtilityCategoryAA
    buildContinueWatchingSignedOutUserCategoryAA: tubiMetadataTranslate_buildContinueWatchingSignedOutUserCategoryAA
    generateChannelPosterUrl: tubiMetadataTranslate_generateChannelPosterUrl
    fetchedAtTimestamp: tubiMetadataTranslate_fetchedAtTimestamp
    getGridItemType: tubiMetadataTranslate_getGridItemType
    experiments: experiments
    getThumbnailImage: tubiMetadataTranslate_getThumbnailImage
  }
End Function


Function tubiMetadataTranslate_dedupeBackgrounds(backgroundsFromServer) As Object
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
' getThumbnailImage
'
' Get the thumbnail URL that should be used to set the ContentNode's HDGRIDPOSTERURL property
Function tubiMetadataTranslate_getThumbnailImage(contentFromServer, gridType = "")
  canvasImages = contentFromServer.images
  sThumbnailURL = ""
  if gridType = ""
    gridType = m.constants.ui.gridItemTypes.portrait
  end if

  if gridType = m.constants.ui.gridItemTypes.portrait
    if canvasImages <> invalid and type(canvasImages.poster_tb) = "roArray" and canvasImages.poster_tb[0] <> invalid and canvasImages.poster_tb[0] <> ""
      '//A custom portrait size was requested, use this image instead of the default image
      sThumbnailURL = canvasImages.poster_tb[0]
    else if contentFromServer.posterarts <> invalid and type(contentFromServer.posterarts) = "roArray" and contentFromServer.posterarts.count() > 0
      sThumbnailURL = contentFromServer.posterarts[0]
    end if
  else if gridType = m.constants.ui.gridItemTypes.landscape
    if canvasImages <> invalid and type(canvasImages.landscape_tb) = "roArray" and canvasImages.landscape_tb[0] <> invalid and canvasImages.landscape_tb[0] <> ""
      '//A custom landscape size was requested, use this image instead of the default image
      sThumbnailURL = canvasImages.landscape_tb[0]
    else if contentFromServer.hero_images <> invalid and type(contentFromServer.hero_images) = "roArray" and contentFromServer.hero_images.count() > 0
      sThumbnailURL = contentFromServer.hero_images[0]
    else if contentFromServer.thumbnails <> invalid and type(contentFromServer.thumbnails) = "roArray" and contentFromServer.thumbnails.count() > 0
      sThumbnailURL = contentFromServer.thumbnails[0]
    end if
  else if gridType = m.constants.ui.gridItemTypes.vitg_large
    if canvasImages <> invalid and type(canvasImages.vitg_tb) = "roArray" and canvasImages.vitg_tb[0] <> invalid and canvasImages.vitg_tb[0] <> ""
      '//A custom vitg size was requested, use this image instead of the default image
      sThumbnailURL = canvasImages.vitg_tb[0]
    else if contentFromServer.hero_images <> invalid and type(contentFromServer.hero_images) = "roArray" and contentFromServer.hero_images.count() > 0
      if contentFromServer.hero_images.count() >= 2
        '//::TEMP:: The Tupian image server will not return the resized image yet in the proper place, so look for the resized image in the old image array, but at a different index placement than the usual index location 
        sThumbnailURL = contentFromServer.hero_images[1]
      else 
        sThumbnailURL = contentFromServer.hero_images[0]
      end if
    end if
  end if
  return sThumbnailURL
End Function



'''''''''''''''''''''
' translateBackendTypeToClientSideType
'
' Translate the backend type into a more readable client side content type
Function tubiMetadataTranslate_translateBackendTypeToClientSideType(sBackendType = "" as String) as String
  sReturn = ""
  if sBackendType = "u"
    sReturn = m.contentTypes.utility
  else if sBackendType = "c"
    sReturn = m.contentTypes.category
  else if sBackendType = "cwso"
    sReturn = m.contentTypes.historySignedOutUser
  else if sBackendType = "v" or sBackendType = "clip"
    sReturn = m.contentTypes.video
  else if sBackendType = "s"
    sReturn = m.contentTypes.series
  else if sBackendType = "a"
    sReturn = m.contentTypes.season
  else if sBackendType = "channel"
    sReturn = m.contentTypes.channel
  else if sBackendType = "l"
    sReturn = m.contentTypes.linear
  end if

  return sReturn
End Function



'''''''''''''''''''''
' translateRecursive
'
' This is a recursive Function that does the heavy lifting for translateContentFromServer
'this is a recursive Function that does the heavy lifting for translateContentFromServer
Function tubiMetadataTranslate_translateRecursive(contentFromServer As Object, translatedContent As Object) as integer
  if contentFromServer = invalid or type(contentFromServer) <> "roAssociativeArray" then return 0

  count = 1

  if contentFromServer.id <> invalid then translatedContent.id = contentFromServer.id
  typeVar = "type"
  if contentFromServer[typeVar] <> invalid
    sType = m.translateBackendTypeToClientSideType(contentFromServer[typeVar])
    translatedContent[typeVar] = sType

    if sType = m.contentTypes.series
      ' prefix "0" to series
      if translatedContent.id <> "" then translatedContent.id = "0" + translatedContent.id
    else if sType = m.contentTypes.season
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
 
  translatedContent.landscape  = m.getThumbnailImage(contentFromServer, m.constants.ui.gridItemTypes.landscape)  
  sPortraitURL = m.getThumbnailImage(contentFromServer)
  if sPortraitURL <> ""
    translatedContent.portrait = sPortraitURL 
    translatedContent.HDGRIDPOSTERURL = sPortraitURL
  end if
  if (translatedContent.HDGRIDPOSTERURL = invalid or translatedContent.HDGRIDPOSTERURL = "") and contentFromServer.HDGRIDPOSTERURL <> invalid
    '//If the contentFromServer already set HDGRIDPOSTERURL then use that value. 
    translatedContent.HDGRIDPOSTERURL = contentFromServer.HDGRIDPOSTERURL
  end if

  if contentFromServer.backgrounds <> invalid and type(contentFromServer.backgrounds) = "roArray" and contentFromServer.backgrounds.count() > 0
    translatedContent.backgrounds = m.dedupeBackgrounds(contentFromServer.backgrounds)
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

  '//Parse the cuePoints
  if contentFromServer.monetization <> invalid and contentFromServer.monetization.cue_points <> invalid
    translatedContent.cuepoints = contentFromServer.monetization.cue_points
  end if

  ' DRM encoded streams
  if type(contentFromServer.video_resources) = "roArray" and contentFromServer.video_resources.count() > 0
    ' Create a "stub" ContentNode with just the DRM-oriented fields populated. This
    ' will make it easy to merge metadata plus drm info into one actionable
    ' contentnode for the video player
    videoResources = []
    for each video in contentFromServer.video_resources
      resource = {}
      if video.manifest <> invalid
        if video.manifest.url <> invalid then resource.url = video.manifest.url
        if video.manifest.duration <> invalid then resource.length = video.manifest.duration
      end if

      if video.type = m.constants.player.drmTypes.dashWidevine 
        resource.type = m.constants.player.drmTypes.dashWidevine
        resource.streamFormat = "dash"
        if video.license_server <> invalid
          resource.drmParams = {
            keySystem: "Widevine"
            licenseServerURL: video.license_server.url
          }
          if video.license_server.auth_header_key <> invalid and video.license_server.auth_header_value <> invalid
            resource.drmHeaders = [video.license_server.auth_header_key + ":" + video.license_server.auth_header_value]
          end if

          if video.license_server.hdcp_version <> invalid
            resource.hdcpVersion = video.license_server.hdcp_version
          end if
        end if
      else if video.type = m.constants.player.drmTypes.dashPlayReady
        resource.type = m.constants.player.drmTypes.dashPlayReady
        resource.streamFormat = "dash"
        if video.license_server <> invalid
          resource.encodingType = "PlayReadyLicenseAcquisitionUrl"
          resource.encodingKey = video.license_server.url
          if video.license_server.auth_header_key <> invalid and video.license_server.auth_header_value <> invalid
            resource.drmHeaders = [video.license_server.auth_header_key + ":" + video.license_server.auth_header_value]
          end if

          if video.license_server.hdcp_version <> invalid
            resource.hdcpVersion = video.license_server.hdcp_version
          end if
        end if
      else if video.type = m.constants.player.drmTypes.hlsv3
        resource.type = m.constants.player.drmTypes.hlsv3
        resource.streamFormat = "hls"
      else
        ' Don't add unsupported/unknown video resource types
        resource = invalid
      end if

      if resource <> invalid
        videoResources.push(resource)
      end if
    end for
    translatedContent.videoResources = videoResources
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

  ' linear
  if translatedContent[typeVar] = m.contentTypes.linear and translatedContent.hasSubtitles = true
    '//::TODO::LiveNews::HARDCODE:: - The following code is a hardcoded. 
    '//   The backend needs to let us know what captions are available and what channel the track is on.
    '//   In the meantime, backend is setting the has_subtitles field to true if the stream has at least 1 caption. We will assume during MVP of the live news launch that the caption in the 1st caption channel is English.
    '//   For future versions, backend will provide the language and channel location.
    '//   MAYBE, in a future Roku firmware update, captions will be known. However, we currently do not know when or if any future update will have this ability. 
    subtitleTracks = []
    subtitleTracks.push({
        language: "eng"
        description: "English"
        trackname: "eia608/CC1"
      })
    translatedContent.subtitleTracks = subtitleTracks
    translatedContent.subtitleConfig = {TrackName: "eia608/CC1"}
  end if
  if translatedContent[typeVar] = m.contentTypes.linear 
    if contentFromServer.thumbnails <> invalid
      translatedContent.inlineLogoUri = contentFromServer.thumbnails[0]
    end if
  end if

  ' trailers
  if contentFromServer.trailers <> invalid and type(contentFromServer.trailers) = "roArray" and contentFromServer.trailers.count() > 0
    if contentFromServer.trailers[0] <> invalid and contentFromServer.trailers[0].url <> invalid and contentFromServer.trailers[0].url <> ""
      translatedContent.trailerInfo = contentFromServer.trailers[0]
    end if
  end if
  
  if contentFromServer.has_trailer = true then translatedContent.hasTrailer = true

  'if this content is actually just a paginated response, set pagination data
  if contentFromServer.total_count <> invalid then translatedContent.totalCount = contentFromServer.total_count

  if contentFromServer.more <> invalid then translatedContent.more = contentFromServer.more

  ' Channels
  if contentFromServer.channel_id <> invalid then translatedContent.channelId = contentFromServer.channel_id
  if contentFromServer.channel_logo <> invalid then translatedContent.inlineLogoUri = contentFromServer.channel_logo
  if contentFromServer.logo <> invalid then translatedContent.titleLogoUri = contentFromServer.logo
  if contentFromServer.channel_name <> invalid then translatedContent.channelName = contentFromServer.channel_name

  if contentFromServer.is_recurring <> invalid then translatedContent.isRecurring = contentFromServer.is_recurring
  if contentFromServer.availability_ends <> invalid then translatedContent.availabilityEnds = contentFromServer.availability_ends

  'set the time past which the content metadata should be refreshed from the server
  if contentFromServer.valid_duration <> invalid
    translatedContent.validUntil = UpTime(0) + contentFromServer.valid_duration
  else
    translatedContent.validUntil = UpTime(0) + m.constants.cacheTimes.content
  end if

  'take care of any children the content might have
  if contentFromServer.children <> invalid and contentFromServer.children.count() > 0

    if translatedContent.totalCount = -1
      translatedContent.totalCount = contentFromServer.children.count()
    end if

    for each childContent in contentFromServer.children
      node = translatedContent.createChild("TubiContentNode")
      ' pass the resolved fetchedAt time so that it doesn't have to be generated again for every child
      count = count + m.translateRecursive(childContent, node)
    end for

  end if

  ' return the total number of children converted
  return count
End Function


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
      m.translateRecursive(fullContent, translated)
      translated.parentId = category.id
      translated.parentType = category.type
      translated.parentTitle = category.title

      vitg_large = m.constants.ui.gridItemTypes.vitg_large
      vitg_small = m.constants.ui.gridItemTypes.vitg_small
      ' inject the default background for large vitg content items
      if category.gridItemType = vitg_large 
        translated.backgrounds = [m.constants.ui.uris.defaultBackground]
      else if category.gridItemType = m.constants.ui.gridItemTypes.historySignedOutUser 
        translated.backgrounds = [m.constants.ui.uris.defaultBackground]
      end if

      ' set vitg on the content node so various non item UI components can respond to it (ie. detail screen)
      if category.gridItemType = vitg_large or category.gridItemType = vitg_small
        translated.addField("isVitg", "boolean", false)
        translated.isVitg = true
      end if

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
  translated = CreateObject("roSGNode", "CategoryContentNode")
  if type(contentFromServer) = "roArray"
    shortestValidDuration = invalid
    for each content in contentFromServer
      node = translated.createChild("TubiContentNode")
      m.translateRecursive(content, node)

      if shortestValidDuration = invalid
        shortestValidDuration = content.valid_duration
      else if content.valid_duration <> invalid
        if content.valid_duration < shortestValidDuration
          shortestValidDuration = content.valid_duration
        end if
      end if
    end for

    if shortestValidDuration <> invalid
      translated.validUntil = UpTime(0) + shortestValidDuration
    else
      translated.validUntil = Uptime(0) + m.constants.cacheTimes.category
    end if
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
'//::TODO:: Remove the contentMode, authInfo & isKidsMode parameters once we have API support
'
' @contentToTranslate: AA, json parsed response from the matrix/homescreen endpoint
' @contentMode: string, the value of the contentMode parameter as sent as part of the matrix/homescreen request
' @authInfo: AA, auth info as returned by Auth.getAuthInfo()
' @isKidsMode: boolean, the value of the isKidsMode parameter as sent as part of the matrix/homescreen request
' @uiMode: string, one of the allowed values from constants.ui.modes
Function tubiMetadataTranslate_translateHomescreen(contentToTranslate, contentMode="homescreen", authInfo=invalid, isKidsMode=false, uiMode="standard") As Object
  translated = CreateObject("roSGNode", "CategoryContentNode")
  homescreenAA = {
    id: ""
    title: ""
    validUntil: 0
    children: []    'categories
  }

  if contentToTranslate.valid_duration <> invalid
    homescreenAA.validUntil = Uptime(0) + contentToTranslate.valid_duration
  else
    homescreenAA.validUntil = Uptime(0) + m.constants.cacheTimes.homescreen
  end if

  containers = contentToTranslate.containers
  contents = contentToTranslate.contents

  ' userCategoriesPos is used to store the index in the list of categories where the /homescreen API
  ' placed the userCategories
  continueWatchingIndex = 4
  queueIndex = 5
  
  '//::TODO:: Remove the kidsModeFeatureOn check once we have API support  
  kidsModeFeatureOn = false   'Should the kids Mode feature be made available for the user to interact with
  if m.constants.deviceInfo.countryCode <> invalid and (UCase(m.constants.deviceInfo.countryCode) = "US" or UCase(m.constants.deviceInfo.countryCode) = "CA")
    kidsModeFeatureOn = true
  end if  

  '//::TODO:: Remove the parentalRating check once we have API support    
  parentalRating = 3
  if authInfo <> invalid and authInfo.parentalRating <> invalid
    parentalRating = authInfo.parentalRating
  end if
  
  ' utility row position experiment
  utilityRowPosition = -2 ' setting default as negative to avoid insertion if the experiment is control group

  if m.experiments <> invalid
    m.experimentInfo = m.experiments.getExperimentResource("roku_discovery_v3", "roku_discovery_row_v3")
    if m.experimentInfo <> invalid
    ' decreasing the position value by 1 in order to use it as index
      utilityRowPosition = m.experimentInfo.position - 1
    end if
  end if
  
  ' include utility row only in homescreen when kidsmode feature is ON (available to users) and
  ' parentalRating is set to Adult and isKidsMode is false
  includeUtilityRow = false
  if kidsModeFeatureOn = true and contentMode = m.constants.ui.contentMode.homescreen and parentalRating > 2 and isKidsMode = false
    includeUtilityRow = true
  end if  

  'set up AAs for all categories
  for i=0 to containers.count()-1
    container = containers[i]
    if container.id = m.constants.ui.categoryIds.history
      continueWatchingIndex = i
      ' increasing the utilityRowPosition by 1 if the ContinueWatching has no children AND the user
      ' is signed in (continue watching row is displayed if the user is not signed in regardless).
      '//::TODO:: Remove this section once we have API support
      if container.children.Count() = 0 and (authInfo <> invalid or uiMode = m.constants.ui.modes.kidsAgeGate)
        utilityRowPosition = utilityRowPosition + 1
      end if
    else if container.id = m.constants.ui.categoryIds.queue
      queueIndex = i
      ' increasing the utilityRowPosition by 1 if the MyList/Queue has no children
      '//::TODO:: Remove this section once we have API support
      if container.children.Count() = 0
        utilityRowPosition = utilityRowPosition + 1
      end if
    end if

    ' inserting utilityRow in specific position based on experiment result
    '//::TODO:: Remove this section once we have API support
    if includeUtilityRow = true and i = utilityRowPosition
      categoryAA = m.buildUtilityCategoryAA(containers)
      if categoryAA <> invalid
        homescreenAA.children.push(categoryAA)
      end if
      categoryAA = invalid
    end if

    if container.id = m.constants.ui.categoryIds.history and authInfo = invalid and uiMode <> m.constants.ui.modes.kidsAgeGate
      '//if continue watching container while user is signed out,
      ' then ensure row is empty except for 1 item that will entice users to sign in
      categoryAA = m.buildContinueWatchingSignedOutUserCategoryAA(container, isKidsMode)
      if categoryAA <> invalid
        homescreenAA.children.push(categoryAA)
      end if
    else
      categoryAA = m.buildCategoryAA(container, contents, invalid, "", false, contentMode)
      if categoryAA <> invalid
        homescreenAA.children.push(categoryAA)
      end if
    end if
  end for

  translated.update(homescreenAA)
  translated.addField("continueWatchingIndex", "integer", false)
  translated.addField("queueIndex", "integer", false)
  translated.continueWatchingIndex = continueWatchingIndex
  translated.queueIndex = queueIndex
  node_count = 1 + translated.getChildCount()
  tubiLog("TranslateMetadata converted " + stri(node_count) + " nodes")
  return translated
End Function


''''''''''''''''''''
' translateChannelsCategories
'
' Translate a response from matrix/categories or matrix/channels for use in ChannelGridScreen
Function tubiMetadataTranslate_translateChannelsCategories(contentToTranslate, bDisplayChannels = true) As Object
  sID_queue = m.constants.ui.categoryIds.queue 
  sID_continue_watching = m.constants.ui.categoryIds.history

  oLimitTypes = {}
  if bDisplayChannels = true
    oLimitTypes[m.constants.ui.categoryTypes.channel] = true
  else
    oLimitTypes[m.constants.ui.categoryTypes.regular] = true
    oLimitTypes[m.constants.ui.categoryTypes.history] = true
    oLimitTypes[m.constants.ui.categoryTypes.queue] = true
  end if

  catRecommend = invalid
  catContinueWatching = invalid
  catQueue = invalid

  '//The following is a modifed version of the tubiMetadataTranslate_translateHomescreen() method
  translated = CreateObject("roSGNode", "CategoryContentNode")
  homescreenAA = {
    id: ""
    title: ""
    validUntil: 0
    children: []    'categories
  }
  if contentToTranslate.valid_duration <> invalid
    homescreenAA.validUntil = Uptime(0) + contentToTranslate.valid_duration
  else
    homescreenAA.validUntil = Uptime(0) + m.constants.cacheTimes.homescreen
  end if

  containers = contentToTranslate.containers
  contents = contentToTranslate.contents

  '//The following code adds a transparency to the thumbnails and for categories, it shifts a few categories to the top of the list
  '//::HARDCODED:: If this is categories, then place few catrgories in the front and get rid of featured
  '//::TODO:: have the backend filter and sort categories when they have more bandwidth
  'set up AAs for all categories including any nested categories

  for i=0 to containers.count()-1
    container = containers[i]

    if oLimitTypes[container.type] = true
      categoryAA = m.buildCategoryAA(container, contents, invalid, "", false)  'categoryAA is invalid if empty container
      if categoryAA <> invalid
        if bDisplayChannels = true
          categoryAA.type = m.contentTypes.channel
        else
          categoryAA.type = m.contentTypes.category
        end if

        sID = ""
        if categoryAA.id <> invalid
          sID = LCase(categoryAA.id)
        end if

        if sID <> m.constants.ui.categoryIds.featured
          if sID = m.constants.ui.categoryIds.recommendedForYou
            catRecommend = categoryAA
            catRecommend.isSpecial = true
            catRecommend.thumbnail = m.constants.ui.uris.categoryBackgrounds.recommended
          else if sID = sID_continue_watching
            catContinueWatching = categoryAA
            catContinueWatching.isSpecial = true
            catContinueWatching.thumbnail = m.constants.ui.uris.categoryBackgrounds.continueWatching
          else if sID = sID_queue
            catQueue = categoryAA
            catQueue.isSpecial = true
            catQueue.thumbnail = m.constants.ui.uris.categoryBackgrounds.queue
          else
            homescreenAA.children.push(categoryAA)
          end if
        end if
      end if
    end if
  end for
  
  homescreenAA.children.SortBy("title")

  '//Move the following items to the front of the list if they exist
  if catQueue <> invalid
    homescreenAA.children.Unshift(catQueue)
  end if
  if catContinueWatching <> invalid
    homescreenAA.children.Unshift(catContinueWatching)
  end if
  if catRecommend <> invalid
    homescreenAA.children.Unshift(catRecommend)
  end if

  ' use gradient images that reside on the CDN for category/channel poster images
  for i=0 to homescreenAA.children.count()-1
    categoryAA = homescreenAA.children[i]

    if categoryAA.isSpecial <> true
      thumbnailNumber = (i MOD 11) + 1
      categoryAA.thumbnail = m.constants.ui.uris.categoryBackgrounds.urlBase + thumbnailNumber.toStr() + m.constants.ui.uris.categoryBackgrounds.urlEnding 
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
' 1) Use ContentNode instead of TubiContentNode for item contents
' 2) Use ifSGNodeChildren.update() to leverage native code for node creation and setting fields
' 3) Avoid custom fields in favor of ContentNode's defined fields, this avoiding addField() calls in a loop
Function tubiMetadataTranslate_translateContainer(contentToTranslate, fullJson, sOrientation = "", bFullData = false, contentMode="homeScreen") As Object
  translated = CreateObject("roSGNode", "CategoryContentNode")
  container = contentToTranslate.container
  contents = contentToTranslate.contents
  contentsJson = m.getContentsJson(contentToTranslate, fullJson) 

  node_count = 0
  categoryMetadata = m.buildCategoryAA(container, contents, contentsJson, sOrientation, bFullData, contentMode)
  if categoryMetadata = invalid  'happens if a container has no valid content in it (ie. all content is out of window)
    return invalid
  end if

  ' Store the gridItemType as necessary (only for landscape, linear, vitg, and utility). 
  ' We do it here manually, after creating the child nodes, to avoid having to define
  ' a custom content node which have proven to be much slower to instantiate.
  ' Could use some testing though.
  landscape = m.constants.ui.gridItemTypes.landscape
  portrait = m.constants.ui.gridItemTypes.portrait
  vitg_small = m.constants.ui.gridItemTypes.vitg_small
  vitg_large = m.constants.ui.gridItemTypes.vitg_large
  utility = m.constants.ui.gridItemTypes.utility
  linear = m.constants.ui.gridItemTypes.linear
  gridItemType = m.getGridItemType(container, sOrientation, m.constants)

  '//::HARDCODE:: If the container type includes live news, then mark this as "new". evebtually we will remove the new tag
  if gridItemType = linear
    categoryMetadata.new = true
  end if

  if type(categoryMetadata) = "roAssociativeArray"
    ' buildCategoryAA always returns AA.state = "partial",
    ' but any single category request should be considered fully loaded
    categoryMetadata.state = "loaded"
    translated.update(categoryMetadata)
    node_count = 1 + translated.getChildCount()
  end if

  if gridItemType = landscape or gridItemType = vitg_small or gridItemType = vitg_large or gridItemType = utility or gridItemType = linear
    for i = 0 to translated.getChildCount()-1
      child = translated.getChild(i)
      child.addField("gridItemType", "string", false)
      child.gridItemType = gridItemType
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
' @sOrientation: string, should the thumbnail be a "portrait" or "landscape" (match against m.constants.ui.gridItemTypes values)
' @bFullData: boolean, Should the full data be parsed and passed to the video children?
'
' returns an associative array that can be passed to ContentNode.udpate() to populate the ContentNode and it's children
Function tubiMetadataTranslate_buildCategoryAA(container, contents, contentsJson=invalid, sOrientation = "", bFullData = false, contentMode="homeScreen")
  updateMetadata = {}
  if type(container) = "roAssociativeArray" and type(contents) = "roAssociativeArray"
    ' the metadata for the category
    sTitle = container.title
    if container.id = m.constants.ui.categoryIds.queue 
      '//::HARDCODE:: this is a temporary hardcode until the backend is ready to play My List Instead of Queue as the title
      if contentMode <> m.constants.ui.contentMode.latino
        sTitle = "My List"
      end if
    end if
 
    updateMetadata = {
      id: container.id
      slug: container.slug
      title: sTitle
      description: container.description
      totalCount: 0
      offset: m.constants.performance.categoryGridList.initialBlockSize
      validUntil: 0
      json: ""
      state: "partial"
      gridItemType: m.getGridItemType(container, sOrientation, m.constants)
    }
    
    '//::HARDCODE:: If the container type includes live news, then mark this as "new". eventually we will remove the new tag
    if updateMetadata.gridItemType = m.constants.ui.gridItemTypes.linear
      updateMetadata.new = true
    end if

    if container.thumbnail <> invalid
      updateMetadata.thumbnail = container.thumbnail
    end if

    withPrepend = false
    updateMetadata.type = m.contentTypes.category

    if container.type = m.contentTypes.channel
      updateMetadata.type = m.contentTypes.channel
      if container.children <> invalid and container.children.count() > 0
        withPrepend = true
      end if
    end if

    updateMetadata.logoUri = container.logo

    if container.valid_duration <> invalid
      updateMetadata.validUntil = Uptime(0) + container.valid_duration
    else
      updateMetadata.validUntil = Uptime(0) + m.constants.cacheTimes.category
    end if

    jsonAA = {}
    validCount = 0
    children = []
    
    'add the channel content to the beginning of the category
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
      ' For all other categories, assume all contents are valid. Valid in this case means, the content is "in window"
      ' and allowed to be played on the Roku platform
      if contents[child] <> invalid and contents[child].valid <> false
        childIsPushable = true
        fullChild = contents[child]
        sType = "ContentNode"
        if bFullData = true
          '//if true then set children to TubiContentNode type so more data is passed to the children
          sType = "TubiContentNode"
        end if

        if updateMetadata.gridItemType = m.constants.ui.gridItemTypes.vitg_small or updateMetadata.gridItemType = m.constants.ui.gridItemTypes.vitg_large
          sType = "VitgContentNode"
        else if updateMetadata.gridItemType = m.constants.ui.gridItemTypes.linear
          sType = "TubiContentNode"
        end if
        

        sContentType = m.translateBackendTypeToClientSideType(fullChild.type)
        childAA = {
          id: fullChild.id
          title: fullChild.title
          description: fullChild.description
          length: fullChild.duration
          subtype: sType
          type: sContentType
        }
        
        bLandscape = false
        if updateMetadata.gridItemType = m.constants.ui.gridItemTypes.portrait or updateMetadata.gridItemType = m.constants.ui.gridItemTypes.utility
          bLandscape = false
        else if updateMetadata.gridItemType = m.constants.ui.gridItemTypes.landscape and fullChild.hero_images <> invalid
          bLandscape = true
        else if container.id = m.constants.ui.categoryIds.featured and fullChild.hero_images <> invalid
          bLandscape = true
        else if updateMetadata.gridItemType = m.constants.ui.gridItemTypes.vitg_small or updateMetadata.gridItemType = m.constants.ui.gridItemTypes.vitg_large
          bLandscape = true
        end if

        if bFullData = true and fullChild.backgrounds <> invalid and type(fullChild.backgrounds) = "roArray" and fullChild.backgrounds.count() > 0
          childAA.backgrounds = m.dedupeBackgrounds(fullChild.backgrounds)
        end if

        gridType = ""
        if updateMetadata.gridItemType = m.constants.ui.gridItemTypes.portrait
          gridType = m.constants.ui.gridItemTypes.portrait
        else if updateMetadata.gridItemType = m.constants.ui.gridItemTypes.landscape
          gridType = m.constants.ui.gridItemTypes.landscape
        else if container.id = m.constants.ui.categoryIds.featured
          gridType = m.constants.ui.gridItemTypes.landscape
        else if updateMetadata.gridItemType = m.constants.ui.gridItemTypes.vitg_small
          gridType = m.constants.ui.gridItemTypes.landscape
        else if updateMetadata.gridItemType = m.constants.ui.gridItemTypes.vitg_large
          gridType = m.constants.ui.gridItemTypes.vitg_large
        end if

        if bLandscape = true then
          childAA.hdgridposterurl = fullChild.hero_images[0]
        else if fullChild.posterarts <> invalid then
          childAA.hdgridposterurl = fullChild.posterarts[0]
          ' HDPOSTERURL is an active image which is used in utility row
          if updateMetadata.gridItemType = m.constants.ui.gridItemTypes.utility
            childAA.HDPOSTERURL = fullChild.posterarts[1]
          end if
        end if
        childAA.hdgridposterurl = m.getThumbnailImage(fullChild, gridType)

        if updateMetadata.gridItemType = m.constants.ui.gridItemTypes.linear and fullChild.thumbnails <> invalid
          childAA.inlineLogoUri = fullChild.thumbnails[0]
        end if

        'add the trailer url to vitg content items - don't include vitg content if there is no trailer
        if updateMetadata.gridItemType = m.constants.ui.gridItemTypes.vitg_small or updateMetadata.gridItemType = m.constants.ui.gridItemTypes.vitg_large
          childIsPushable = false
          if fullChild.has_trailer = true
            if fullChild.trailers <> invalid and type(fullChild.trailers) = "roArray" and fullChild.trailers.count() > 0
              if fullChild.trailers[0] <> invalid and fullChild.trailers[0].url <> invalid and fullChild.trailers[0].url <> ""
                childAA.url = fullChild.trailers[0].url
                ' abuse the contentNode fields to add vitg info to the content node
                ' so that we can continue to use the content node which is created faster than custom nodes
                if fullChild.trailers[0].duration <> invalid
                  ' use deprecated playDuration as a store for the trailer duration since we are
                  ' already using the length field for our content duration
                  childAA.playDuration = fullChild.trailers[0].duration
                end if

                if fullChild.trailers[0].id <> invalid
                  ' use the otherwise unused episodeNumber field as a store for the trailer id
                  ' so that we have access to the trailer id for trailer analytics
                  childAA.episodeNumber = fullChild.trailers[0].id
                end if
                childIsPushable = true
              end if
            end if
          end if

          if fullChild.year <> invalid
            childAA.releaseDate = fullChild.year.toStr()
          end if
        end if
        
        sFullChildID = fullChild.id
        if Type(fullChild.id) = "Integer"
          '//in case the ID is an integer, change it to a string.
          sFullChildID = fullChild.id.toStr()
        end if
        childAA.id = sFullChildID

        ' normalize ids for series, should always be zero-prefixed
        if fullChild.type = "s" or fullChild.type = "a"
          childAA.id = "0" + sFullChildID
        end if
        if childIsPushable = true
          jsonAA[childAA.id] = fullChild
        end if

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
'helper Function to encapsulate getting the contents JSON from a matrix single container response
'@parsedJson: assocArray, the container response that has already been run through ParseJSON()
'@fullJson: string, the full json formatted response
Function tubiMetadataTranslate_getContentsJson(parsedJson, fullJson)
  contentsJson = invalid

  'Doing string operations to isolate the contents portion of the JSON matrix response is ~4x faster than re-formatting the JSON
  contentsIdentifier =  Chr(34) + "contents" + Chr(34) + ":{"
  safetyEject = false
  contentsIdentifierPos = Instr(1, fullJson, contentsIdentifier)
  
  'make sure the content key exists exactly once in the JSON string
  if contentsIdentifierPos > 0 and Instr(contentsIdentifierPos + 1, fullJson, contentsIdentifier) < 1
    contentsStartPos = contentsIdentifierPos + contentsIdentifier.len() - 1
    contentsEndPos = fullJson.len()  'set default assuming contents is the last key in the AA json

    for each key in parsedJson
      if key <> "contents"
        keyIdentifier = Chr(34) + key + Chr(34) + ":"   ' ex: "container":  'can't guarantee AA so don't include bracket
        keyPos = Instr(1, fullJson, keyIdentifier)
        'make sure the key exists exactly once in the JSON string
        if keyPos > 0 and Instr(keyPos + 1, fullJson, keyIdentifier) < 1
          if keyPos > contentsStartPos and keyPos < contentsEndPos
            contentsEndPos = keyPos - 1
          end if
        else
          safetyEject = true  ' key not found, or found multiple times in string, can't be trusted
          exit for
        end if
      end if
    end for
  end if

  if safetyEject = false
    contentsJson = Mid(fullJson, contentsStartPos, contentsEndPos - contentsStartPos)
  end if

  'the optimization didn't update contentsJson, so do the slower but more faithful way (FormatJSON)
  if contentsJson = invalid and parsedJson.contents <> invalid
    tubiLog("Formatted JSON for category metadata", "warn", "clientWarn", "category-metadata-format-json")
    contentsJson = FormatJSON(parsedJson.contents)
  end if

  return contentsJson
End Function


'See example metadata at "https://uapi.adrise.tv/cms/categories?app_id=tubitv&platform=roku&device_id=AABBCCDDEEFF&page_enabled=false"

''''''''''''''''''''''
' translate
'
' Translates content from server into format that roku understands
' contentToTranslate should be parsed from JSON before it hits this Function
Function tubiMetadataTranslate_translate(contentToTranslate) As Object
  translated = CreateObject("roSGNode", "TubiContentNode")
  fetchedAt = m.fetchedAtTimestamp()
  translated.fetchedAt = fetchedAt  ' This is probably just an ignored object, but we
  ' should mark it's fetch time for consistency
  node_count = 0

  if contentToTranslate <> invalid
    'expect a list of categories with one category filled with content or a list of contents
    if type(contentToTranslate) = "roArray"
      for each content in contentToTranslate
        if content.title <> "After Hours" or m.allowAfterHours = true
          node = translated.createChild("TubiContentNode")
          node_count = node_count + m.translateRecursive(content, node)
        end if
      end for

      'expect a single piece of content, or several (as an associative array)
    else if type(contentToTranslate) = "roAssociativeArray"

      'expect this to happen just for the search API
      if contentToTranslate.children <> invalid
        node_count = m.translateRecursive(contentToTranslate, translated)

        'expect this to happen for history/queue content
      else
        for each content in contentToTranslate
          if contentToTranslate[content] <> invalid
            node = translated.createChild("TubiContentNode")
            node_count = node_count + m.translateRecursive(contentToTranslate[content], node)
          end if
        end for
      end if
    end if
  end if

  m.setTotalCount(translated)
  tubiLog("TranslateMetadata converted " + stri(node_count) + " nodes")
  return translated
End Function


'//::TODO:: Remove this function and references once we have API support
Function tubiMetadataTranslate_buildUtilityCategoryAA(containers)

  updateMetadata = {
    id: "utility"
    slug: "utility"
    title: ""
    description: ""
    totalCount: 0
    offset: m.constants.performance.categoryGridList.initialBlockSize
    validUntil: 0
    json: ""
    state: "full"
    gridItemType: m.constants.ui.gridItemTypes.utility
    type: m.contentTypes.utility
  }

  jsonAA = {}
  validCount = 0
  children = []
    
  children.append(containers)
  children.SortBy("title")
  
  updateMetadata.children = []

  sType = "UtilityContentNode"
  
  if m.experimentInfo <> invalid
    if m.experimentInfo.has_tvshows = true
      childAA = {
        id: "u_tvshows"
        title: "TV Shows"
        description: "Tune in to thousands of binge worthy TV shows, docuseries and reality TV. New shows added monthly, you’ll never run out."
        subtype: sType
        gridItemType : "utility"
      }
      childAA.type = "u"
      jsonAA[childAA.id] = childAA
      validCount += 1
      updateMetadata.children.push(childAA)
    end if
    
    if m.experimentInfo.has_movies = true
      childAA = {
        id: "u_movies"
        title: "Movies"
        description: "Movie magic starts here with thousands of nostalgic favorites and recent box office hits. New movies added monthly, no movie ticket required."
        subtype: sType
        gridItemType : "utility"
      }
      childAA.type = "u"
      jsonAA[childAA.id] = childAA
      validCount += 1
      updateMetadata.children.push(childAA)
    end if    
  end if

  for each child in children
    
    if m.constants.ui.categoryList.Lookup(child.id) <> invalid

      ' TODO: FIND A BETTER WAY TO SOLVE THE u_continue_watching issue
      ' We artificially prepend a "u_" to the category id so that when doing a .findNode(), the
      ' continue_watching category and continue watching pill have a unique ids.
      childId = child.id
      if child.id = "continue_watching"
        childId = "u_" + child.id
      end if
    
      childAA = {
        id: childId
        title: child.title
        description: child.description
        subtype: sType
        gridItemType : "utility"
      }
      child.type = "u"
      jsonAA[childAA.id] = child
      validCount += 1
      updateMetadata.children.push(childAA)
    end if
    
  end for
  
  if validCount = 0
    return invalid
  end if

  updateMetadata.totalCount = validCount
  updateMetadata.json = FormatJSON(jsonAA)

  return updateMetadata
End Function


Function tubiMetadataTranslate_buildContinueWatchingSignedOutUserCategoryAA(container, bKidsMode = false)
  updateMetadata = {}
  if container <> invalid
    updateMetadata = {
      id: container.id
      slug: container.slug
      title: container.title
      description: container.description
      totalCount: 0
      offset: m.constants.performance.categoryGridList.initialBlockSize
      validUntil: 0
      json: ""
      state: "full"
      gridItemType: m.constants.ui.gridItemTypes.historySignedOutUser
      type: m.contentTypes.historySignedOutUser
    }

    jsonAA = {}
    validCount = 0
    children = []

    sTitle = getTranslation("metadata_continueWatching_notSignedIn_title")
    sDescription = getTranslation("metadata_continueWatching_notSignedIn_description")  

    childAA = {
      id: m.constants.ui.contentTypes.historySignedOutUser
      subtype: "TubiContentNode"
      type: "cwso"
      title: sTitle
      description: sDescription
      gridItemType: m.constants.ui.gridItemTypes.historySignedOutUser
    }
    if bKidsMode = true
      '//If kids mode is on, then images should be kidsMode versions
      childAA.hdgridposterurl = m.constants.urls.continueWatchingItemBackground_kidsMode 
    else
      '//Otherwise images should be default versions
      childAA.hdgridposterurl = m.constants.urls.continueWatchingItemBackground
    end if 

    validCount += 1
    updateMetadata.children = CreateObject("roArray", 1, false)
    updateMetadata.children.push(childAA)
    jsonAA[childAA.id] = childAA

    updateMetadata.totalCount = validCount
    updateMetadata.json = FormatJSON(jsonAA)

  end if
  return updateMetadata
End Function


Function tubiMetadataTranslate_translateChannel(contentToTranslate)
  translated = CreateObject("roSGNode", "CategoryContentNode")
  fetchedAt = m.fetchedAtTimestamp()
  node_count = 0
  container = contentToTranslate.container
  if container <> invalid
    sTitle = container.title
    if container.id = m.constants.ui.categoryIds.queue 
      '//::HARDCODE:: this is a temporary hardcode until the backend is ready to play My List Instead of Queue as the title
      sTitle = "My List"
    end if
    translated.id = container.id
    translated.title = sTitle
    translated.description = container.description
    translated.offset = 0
    translated.json = ""
    translated.state = "loaded"
    translated.logoUri = container.logo
    translated.type = m.contentTypes.channel
    translated.slug = container.slug

    if container.valid_duration <> invalid
      translated.validUntil = Uptime(0) + container.valid_duration
    else
      translated.validUntil = Uptime(0) + m.constants.cacheTimes.category
    end if

    for i=0 to container.children.count()-1
      child = contentToTranslate.contents[contentToTranslate.container.children[i]]
      node = translated.createChild("TubiContentNode")
      node_count += m.translateRecursive(child, node)
    end for
  end if
  m.setTotalCount(translated)
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


' @container: assocArray, an AA version of the container as parsed from matrix/homescreen API
' @orientation: string, "landscape" or "portrait"
' @constants: assocArray, m.constants
' returns: string, one of the gridItemTypes as found in m.constants.ui.gridItemTypes
Function tubiMetadataTranslate_getGridItemType(container, orientation, constants)
  gridItemType = constants.ui.gridItemTypes.portrait
  if container.type = constants.ui.categoryTypes.preview
    if constants.deviceInfo.limitedUI <> true
      gridItemType = constants.ui.gridItemTypes.vitg_large
    end if
  else if container.type = constants.ui.categoryTypes.linear
    gridItemType = constants.ui.gridItemTypes.linear  
  else if container.id = constants.ui.categoryIds.featured and orientation <> constants.ui.gridItemTypes.portrait
    gridItemType = constants.ui.gridItemTypes.landscape
  else if container.type = constants.ui.categoryTypes.utility
    gridItemType = constants.ui.gridItemTypes.utility  
  end if
  
  return gridItemType
End Function