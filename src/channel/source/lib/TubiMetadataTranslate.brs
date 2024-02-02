Function TubiMetadataTranslate(constants, experiments = invalid)
  return {
    ' public
    translateBackendTypeToClientSideType: tubiMetadataTranslate_translateBackendTypeToClientSideType
    translateRecursive: tubiMetadataTranslate_translateRecursive
    getContentFromCategoryJson: tubiMetadataTranslate_getContentFromCategoryJson
    translateRelatedContent: tubiMetadataTranslate_translateRelatedContent
    translate: tubiMetadataTranslate_translate
    translateContainer: tubiMetadataTranslate_translateContainer
    translateCategoryDetails: tubiMetadataTranslate_translateCategoryDetails
    translateFIFAHomescreen: tubiMetadataTranslate_translateFIFAHomescreen
    translateHomescreen: tubiMetadataTranslate_translateHomescreen
    translateCategoriesListScreen: tubiMetadataTranslate_translateCategoriesListScreen
    translateEPGChannelIds: tubiMetadataTranslate_translateEPGChannelIds
    translateEPGPrograms: tubiMetadataTranslate_translateEPGPrograms
    translateEmptyMyStuffContainer: tubiMetadataTranslate_translateEmptyMyStuffContainer
    translateTournamentScreen: tubiMetadataTranslate_translateTournamentScreen
    upNextTranslateRecursiveWrapper: tubiMetadataTranslate_upNextTranslateRecursiveWrapper
    setDescriptorCodeAndDescription: tubiMetadataTranslate_setDescriptorCodeAndDescription
    translateProgram: tubiMetadataTranslate_translateProgram

    ' private
    constants: constants
    contentTypes: constants.ui.contentTypes
    creditsDuration: constants.player.creditsDuration
    allowAfterHours: constants.settings.allowAfterHours
    experiments: experiments

    dedupeBackgrounds: tubiMetadataTranslate_dedupeBackgrounds
    setTotalCount: tubiMetadataTranslate_setTotalCount
    setSponsorshipInfo: tubiMetadataTranslate_setSponsorshipInfo
    getContentsJson: tubiMetadataTranslate_getContentsJson
    buildCategoryAA: tubiMetadataTranslate_buildCategoryAA
    buildCategoryAAWithInsert: tubiMetadataTranslate_buildCategoryAAWithInsert
    buildCategoryParentInfo: tubiMetadataTranslate_buildCategoryParentInfo
    buildCategoryChildrenInfo: tubiMetadataTranslate_buildCategoryChildrenInfo
    buildEmptyMyStuffCategoryAA: tubiMetadataTranslate_buildEmptyMyStuffCategoryAA
    buildContinueWatchingSignedOutUserCategoryAA: tubiMetadataTranslate_buildContinueWatchingSignedOutUserCategoryAA
    generateChannelPosterUrl: tubiMetadataTranslate_generateChannelPosterUrl
    fetchedAtTimestamp: tubiMetadataTranslate_fetchedAtTimestamp
    getGridItemType: tubiMetadataTranslate_getGridItemType
    getThumbnailImage: tubiMetadataTranslate_getThumbnailImage
    composeVideoResources: tubiMetadataTranslate_composeVideoResources
    getRoundedCornersURL: tubiMetadataTranslate_getRoundedCornersURL
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
  if metadata.totalCount = -1 AND metadata.getChildCount() <> 0 then
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
  gridItemTypes = m.constants.ui.gridItemTypes
  if gridType = ""
    gridType = gridItemTypes.portrait
  end if

  if gridType = gridItemTypes.portrait
    if canvasImages <> invalid AND type(canvasImages.poster_tb) = "roArray" AND isNonEmptyString(canvasImages.poster_tb[0]) = true
      '//A custom portrait size was requested, use this image instead of the default image
      sThumbnailURL = canvasImages.poster_tb[0]
    else if contentFromServer.posterarts <> invalid AND isNonEmptyArray(contentFromServer.posterarts) = true
      sThumbnailURL = contentFromServer.posterarts[0]
    else if isNonEmptyArray(contentFromServer.thumbnails) = true
      sThumbnailURL = contentFromServer.thumbnails[0]
    end if
  else if gridType = gridItemTypes.landscape OR gridType = gridItemTypes.landscapeNoTitle OR gridType = gridItemTypes.landscapeInnerMetadata
    if canvasImages <> invalid AND type(canvasImages.hero_tb) = "roArray" AND isNonEmptyString(canvasImages.hero_tb[0])
      '//A custom hero size was requested, use this image instead of the default image
      sThumbnailURL = canvasImages.hero_tb[0]
    else if canvasImages <> invalid AND type(canvasImages.landscape_tb) = "roArray" AND isNonEmptyString(canvasImages.landscape_tb[0])
      '//A custom landscape size was requested, use this image instead of the default image
      sThumbnailURL = canvasImages.landscape_tb[0]
    else if isNonEmptyArray(contentFromServer.hero_images) = true
      sThumbnailURL = contentFromServer.hero_images[0]
    else if contentFromServer.type = "l" 'linear content in non-linear row
      sThumbnailURL = contentFromServer.landscape_images[0] 'default channel image
    else if isNonEmptyArray(contentFromServer.thumbnails) = true
      sThumbnailURL = contentFromServer.thumbnails[0]
    end if
  else if gridType = gridItemTypes.linear
    if isNonEmptyArray(contentFromServer.landscape_images)
      sThumbnailURL = contentFromServer.landscape_images[0]
    end if
  end if

  '//Ensure thumbnails have rounded corners - will only work with Tupian URLs
  sThumbnailURL = m.getRoundedCornersURL(sThumbnailURL)

  return sThumbnailURL
End Function


'''''''''''''''''''''
' translateBackendTypeToClientSideType
'
' Translate the backend type into a more readable client side content type
Function tubiMetadataTranslate_translateBackendTypeToClientSideType(sBackendType = "" as String) as String
  sReturn = ""
  if sBackendType = "c"
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
  else if sBackendType = "se"
    sReturn = m.contentTypes.sportsEvent
  else if sBackendType = "n"
    sReturn = m.contentTypes.navigate
  end if

  return sReturn
End Function


' Convert the URL to that of a URL with rounded corners
Function tubiMetadataTranslate_getRoundedCornersURL(sPosterURL)

  sPosterURL = replaceURLParameter(sPosterURL, "border_radius", "default", true)
  '//::TODO::roku_rounded_corners_v1 - linear thumbnails with a border_radius=8 are cached in the CDN with square corners.
  '// So we are setting the border_radius param to "normal" (which is the same thing as "8") to ensure we display rounded corners and not worry about the cached version of the border_radius=9 URL
  '//   When linear thumnails come from Tupian (sometime in October 2023), then we can set the border radius back to "8" instead of "default", and then we should see the rounded corners.
  ' sPosterURL = replaceURLParameter(sPosterURL, "border_radius", "8", true)

  return sPosterURL
End Function


'''''''''''''''''''''
' translateRecursive
'
' This is a recursive function that does the heavy lifting for translateContentFromServer
' This function has the side effect of updating the translatedContent object that is passed in.
' Pass in an AA as the translatedContent argument if using the .update() function later.
'
' @contentFromServer: assocArray, AA representation of content metadata JSON as returned from server
' @translatedContent: empty ContentNode or AA that will be populated with content metadata
' @isSignedInUser: boolean, value based on user logged In or not
Function tubiMetadataTranslate_translateRecursive(contentFromServer As Object, translatedContent As Object, isSignedInUser = false) as integer
  if contentFromServer = invalid or type(contentFromServer) <> "roAssociativeArray" then return 0

  count = 1
  if contentFromServer.id <> invalid then translatedContent.id = contentFromServer.id
  typeVar = "type"

  if contentFromServer[typeVar] <> invalid
    sType = contentFromServer[typeVar]
    if contentFromServer[typeVar] <> m.constants.ui.contentTypes.emptyContainer
      sType = m.translateBackendTypeToClientSideType(contentFromServer[typeVar])
    end if
    translatedContent[typeVar] = sType

    if sType = m.contentTypes.series
      ' prefix "0" to series
      if translatedContent.id <> "" then translatedContent.id = "0" + translatedContent.id
    else if sType = m.contentTypes.season
      ' prefix "0" to series
      if translatedContent.id <> "" then translatedContent.id = "0" + translatedContent.id
    end if
  end if

  if type(translatedContent) = "roSGNode"
    'record keeping needed for adding series to bookmarks and previously viewed

    ' NOTE: getParent() can return invalid due to Rendezvous error.  If it's the root TubiContentNode
    '       it will by default have a parent of this Task node.  Apparently there is a rendezvous copy
    '       of the parent task node made when getParent() is called, and that can end up being invalid
    '       if the primary thread is stuck.

    parent = translatedContent.getParent()
    parentWhiteList = {}
    parentWhiteList[m.constants.ui.contentTypes.series] = true
    parentWhiteList[m.constants.ui.contentTypes.season] = true

    if parent <> invalid AND parent.type <> invalid AND parentWhiteList.DoesExist(parent.type) then
      if parent.parentId <> invalid AND parent.parentId <> "" then
        translatedContent.parentId = parent.parentId
      else
        translatedContent.parentId = parent.id
      end if

      'this happens on deep link with mediaType = episode
      if contentFromServer.series_id <> invalid
        translatedContent.parentId = "0" + contentFromServer.series_id
      end if

      if parent.parentType <> invalid AND parent.parentType <> "" then
        translatedContent.parentType = parent.parentType
      else
        translatedContent.parentType = parent[typeVar]
      end if

      if parent.parentTitle <> invalid AND parent.parentTitle <> "" then
        translatedContent.parentTitle = parent.parentTitle
      else
        translatedContent.parentTitle = parent.title
      end if

      if parent.parentHistoryId <> invalid AND parent.parentHistoryId <> "" then
        translatedContent.parentHistoryId = parent.parentHistoryId
      else if parent.historyId <> invalid AND parent.historyId <> ""
        translatedContent.parentHistoryId = parent.historyId
      end if

      ' episodes may not be marked as CDC (Child Directed Content) even if the parent series is,
      ' so make sure all episodes are marked as CDC.
      if parent.isCdc <> false
        translatedContent.isCdc = parent.isCdc
      else if contentFromServer.is_cdc <> invalid
        translatedContent.isCdc = contentFromServer.is_cdc
      end if

    else if contentFromServer.series_id <> invalid
      translatedContent.parentId = "0" + contentFromServer.series_id

    else
      translatedContent.parentId = invalid
    end if
  end if

  'translate all the stuff from the server
  translatedContent.length = 0
  if contentFromServer.duration <> invalid then translatedContent.length = contentFromServer.duration
  if contentFromServer.title <> invalid then translatedContent.title = contentFromServer.title
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
  if contentFromServer.year <> invalid AND contentFromServer.year <> 0 then translatedContent.releaseDate = contentFromServer.year.ToStr()
  if contentFromServer.currentEpisodeId <> invalid then translatedContent.currentEpisodeId = contentFromServer.currentEpisodeId
  if contentFromServer.nowPos <> invalid then translatedContent.nowPos = contentFromServer.nowPos
  if contentFromServer.series_id <> invalid then translatedContent.seriesId = "0" + contentFromServer.series_id

  if contentFromServer.needs_login = true and isSignedInUser = false
    translatedContent.needsLogin = true
  end if

  ' in case isCdc was already set from the parent above, don't overwrite
  if translatedContent.isCdc <> true AND contentFromServer.is_cdc <> invalid
    translatedContent.isCdc = contentFromServer.is_cdc
  end if

  if contentFromServer.description <> invalid
    translatedContent.description = contentFromServer.description

    #if useQaAnalyticsProxy
      ' QA - display content ids UI tests
      if m.constants.settings.mode = "qa"
        translatedContent.description = translatedContent.id + " " + contentFromServer.description
      end if
    #end if
  end if

  if contentFromServer.directors <> invalid AND contentFromServer.directors.count() > 0
    translatedContent.directors = contentFromServer.directors
  end if

  roundGroupInfo = ""
  league = contentFromServer.league
  if league <> invalid AND league.round <> invalid
    roundGroupInfo += league.round
    if league.round = "Group Stage" ' hack for world cup
      teams = contentFromServer.teams
      if isNonEmptyArray(teams) = true AND teams[0].group <> invalid
        roundGroupInfo += " " + Chr(&hb7) + " " + teams[0].group
      end if
    end if
  end if

  if contentFromServer.type = "se"
    if type(translatedContent) = "roSGNode"
      translatedContent.addField("roundGroupInfo", "string", false)
    end if
    translatedContent.roundGroupInfo = roundGroupInfo
  end if

  creditCuePoints = {}
  postlude = 0

  if contentFromServer.credit_cuepoints <> invalid
    'adding creditCuePoints for episide to implement SkipIntro feature for episode
    if contentFromServer.detailed_type = "episode"
      creditCuePoints = contentFromServer.credit_cuepoints
    end if
    if contentFromServer.credit_cuepoints.postlude <> invalid
      postlude = contentFromServer.credit_cuepoints.postlude
    end if
  end if

  'add default credit cuepoints if missing, or skip it if content is very short
  if postlude = 0 AND translatedContent.length > m.creditsDuration
    cuePoint = translatedContent.length - m.creditsDuration
    if cuePoint >= 0
      postlude = cuePoint
    end if
  end if

  ' if credits duration is less than m.creditsDuration, force it to be at least that long
  if postlude > 0 AND (translatedContent.length - postlude) < m.creditsDuration
    cuePoint = translatedContent.length - m.creditsDuration
    if cuePoint >= 0
      postlude = cuePoint
    else
      ' if the cuepoint was adjusted, but it ended up being negative
      postlude = 0
    end if
  end if

  ' Rounding the value to down for all the end creditcuepoints
  earlycredits_end = creditCuePoints.earlycredits_end
  if earlycredits_end <> invalid AND earlycredits_end > 0
    creditCuePoints.AddReplace("earlycredits_end", roundDown(earlycredits_end))
  end if

  intro_end = creditCuePoints.intro_end
  if intro_end <> invalid AND intro_end > 0
    creditCuePoints.AddReplace("intro_end", roundDown(intro_end))
  end if

  recap_end = creditCuePoints.recap_end
  if recap_end <> invalid AND recap_end > 0
    creditCuePoints.AddReplace("recap_end", roundDown(recap_end))
  end if

  ' Rounding the value to up for all the start creditcuepoints
  if postlude <> invalid AND postlude > 0
    postlude = roundUp(postlude)
  end if

  prelogue = creditCuePoints.prelogue
  if prelogue <> invalid
    creditCuePoints.AddReplace("prelogue", roundUp(prelogue))
  end if

  earlycredits_start = creditCuePoints.earlycredits_start
  if earlycredits_start <> invalid AND earlycredits_start > 0
    creditCuePoints.AddReplace("earlycredits_start", roundUp(earlycredits_start))
  end if

  intro_start = creditCuePoints.intro_start
  if intro_start <> invalid AND intro_start > 0
    creditCuePoints.AddReplace("intro_start", roundUp(intro_start))
  end if

  recap_start = creditCuePoints.recap_start
  if recap_start <> invalid AND recap_start > 0
    creditCuePoints.AddReplace("recap_start", roundUp(recap_start))
  end if

  creditCuePoints.AddReplace("postlude", postlude)
  translatedContent.creditCuePoints = creditCuePoints

  sLandscapeURL = m.getThumbnailImage(contentFromServer, m.constants.ui.gridItemTypes.landscape)
  translatedContent.landscape = sLandscapeURL

  sPortraitURL = m.getThumbnailImage(contentFromServer)
  if sPortraitURL <> ""
    translatedContent.portrait = sPortraitURL
    translatedContent.HDGRIDPOSTERURL = sPortraitURL
  end if

  if (translatedContent.HDGRIDPOSTERURL = invalid or translatedContent.HDGRIDPOSTERURL = "") AND contentFromServer.HDGRIDPOSTERURL <> invalid
    '//If the contentFromServer already set HDGRIDPOSTERURL then use that value.
    sHDGridPosterURL = m.getRoundedCornersURL(contentFromServer.HDGRIDPOSTERURL)
    translatedContent.HDGRIDPOSTERURL = sHDGridPosterURL
  end if

  if contentFromServer.backgrounds <> invalid AND type(contentFromServer.backgrounds) = "roArray" AND contentFromServer.backgrounds.count() > 0
    translatedContent.backgrounds = m.dedupeBackgrounds(contentFromServer.backgrounds)
  end if

  if contentFromServer.ratings <> invalid AND contentFromServer.ratings[0] <> invalid AND contentFromServer.ratings[0].value <> invalid
    translatedContent.rating = contentFromServer.ratings[0].value

    rating = translatedContent.rating
    if (rating = "R" OR rating = "TV-MA" OR rating = "TV-14" OR rating = "NC-17" OR rating = "NR") AND m.constants.deviceinfo.countrycode = "US" AND translatedContent[typeVar] <> m.contentTypes.linear AND isSignedInUser = false AND m.experiments <> invalid AND m.experiments.getExperimentResource("roku_registration_vs_tvt_lock_rated_content", "roku_registration_vs_tvt_lock_rated_content_v1").enabled = true
      translatedContent.needsLogin = true
    end if

    if contentFromServer.ratings[0].descriptors <> invalid AND contentFromServer.ratings[0].descriptors.Count() > 0
      m.setDescriptorCodeAndDescription(translatedContent, contentFromServer.ratings[0].descriptors)
    end if
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
  if contentFromServer.monetization <> invalid AND contentFromServer.monetization.cue_points <> invalid
    translatedContent.cuepoints = contentFromServer.monetization.cue_points
  end if

  ' DRM encoded streams
  translatedContent.videoResources = m.composeVideoResources(translatedContent, contentFromServer)

  'take care of any subtitles if they exist - should only happen on videos
  if contentFromServer.has_subtitle <> invalid then translatedContent.hasSubtitles = contentFromServer.has_subtitle

  ' compare list of renditions to device and environment capabilities to get the highest rendition
  if contentFromServer.video_renditions <> invalid
    ' for now, only worry about 4k
    if contentFromServer.video_renditions[0] = m.constants.serverValues.tensorVideoRenditions.fourK
      if m.constants.deviceInfo.videoMode.toInt() >= 2160
        translatedContent.highestRendition = m.constants.serverValues.tensorVideoRenditions.fourK
      end if
    end if
  end if

  ' linear subtitles
  if translatedContent[typeVar] = m.contentTypes.linear AND translatedContent.hasSubtitles = true
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
  else if contentFromServer.subtitles <> invalid AND type(contentFromServer.subtitles) = "roArray" AND contentFromServer.subtitles.count() > 0
    '//subtitles for non-linear video
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


  if translatedContent[typeVar] = m.contentTypes.linear
    if contentFromServer.thumbnails <> invalid
      translatedContent.inlineLogoUri = contentFromServer.thumbnails[0]
    end if
  end if

  ' trailers
  if contentFromServer.trailers <> invalid AND type(contentFromServer.trailers) = "roArray" AND contentFromServer.trailers.count() > 0
    trailerInfo = contentFromServer.trailers[0]

    if trailerInfo <> invalid AND isNonEmptyString(trailerInfo.url)

        if Lcase(trailerInfo.url).instr(1, ".mpd") > 0
          trailerInfo.streamFormat = "dash"
          translatedContent.trailerInfo = trailerInfo
        else if Lcase(trailerInfo.url).instr(1, ".m3u8") > 0
          trailerInfo.streamFormat = "hls"
          translatedContent.trailerInfo = trailerInfo
        end if
    end if
  end if

  if contentFromServer.has_trailer = true then translatedContent.hasTrailer = true

  ' video preview
  if contentFromServer.video_preview_url <> invalid
    translatedContent.videoPreviewUrl = contentFromServer.video_preview_url
  end if

  'if this content is actually just a paginated response, set pagination data
  if contentFromServer.total_count <> invalid then translatedContent.totalCount = contentFromServer.total_count

  ' Channels
  if contentFromServer.channel_id <> invalid then translatedContent.channelId = contentFromServer.channel_id
  if contentFromServer.channel_logo <> invalid then translatedContent.inlineLogoUri = contentFromServer.channel_logo
  if contentFromServer.channel_name <> invalid then translatedContent.channelName = contentFromServer.channel_name

  if contentFromServer.is_recurring <> invalid then translatedContent.isRecurring = contentFromServer.is_recurring
  if contentFromServer.availability_ends <> invalid then translatedContent.availabilityEnds = contentFromServer.availability_ends
  if contentFromServer.air_datetime <> invalid then translatedContent.airDateTime = contentFromServer.air_datetime

  hasVideoResources = false
  if contentFromServer.has_video_resources = true
    hasVideoResources = true
  else if type(contentFromServer.video_resources) = "roArray" AND contentFromServer.video_resources.count() > 0
    hasVideoResources = true
  end if
  translatedContent.hasVideoResources = hasVideoResources

  'set the time past which the content metadata should be refreshed from the server
  if contentFromServer.valid_duration <> invalid
    translatedContent.validUntil = UpTime(0) + contentFromServer.valid_duration
  else
    translatedContent.validUntil = UpTime(0) + m.constants.cacheTimes.content
  end if

  'take care of any children the content might have
  if contentFromServer.children <> invalid AND contentFromServer.children.count() > 0

    if translatedContent.totalCount = -1
      translatedContent.totalCount = contentFromServer.children.count()
    end if

    for each childContentFromServer in contentFromServer.children
      if type(translatedContent) = "roSGNode"
        translatedChild = translatedContent.createChild("TubiContentNode")
        count = count + m.translateRecursive(childContentFromServer, translatedChild, isSignedInUser)
      else if type(translatedContent) = "roAssociativeArray"
        translatedChild = CreateObject("roAssociativeArray")
        count = count + m.translateRecursive(childContentFromServer, translatedChild, isSignedInUser)

        if translatedContent.children = invalid
          translatedContent.children = []
        end if

        translatedContent.children.push(translatedChild)
      end if
    end for
  else if contentFromServer.type = "l" AND contentFromServer.programs <> invalid AND contentFromServer.programs.count() > 0

    programs = contentFromServer.programs
    programCount = programs.count()

    if translatedContent.totalCount = -1
      translatedContent.totalCount = programCount
    end if

    if type(translatedContent) = "roSGNode"
      for i = 0 to programCount - 1
        programFromServer = programs[i]

        if programFromServer <> invalid
          translatedChild = translatedContent.createChild("EPGContentNode")
          m.translateProgram(contentFromServer, programFromServer, translatedChild, m.constants.ui.screenIds.homeScreen, isSignedInUser)
          count = count + 1
        end if
      end for
    else if type(translatedContent) = "roAssociativeArray"

      if translatedContent.children = invalid
        translatedContent.children = []
      end if

      for i = 0 to programCount - 1
        programFromServer = programs[i]

        if programFromServer <> invalid
          translatedChild = CreateObject("roAssociativeArray")
          m.translateProgram(contentFromServer, programFromServer, translatedChild, m.constants.ui.screenIds.homeScreen, isSignedInUser)
          count = count + 1
          translatedContent.children.push(translatedChild)
        end if
      end for
    end if
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
' @isSignedInUser: boolean, value based on user logged In or not
Function tubiMetadataTranslate_getContentFromCategoryJson(category, contentId, isSignedInUser = false)
  if category <> invalid AND category.json <> invalid AND category.json <> ""
    parsed = ParseJson(category.json)
    if parsed <> invalid
      fullContent = parsed[contentId]
      translated = CreateObject("roSGNode", "TubiContentNode")
      m.translateRecursive(fullContent, translated, isSignedInUser)
      translated.parentId = category.id
      translated.parentType = category.type
      translated.parentTitle = category.title

      if category.gridItemType = m.constants.ui.gridItemTypes.historySignedOutUser
        translated.backgrounds = [m.constants.ui.uris.defaultContentBackgroundUri]
      end if


      ' QA - inject the category slug into the content description for automated UI testing
      #if useQaAnalyticsProxy
        if m.constants.settings.mode = "qa"
          translated.description = category.id + " " + translated.description
        end if
      #end if
      return translated
    end if
  end if
  return invalid
End Function


''''''''''''''''''''''
' translateRelatedContent
'
' Expect content from the /related API, structured as an array of assocarrays
' @contentFromServer: assocArray, AA representation of content metadata JSON as returned from server
' @isSignedInUser: boolean, value based on user logged In or not
Function tubiMetadataTranslate_translateRelatedContent(contentFromServer, isSignedInUser = false)
  translated = CreateObject("roSGNode", "CategoryContentNode")
  if type(contentFromServer) = "roArray"
    shortestValidDuration = invalid
    for each content in contentFromServer
      node = translated.createChild("TubiContentNode")
      m.translateRecursive(content, node, isSignedInUser)

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


' @contentToTranslate: AA, json parsed response from the matrix/homescreen endpoint
' @contentMode: string, the value of the contentMode parameter as sent as part of the matrix/homescreen request
' @isKidsMode: boolean, the value of the isKidsMode parameter as sent as part of the matrix/homescreen request
' @uiMode: string, one of the allowed values from constants.ui.modes
' @isSignedInUser: boolean, value based on user logged In or not
Function tubiMetadataTranslate_translateFIFAHomescreen(contentToTranslate, contentMode="homescreen", isKidsMode=false, uiMode="standard", isSignedInUser = false) As Object
  tubiLog("TubiMetadataTranslate tubiMetadataTranslate_translateFIFAHomescreen()")
  translated = m.translateHomescreen(contentToTranslate, contentMode, isKidsMode, uiMode, "homeScreen", isSignedInUser)
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
'//::TODO:: Remove the contentMode, isSignedInUser & isKidsMode parameters once we have API support
'
' @contentToTranslate: AA, json parsed response from the matrix/homescreen endpoint
' @contentMode: string, the value of the contentMode parameter as sent as part of the matrix/homescreen request
' @isKidsMode: boolean, the value of the isKidsMode parameter as sent as part of the matrix/homescreen request
' @uiMode: string, one of the allowed values from constants.ui.modes
' @screenId: string, the id of the screen
' @isSignedInUser: boolean, value based on user logged In or not
Function tubiMetadataTranslate_translateHomescreen(contentToTranslate, contentMode="homescreen", isKidsMode=false, uiMode="standard", screenId="", isSignedInUser = false) As Object
  tubiLog("TubiMetadataTranslate tubiMetadataTranslate_translateHomescreen()")

  translated = CreateObject("roSGNode", "CategoryContentNode")
  homescreenAA = {
    id: m.constants.ui.contentIds.homegrid
    title: ""
    validUntil: 0
    children: []    'categories
  }

  if contentToTranslate <> invalid
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

    'set up AAs for all categories
    for i=0 to containers.count()-1
      container = containers[i]
      if container.id = m.constants.ui.categoryIds.history
        continueWatchingIndex = i
      else if container.id = m.constants.ui.categoryIds.queue
        queueIndex = i
      end if

      categoryAA = invalid
      if container.id = m.constants.ui.categoryIds.history AND isSignedInUser = false AND uiMode <> m.constants.ui.modes.kidsAgeGate
        '//if continue watching container while user is signed out,
        ' then ensure row is empty except for 1 item that will entice users to sign in
        categoryAA = m.buildContinueWatchingSignedOutUserCategoryAA(container, isKidsMode)
      else
        categoryAA = m.buildCategoryAAWithInsert(container, contents, "", "", false, contentMode, screenId, isSignedInUser, uiMode)
      end if

      if categoryAA <> invalid
        homescreenAA.children.push(categoryAA)
      end if
    end for

    translated.update(homescreenAA, true)
    translated.addField("continueWatchingIndex", "integer", false)
    translated.addField("queueIndex", "integer", false)
    translated.continueWatchingIndex = continueWatchingIndex
    translated.queueIndex = queueIndex
    node_count = 1 + translated.getChildCount()
    tubiLog("TranslateMetadata converted " + stri(node_count) + " nodes")
  end if

  return translated
End Function


''''''''''''''''''''
' translateCategoriesListScreen
'
' Translate a response from matrix/categories or matrix/channels for use in ChannelGridScreen
Function tubiMetadataTranslate_translateCategoriesListScreen(contentToTranslate, bDisplayChannels = true) As Object
  tubiLog("TubiMetadataTranslate tubiMetadataTranslate_translateCategoriesListScreen()")
  sID_queue = m.constants.ui.categoryIds.queue
  sID_continue_watching = m.constants.ui.categoryIds.history

  screenContentId = ""
  oLimitTypes = {}
  if bDisplayChannels = true
    oLimitTypes[m.constants.ui.categoryTypes.channel] = true
    screenContentId = m.constants.ui.contentIds.channelList
  else
    oLimitTypes[m.constants.ui.categoryTypes.regular] = true
    oLimitTypes[m.constants.ui.categoryTypes.history] = true
    oLimitTypes[m.constants.ui.categoryTypes.queue] = true
    screenContentId = m.constants.ui.contentIds.categoryList
  end if

  catRecommend = invalid
  catContinueWatching = invalid
  catQueue = invalid

  '//The following is a modifed version of the tubiMetadataTranslate_translateHomescreen() method
  translated = CreateObject("roSGNode", "CategoryContentNode")
  homescreenAA = {
    id: screenContentId
    title: ""
    validUntil: 0
    children: []    'categories
  }

  if contentToTranslate.valid_duration <> invalid
    homescreenAA.validUntil = Uptime(0) + contentToTranslate.valid_duration
  else
    homescreenAA.validUntil = Uptime(0) + m.constants.cacheTimes.homescreen
  end if

  containers = contentToTranslate.browser_list

  '//The following code adds a transparency to the thumbnails and for categories, it shifts a few categories to the top of the list
  '//::HARDCODED:: If this is categories, then place few categories in the front and get rid of featured
  '//::TODO:: have the backend filter and sort categories when they have more bandwidth
  'set up AAs for all categories including any nested categories

  for i=0 to containers.count()-1
    container = containers[i]

    if oLimitTypes[container.type] = true
      categoryAA = m.buildCategoryParentInfo(container)  'categoryAA is invalid if empty container
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

        validContainer = true
        ' do not show the containers on Category screen which has landscape images on it
        if m.constants.ui.notAllowedContainerIds[sID] = true
          validContainer = false
        end if

        if validContainer = true
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
' @contentToTranslate: AA, json parsed response from the matrix/homescreen endpoint
' @fullJson: string, the full JSON of the /container API response
' @sOrientation: string, should the thumbnail be a "portrait" or "landscape" (match against m.constants.ui.gridItemTypes values)
' @bFullData: boolean, Should the full data be parsed and passed to the video children?
' @contentNode: TubiContentNode
' @screenId: string, the id of the screen
' @isSignedInUser: boolean, value based on user logged In or not
' @isKidsMode: boolean, the value of the isKidsMode parameter as sent as part of the matrix/homescreen request
' @uiMode: string, one of the allowed values from constants.ui.modes
'
Function tubiMetadataTranslate_translateContainer(contentToTranslate, fullJson, sOrientation = "", bFullData = false, contentMode="homeScreen", screenId="", isSignedInUser = false, isKidsMode=false, uiMode="standard") As Object
  tubiLog("TubiMetadataTranslate.translateContainer")
  translated = CreateObject("roSGNode", "CategoryContentNode")
  container = contentToTranslate.container
  contents = contentToTranslate.contents
  contentsJson = m.getContentsJson(contentToTranslate, fullJson)

  nodeCount = 0

  if container.id = m.constants.ui.categoryIds.history AND isSignedInUser = false AND uiMode <> m.constants.ui.modes.kidsAgeGate
    '//if continue watching container while user is signed out,
    ' then ensure row is empty except for 1 item that will entice users to sign in
    categoryMetadata = m.buildContinueWatchingSignedOutUserCategoryAA(container, isKidsMode)
  else
    categoryMetadata = m.buildCategoryAAWithInsert(container, contents, contentsJson, sOrientation, bFullData, contentMode, screenId, isSignedInUser, uiMode)
  end if

  if categoryMetadata = invalid  'happens if a container has no valid content in it (ie. all content is out of window)
    translated.id = container.id
    return translated
  end if

  if type(categoryMetadata) = "roAssociativeArray"
    ' buildCategoryAA always returns AA.state = "partial",
    ' but any single category request should be considered fully loaded
    categoryMetadata.state = "loaded"
    translated.update(categoryMetadata, true)
    nodeCount = 1 + translated.getChildCount()
  end if

  tubiLog("TranslateMetadata converted " + stri(nodeCount) + " nodes")
  return translated
End Function


''''''''''''''''''''
' translateEmptyMyStuffContainer
'
' @contentToTranslate: assocArray, the AA resulting from JSON parsing the /container API response
Function tubiMetadataTranslate_translateEmptyMyStuffContainer(contentToTranslate) As Object
  tubiLog("TubiMetadataTranslate.translateEmptyMyStuffContainer")
  translated = CreateObject("roSGNode", "CategoryContentNode")
  container = contentToTranslate.container

  categoryMetadata = m.buildEmptyMyStuffCategoryAA(container)

  if type(categoryMetadata) = "roAssociativeArray"
    ' buildEmptyMyStuffCategoryAA always returns AA.state = "partial",
    ' but any single category request should be considered fully loaded
    categoryMetadata.state = "loaded"
    translated.update(categoryMetadata, true)
  end if

  return translated
End Function


' @contentToTranslate: assocArray, the AA resulting from JSON parsing the /container API response
' @fullJson: string, the full JSON of the /container API response
' @isSignedInUser: boolean, value based on user logged In or not
'
' @returns: roSGNode, a CategoryContentNode with children TubiContentNodes for each content in the container/category
Function tubiMetadataTranslate_translateCategoryDetails(contentToTranslate, fullJson, isSignedInUser)
  tubiLog("TubiMetadataTranslate.translateCategoryDetails")
  translated = CreateObject("roSGNode", "CategoryContentNode")
  container = contentToTranslate.container
  contents = contentToTranslate.contents
  contentsJson = ""
  sOrientation = m.constants.ui.gridItemTypes.portrait
  bFullData = true
  contentMode = m.constants.ui.contentMode.homescreen

  categoryMetadata = m.buildCategoryAA(container, contents, contentsJson, sOrientation, bFullData, contentMode, "", isSignedInUser)

  if categoryMetadata <> invalid
    translated.update(categoryMetadata)
  else if container <> invalid
    ' ensure we at least store the container id, even if there is no content
    translated.id = container.id
  end if

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
' @contentMode: string, one of the contentModes found at m.constants.ui.contentMode
' @isSignedInUser: boolean, value based on user logged In or not
' returns an associative array that can be passed to ContentNode.update() to populate the ContentNode and it's children
Function tubiMetadataTranslate_buildCategoryAA(container, contents, contentsJson = "", sOrientation = "", bFullData = false, contentMode = "homeScreen", screenId="", isSignedInUser = false)

  categoryParent = m.buildCategoryParentInfo(container, contentMode, sOrientation)

  gridItemType = m.getGridItemType(container, sOrientation, m.constants)
  categoryChildrenInfo = m.buildCategoryChildrenInfo(container, contents, contentsJson, gridItemType, bFullData, isSignedInUser)

  categoryParent.children = categoryChildrenInfo.children
  categoryParent.json = categoryChildrenInfo.contentsJson
  categoryParent.gridItemType = gridItemType
  categoryChildrenCount = categoryParent.children.count()

  ' container.cursor = invalid indicates we are dealing with response JSON
  ' from matrix/containers/:id or tensor/containers/:id endpoints.
  ' note: container.cursor = 0 for limitedUI model responses from
  ' matrix/homescreen or tensor/homescreen endpoints

  if container.cursor = invalid
    if categoryChildrenCount = 0
      ' the API returned a container with no valid contents
      return invalid
    else if categoryParent.type = m.contentTypes.channel AND categoryChildrenCount = 1
      ' the API returned a container with no valid contents but there happens to be 1 content
      ' because we inserted a content since it the catgory is a "channel"
      return invalid
    end if
  end if

  categoryParent.totalCount = categoryChildrenCount

  return categoryParent
End Function


''''''''''''''''''''''
' buildCategoryAAWithInsert
'
' It is wrapper function of buildCategoryAA.
' It prepends the content to the given container based on container ID OR container type if necessary
'
' @container: assocArray, a single container as found in the matrix API
' @contents: assocArray, a set of content meta data as found in the matrix API
' @contentsJson: string, the JSON string of just the contents portion of the matrix API
' @sOrientation: string, should the thumbnail be a "portrait" or "landscape" (match against m.constants.ui.gridItemTypes values)
' @bFullData: boolean, Should the full data be parsed and passed to the video children?
' @contentMode: string, one of the contentModes found at m.constants.ui.contentMode
' @screenId: string, one of the screenIds found at constants.ui.screenIds
' @isSignedInUser: boolean, value based on user logged In or not
' @uiMode: string, one of the allowed values from constants.ui.modes
'
' returns an associative array that can be passed to ContentNode.update() to populate the ContentNode and it's children
Function tubiMetadataTranslate_buildCategoryAAWithInsert(container, contents, contentsJson = "", sOrientation = "", bFullData = false, contentMode="homeScreen", screenId="", isSignedInUser = false, uiMode = "standard")
  categoryAA = invalid

  if container <> invalid AND container.children <> invalid
    insertContent = invalid

    childrenCount = container.children.count()

    insertPosition = -1

    if childrenCount > 0 then

      if screenId = m.constants.ui.screenIds.homeScreen AND container.id = m.constants.ui.categoryIds.fifawc
        isTournamentTime = tournamentTimeFrame()   'bs:disable-line 1001 LINT1001
        if (isTournamentTime = "duringTournament" OR isTournamentTime = "preTournament")
          ' create and add a showAll content to the contents which hold the container metadata
          insertContent = {
            id: m.constants.ui.contentIds.showAllGames
            title: "FIFA World Cup 2022" + chr(8482)
            showAllText: getTranslation("screenHome_item_showAllGames")
            type: "n"
            thumbnails: [m.constants.urls.fifaShowAllPoster]
            description: container.description
            backgrounds: [m.constants.urls.fifaShowAllBackground]
          }
          insertPosition = 0
        end if
      else if container.type = m.contentTypes.channel
        ' create and add a new content to the contents which hold the container metadata
        insertContent = {}
        insertContent.append(container)
        insertContent.delete("children")  ' need to make sure there isn't a recursion later when getContentFromCategoryJson is called
        insertContent.posterarts = [m.generateChannelPosterUrl(container.id)]
        insertPosition = 0
      end if
    end if

    if insertContent <> invalid AND insertContent.id <> invalid
      children = insertItemIntoArray(container.children, insertContent.id, insertPosition)
      container.children = children

      contentsWithPrepend = {}
      contentsWithPrepend[insertContent.id] = insertContent
      contentsWithPrepend.append(contents)
      ' force contentsJson to be regenerated with the prepended content in buildCategoryAA()
      contentsJson = invalid
      categoryAA = m.buildCategoryAA(container, contentsWithPrepend, contentsJson, sOrientation, bFullData, contentMode, screenId, isSignedInUser)
    else
      categoryAA = m.buildCategoryAA(container, contents, contentsJson, sOrientation, bFullData, contentMode, screenId, isSignedInUser)
    end if

  end if

  return categoryAA
End Function


' @container: assocArray, the container/category metadata as returned by the API, not including metadata
'                         for each child of the container/category
' @contentMode: string, one of the contentModes found at m.constants.ui.contentMode
' @sOrientation: string, should the thumbnail be a "portrait" or "landscape" (match against m.constants.ui.gridItemTypes values)
'
' @returns: assocArray, an AA that can be used with node.update() to create a TubiCategoryNode
Function tubiMetadataTranslate_buildCategoryParentInfo(container, contentMode = "homeScreen", sOrientation = "")
  updateMetadata = {}

  if type(container) = "roAssociativeArray"
    ' the metadata for the category
    sTitle = container.title

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
      gridItemType: ""
      subtext: ""
    }

    m.categorySubtexts  = {}
    m.categorySubtexts[m.constants.ui.categoryIds.recommendedForYou] = getTranslation("registration_signIn_recommended")

    if sOrientation <> "" then
      updateMetadata.gridItemType = m.getGridItemType(container, sOrientation, m.constants)
    end if

    updateMetadata = m.setSponsorshipInfo(updateMetadata, container.sponsorship)

    if container.thumbnail <> invalid
      updateMetadata.thumbnail = container.thumbnail
    end if

    updateMetadata.type = m.contentTypes.category

    if container.type = m.contentTypes.channel
      updateMetadata.type = m.contentTypes.channel
    end if

    updateMetadata.logoUri = container.logo

    ' QA - display category slug on channel/categories list pages for automated UI tests
    #if useQaAnalyticsProxy
      if m.constants.settings.mode = "qa"
        updateMetadata.title = container.slug
        updateMetadata.logoUri = ""
      end if
    #end if

    if container.valid_duration <> invalid
      updateMetadata.validUntil = Uptime(0) + container.valid_duration
    else
      updateMetadata.validUntil = Uptime(0) + m.constants.cacheTimes.category
    end if
    updateMetadata.subtext = m.categorySubtexts[container.id]

  end if

  return updateMetadata
End Function


' @container: assocArray, the container/category metadata as returned by the API, not including metadata
'                         for each child of the container/category
' @contents: assocArray, a map of content metadata as returned by the 'contents' key of API responses.
'                        Likely will include more contents than exist in the container.
' @contentsJson: string, the JSON string value for the 'contents' key of the API response. Should be
'                        the same data as @contents, only in a JSON string
' @parentGridItemType: string, the gridItemType of the parent container/category
' @bFullData: boolean, true if each child should contain full metadata, false if children should contain
'                      a limited set of metadata
' @isSignedInUser: boolean, value based on user logged In or not
'
' @returns: assocArray, an AA with keys:
'                       "children", as an array of AAs containing content metadata
'                       "contentsJson", a JSON formatted string of contents belonging to the container/category
Function tubiMetadataTranslate_buildCategoryChildrenInfo(container, contents, contentsJson, parentGridItemType, bFullData, isSignedInUser = false)
  childrenReturn = CreateObject("roArray", 0, false)

  if type(container) = "roAssociativeArray" AND type(container.children) = "roArray"
    childrenReturn = CreateObject("roArray", container.children.count(), false)

    jsonAA = {}
    if isNonEmptyString(contentsJson) = true OR bFullData = true
      ' only need to build a jsonAA if we need to replace contentsJson
      ' we don't need to if contentsJson has content already or we are giving all the children their full data
      jsonAA = invalid
    end if

    if type(contents) = "roAssociativeArray"

      for each child in container.children
        ' contents[child].valid is "true" or "false" for user categories and is invalid for all other categories.
        ' For all other categories, assume all contents are valid. Valid in this case means, the content is "in window"
        ' and allowed to be played on the Roku platform
        if contents[child] <> invalid AND contents[child].valid <> false
          childIsPushable = true
          fullChild = contents[child]

          sType = "ContentNode"
          if bFullData = true OR parentGridItemType = m.constants.ui.gridItemTypes.linear
            '//if true then set children to TubiContentNode type so more data is passed to the children
            sType = "TubiContentNode"
          end if

          hasVideoResources = false
          if fullChild.has_video_resources = true
            hasVideoResources = true
          else if type(fullChild.video_resources) = "roArray" AND fullChild.video_resources.count() > 0
            hasVideoResources = true
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

          if fullChild.showAllText <> invalid
            childAA.append({showAllText: fullChild.showAllText})
          end if
          '//TODO: REMOVE AFTER EXPERIMENT roku_registration_vs_tvt_lock_rated_content
          if fullChild.ratings <> invalid AND fullChild.ratings[0] <> invalid AND fullChild.ratings[0].value <> invalid
            rating = UCase(fullChild.ratings[0].value)
            if (rating = "R" OR rating = "TV-MA" OR rating = "TV-14" OR rating = "NC-17" OR rating = "NR") AND m.constants.deviceinfo.countrycode = "US" AND fullChild.type <> "l" AND isSignedInUser = false AND m.experiments <> invalid AND m.experiments.getExperimentResource("roku_registration_vs_tvt_lock_rated_content", "roku_registration_vs_tvt_lock_rated_content_v1").enabled = true
              childAA.needsLogin = true
            end if
          end if

          if fullChild.needs_login = true AND isSignedInUser = false
            childAA.needsLogin = true
          end if

          if hasVideoResources = true
            childAA.hasVideoResources = true
          end if

          if fullChild.air_datetime <> invalid and fullChild.air_datetime <> ""
            childAA.airDateTime = fullChild.air_datetime
          end if

          if parentGridItemType <> m.constants.ui.gridItemTypes.linear AND fullChild.type = "l" AND fullChild.programs <> invalid AND fullChild.programs.count() > 0
            bSingleContentFullData = true
          else
            bSingleContentFullData = false
          end if

          if bFullData = true OR bSingleContentFullData = true
            'mutates childAA by populating all fields on childAA
            m.translateRecursive(fullChild, childAA, isSignedInUser)
          end if

          gridType = ""
          gridItemTypes = m.constants.ui.gridItemTypes
          if gridItemTypes[parentGridItemType] <> invalid then
            gridType = parentGridItemType
          end if

          if childAA.type <> "ContentNode"
            '//if the subtype is not the default ContentNode, then set the gridItemType field
            childAA.gridItemType = gridType
          end if

          sHDGridPosterURL = m.getThumbnailImage(fullChild, gridType)
          childAA.hdgridposterurl = sHDGridPosterURL


          if parentGridItemType = gridItemTypes.linear AND fullChild.thumbnails <> invalid
            childAA.inlineLogoUri = fullChild.thumbnails[0]
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

          if childIsPushable = true and jsonAA <> invalid
            jsonAA[childAA.id] = fullChild
          end if

          childrenReturn.push(childAA)
        end if
      end for
    end if

    if jsonAA <> invalid and isNonEmptyString(contentsJson) = false
      contentsJson = FormatJSON(jsonAA)
    else if bFullData = true
      ' no need for contents Json if contents have the full data (bFullData = true)
      ' however, leave the original contentsJson if bFullData = false and contentsJson is a non empty string.
      contentsJson = ""
    end if
  end if

  return {
    children: childrenReturn
    contentsJson: contentsJson
  }
End Function


''''''''''''''''''''''
' getContentsJson
'
'helper function to encapsulate getting the contents JSON from a matrix single container response
'@parsedJson: assocArray, the container response that has already been run through ParseJSON()
'@fullJson: string, the full json formatted response
Function tubiMetadataTranslate_getContentsJson(parsedJson, fullJson)
  contentsJson = ""

  'Doing string operations to isolate the contents portion of the JSON matrix response is ~4x faster than re-formatting the JSON
  contentsIdentifier =  Chr(34) + "contents" + Chr(34) + ":{"
  safetyEject = false

  contentsIdentifierPos = Instr(1, fullJson, contentsIdentifier)

  'make sure the content key exists exactly once in the JSON string
  if contentsIdentifierPos > 0 AND Instr(contentsIdentifierPos + 1, fullJson, contentsIdentifier) < 1
    contentsStartPos = contentsIdentifierPos + contentsIdentifier.len() - 1
    contentsEndPos = fullJson.len()  'set default assuming contents is the last key in the AA json

    for each key in parsedJson
      if key <> "contents"
        keyIdentifier = Chr(34) + key + Chr(34) + ":"   ' ex: "container":  'can't guarantee AA so don't include bracket
        keyPos = Instr(1, fullJson, keyIdentifier)
        'make sure the key exists exactly once in the JSON string
        if keyPos > 0 AND Instr(keyPos + 1, fullJson, keyIdentifier) < 1
          if keyPos > contentsStartPos AND keyPos < contentsEndPos
            contentsEndPos = keyPos - 1
          end if
        else
          safetyEject = true  ' key not found, or found multiple times in string, can't be trusted
          exit for
        end if
      end if
    end for
  else
    contentsStartPos = 0
    contentsEndPos = 0
  end if

  if safetyEject = false
    contentsJson = Mid(fullJson, contentsStartPos, contentsEndPos - contentsStartPos)
  end if

  'the optimization didn't update contentsJson, so do the slower but more faithful way (FormatJSON)
  if contentsJson = invalid AND parsedJson.contents <> invalid
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
' @isSignedInUser: boolean, value based on user logged In or not
Function tubiMetadataTranslate_translate(contentToTranslate, isSignedInUser = false) As Object
  translated = CreateObject("roSGNode", "TubiContentNode")
  node_count = 0

  if contentToTranslate <> invalid
    'expect a list of categories with one category filled with content or a list of contents
    if type(contentToTranslate) = "roArray"
      for each content in contentToTranslate
        if content.title <> "After Hours" or m.allowAfterHours = true
          node = translated.createChild("TubiContentNode")
          node_count = node_count + m.translateRecursive(content, node, isSignedInUser)
        end if
      end for

      'expect a single piece of content, or several (as an associative array)
    else if type(contentToTranslate) = "roAssociativeArray"

      'expect this to happen just for the search API
      if contentToTranslate.children <> invalid
        node_count = m.translateRecursive(contentToTranslate, translated, isSignedInUser)

        'expect this to happen for history/queue content
      else
        for each content in contentToTranslate
          if contentToTranslate[content] <> invalid
            node = translated.createChild("TubiContentNode")
            node_count = node_count + m.translateRecursive(contentToTranslate[content], node, isSignedInUser)
          end if
        end for
      end if
    end if
  end if

  m.setTotalCount(translated)
  tubiLog("TranslateMetadata converted " + stri(node_count) + " nodes")
  return translated
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
      '//If kids mode is on, then images should be kidsMode large poster versions
      childAA.hdgridposterurl = m.constants.urls.continueWatchingItemBackground_largePoster_kidsMode
    else
      '//Otherwise images should be default large poster versions
      childAA.hdgridposterurl = m.constants.urls.continueWatchingItemBackground_largePoster
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


''''''''''''''''''''''
' buildEmptyMyStuffCategoryAA
'
' @contents: assocArray, content meta data representing a container as returned by the tensor/containers API
Function tubiMetadataTranslate_buildEmptyMyStuffCategoryAA(container)
  updateMetadata = {}
  if container <> invalid
    updateMetadata = {
      id: container.id
      slug: container.slug
      title: container.title
      description: container.description
      totalCount: 0
      offset: m.constants.performance.categoryGridList.initialBlockSize
      validUntil: UpTime(0) + m.constants.cacheTimes.content
      json: ""
      state: "full"
      gridItemType: m.constants.ui.gridItemTypes.emptyContainer
      type: m.contentTypes.emptyContainer
    }

    jsonAA = {}

    sTitle = ""
    sDescription = ""
    sIconURL = ""

    if container.id = m.constants.ui.categoryIds.history
      sTitle = getTranslation("metadata_myStuff_empty_continueWatching_title")
      sDescription = getTranslation("metadata_myStuff_empty_continueWatching_description")
      sIconURL = m.constants.ui.uris.myStuffContinueWatchingIcon
    else if container.id = m.constants.ui.categoryIds.queue
      sTitle = getTranslation("metadata_myStuff_empty_myList_title")
      sDescription = getTranslation("metadata_myStuff_empty_myList_description")
      sIconURL = m.constants.ui.uris.myStuffMyListIcon
    end if

    childAA = {
      id: m.constants.ui.contentTypes.emptyContainer
      subtype: "EmptyMyStuffContentNode"
      type: m.constants.ui.contentTypes.emptyContainer
      title: sTitle
      description: sDescription
      iconUrl: sIconURL
      gridItemType: m.constants.ui.gridItemTypes.emptyContainer
    }
    childAA.hdgridposterurl = m.constants.ui.uris.emptyContainerMyStuffBackground

    updateMetadata.children = CreateObject("roArray", 1, false)
    updateMetadata.children.push(childAA)
    jsonAA[childAA.id] = childAA

    updateMetadata.json = FormatJSON(jsonAA)

  end if

  return updateMetadata
End Function

' add sponsorship info, if it exists, to the metadata
' @metadata: object, The metadata associative array or CategoryContentNode that needs to add the sponsorship info
' @sponsorshipInfo: assocArray, The associative array that contains the raw data of the sponsor info
Function tubiMetadataTranslate_setSponsorshipInfo(metadata, sponsorshipInfo)
  if metadata <> invalid AND sponsorshipInfo <> invalid AND sponsorshipInfo.spon_exp <> invalid AND sponsorshipInfo.image_urls <> invalid then
    images = sponsorshipInfo.image_urls
    ' The info AA later becomes of type "TubiSponsorImagesNode" when the update() function is called on the parent contentNode
    info = {}
    info.subtype = "TubiSponsorImagesNode" '//when the update() function is called, subtype will ensure this AA is typed to the TubiSponsorImagesNode type
    info.brandBackground = images.brand_background
    info.brandColor = images.brand_color
    info.brandLogo = images.brand_logo
    info.brandGraphic = images.brand_graphic
    info.tileBackground = images.tile_background
    info.pixels = sponsorshipInfo.pixels

    metadata.sponsorImages = info
    metadata.sponsorExp = sponsorshipInfo.spon_exp
  end if

  return metadata
End Function


Function tubiMetadataTranslate_generateChannelPosterUrl(channelId)
  if (type(channelId) = "String" or type(channelId) = "roString") AND channelId <> ""
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
  gridItemTypes = constants.ui.gridItemTypes
  gridItemType = gridItemTypes.portrait

  if container.type = constants.ui.categoryTypes.linear
    gridItemType = gridItemTypes.linear
  else if (container.id = constants.ui.categoryIds.fifawc OR container.id = constants.ui.categoryIds.upcomings OR container.id = constants.ui.categoryIds.replays) AND orientation <> constants.ui.gridItemTypes.portrait
    gridItemType = constants.ui.gridItemTypes.landscape
  else if container.id = constants.ui.categoryIds.featured AND orientation <> gridItemTypes.portrait
    ' `orientation <> gridItemTypes.portrait` is required as the search screen container.id is featured but uses portrait imagery
    gridItemType = gridItemTypes.landscapeNoTitle
  else if orientation = gridItemTypes.landscapeInnerMetadata
    gridItemType = gridItemTypes.landscapeInnerMetadata
  end if

  return gridItemType
End Function


' @contentNode: TubiContentNode
' @contentFromServer: assocArray, AA representation of a single piece of content as
'                                 returned by various APIs.
Function tubiMetadataTranslate_composeVideoResources(contentNode, contentFromServer)
  ' videoResources structure example:
  ' videoResources = [
  '   [
  '     {"codec": "H265", "resolution="2160P", ...},
  '     {"codec": "H265", "resolution="1080P", ...}
  '     ...
  '     ...
  '     ...
  '   ]
  '   [
  '     {"codec": "H264", "resolution="1080P", ...},
  '     {"codec": "H264", "resolution="720P", ...}
  '     ...
  '     ...
  '     ...
  '   ]
  videoResources = []
  titanVersionOrExperimentVersion = ""

  codecToVideoResourcesIndexMap = {}
  resources = contentFromServer.video_resources

  if type(resources) = "roArray" AND resources.count() > 0

    ' Create a "stub" ContentNode with just the DRM-oriented fields populated. This
    ' will make it easy to merge metadata plus drm info into one actionable
    ' contentnode for the video player
    for each video in resources

      resource = {}
      if video.manifest <> invalid
        if video.manifest.url <> invalid then
          resource.url = video.manifest.url

          ' Below lines of code helps QA with automation by passing the linear manifest url through qa proxy server.
          #if linearQaProxyEnabled
            settings = m.constants.settings
            if settings.mode = "qa" AND contentNode.type = m.contentTypes.linear
              requestModule = Request(settings)
              ' Removing charles proxy if included.
              resourceUrl = requestModule.removeCharlesProxy(resource.url)
              ' Removing the protocol using split so that both https and http is removed.
              regex = CreateObject("roRegex", "^(http|https)://", "")
              urlSplitArray = regex.split(resourceUrl)
              ' Picking the second part since first part will be protocol
              resourceUrl = m.constants.urls.qaProxy.linearManifest + urlSplitArray[1]

              resource.url = resourceUrl
            end if
          #end if
        end if

        if video.manifest.duration <> invalid then resource.length = video.manifest.duration
      end if

      codec = ""
      if video.codec <> invalid
        codec = getCodecFromVideoResource(video)
        resource.codec = codec
      end if

      'In future ssaiVersion might contain apollo versions like apollo_v15
      if video.ssai_version <> invalid
        resource.ssaiVersion = video.ssai_version
      end if

      resolution = ""
      if video.resolution <> invalid
        resolution = getResolutionFromVideoResource(video)
        resource.resolution = resolution
      end if

      validResource = false

      if contentFromServer.type = "l" OR contentFromServer.type = m.constants.ui.contentTypes.linear OR codec = m.constants.avcCodec OR codec = m.constants.hevcCodec
        validResource = true
      end if

      if validResource = true

        if video.type = m.constants.player.drmTypes.dashWidevine
          resource.type = m.constants.player.drmTypes.dashWidevine
          resource.streamFormat = "dash"
          if video.license_server <> invalid
            resource.drmParams = {
              keySystem: "Widevine"
              licenseServerURL: video.license_server.url
            }
            if video.license_server.auth_header_key <> invalid AND video.license_server.auth_header_value <> invalid
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
            if video.license_server.auth_header_key <> invalid AND video.license_server.auth_header_value <> invalid
              resource.drmHeaders = [video.license_server.auth_header_key + ":" + video.license_server.auth_header_value]
            end if

            if video.license_server.hdcp_version <> invalid
              resource.hdcpVersion = video.license_server.hdcp_version
            end if
          end if
        else if video.type = m.constants.player.drmTypes.dash
          resource.type = m.constants.player.drmTypes.dash
          resource.streamFormat = "dash"
        else if video.type = m.constants.player.drmTypes.hlsv6
          resource.type = m.constants.player.drmTypes.hlsv6
          resource.streamFormat = "hls"
        else if video.type = m.constants.player.drmTypes.hlsv3
          resource.type = m.constants.player.drmTypes.hlsv3
          resource.streamFormat = "hls"
        else
          ' Don't add unsupported/unknown video resource types
          resource = invalid
        end if

        if resource <> invalid

          if video.titan_version <> invalid AND video.titan_version <> ""
            resource.titanVersionOrExperimentVersion = video.titan_version
          else if titanVersionOrExperimentVersion <> ""
            resource.titanVersionOrExperimentVersion = titanVersionOrExperimentVersion
          end if

          ' the following logic groups all the video resources by their codec into a 2 dimensional array of arrays.
          if codecToVideoResourcesIndexMap[codec] = invalid
            videoResourcesIndex = videoResources.count()
            codecToVideoResourcesIndexMap[codec] = videoResourcesIndex
            videoResources.push([])
          else
            videoResourcesIndex = codecToVideoResourcesIndexMap[codec]
          end if

          videoResources[videoResourcesIndex].push(resource)

        end if

      end if

    end for
  end if

  return videoResources
End Function


' @resource: assocArray, video resource that content api responds
'
' returns codec as string without prefix "VIDEO_CODEC_"
' eg. H265
Function getCodecFromVideoResource(resource as Object)
  return resource.codec.replace("VIDEO_CODEC_","")
End Function


' @resource: assocArray, video resource that content api responds
'
' returns resolution as string without prefix "VIDEO_RESOLUTION_"
' eg. 1080P
Function getResolutionFromVideoResource(resource as Object)
  return resource.resolution.replace("VIDEO_RESOLUTION_","")
End Function


''''''''''''''''''''''
' translateEPGChannelIds
' Translate the initial getEPGChannelIds call
'
' @contentToTranslate: roAssocArray, should have a form like:
'                     all_modes:[
'                         "tubitv_us_linear"
'                      ]
'                     mode: {
'                        containers: [
'                           {
'                             container_slug: "sports_on_tubi",
'                             name: "Sports on Tubi",
'                             contents: ["613683", "613761"]
'                             ...
'                           }
'                           {
'                             container_slug: "national_news",
'                             name: "National News",
'                             contents: ["618762", "556174", "555127"]
'                             ...
'                           }
'                        ]
'                     }
'
' Returns a set of content meta data in the form below.
' The ContentNodes will have a limited set of meta data, just enough to propagate the category grid.
' The outer most CategoryContentNode's json field will be filled with the contents json
' <ContentNode json={...all contents info...}>
'   <ContentNode>
'      id="613683"
'      containerName="Sports on Tubi"
'      ...
'   </ContentNode>
'   <ContentNode>
'      id="619727"
'      containerName="National News"
'      ...
'   </ContentNode>
'   ...
' </ContentNode>
'
'
' @contentToTranslate: AA, json parsed response from the epgChannelIds endpoint
Function tubiMetadataTranslate_translateEPGChannelIds(contentToTranslate, requestorID, isUserSignedIn = false, fetchId = 0) As Object
  tubiLog("TubiMetadataTranslate tubiMetadataTranslate_translateEPGChannelIds")

  translated = CreateObject("roSGNode", "ContentNode")
  translated.addField("requestorID", "string", false)
  translated.requestorID = requestorID
  translated.addField("fetchId", "string", false)
  translated.fetchId = fetchId
  translated.id = m.constants.ui.contentIds.timeGridContent

  if contentToTranslate <> invalid AND contentToTranslate.contents <> invalid AND contentToTranslate.containers <> invalid
    containers = contentToTranslate.containers
    for i = 0 to containers.count() - 1
      container = containers[i]
      containerContents = container.contents

      for j = 0 to containerContents.count() - 1
        channelFromServer = contentToTranslate.contents[containerContents[j]]

        if channelFromServer <> invalid
          channelContentNode = translated.createChild("TubiContentNode")
          channelContentNode.id = containerContents[j]

          if container.name <> invalid
            channelContentNode.parentTitle = container.name
          end if

          if container.container_id <> invalid
            channelContentNode.parentId = container.container_id
          end if

          channelContentNode.title = channelFromServer.title
          channelContentNode.type = m.contentTypes.linear
          channelContentNode.channelName = channelFromServer.title

          ' Setting the channelFromServer type as linear, as the backend is not returning type.
          ' //REMOVE this once the roku_dash experiment is graduated, because in future api may return type in response.
          channelFromServer.type = m.constants.ui.categoryTypes.linear

          channelContentNode.videoResources = m.composeVideoResources(channelContentNode, channelFromServer)

          if channelContentNode.videoResources <> invalid
            channelContentNode.hasVideoResources = true
          end if

          channelContentNode.description = channelFromServer.description

          if contentToTranslate.valid_duration <> invalid
            channelContentNode.validUntil = Uptime(0) + contentToTranslate.valid_duration
          else
            channelContentNode.validUntil = UpTime(0) + m.constants.cacheTimes.epgscreen
          end if

          if channelFromServer.subtitles <> invalid
            channelContentNode.hasSubtitles = true
            subtitleTracks = channelFromServer.subtitles

            if  subtitleTracks[0] <> invalid
              langDescription = subtitleTracks[0].language
            else
              langDescription = "English"
            end if


            '//::TODO::LiveNews::HARDCODE:: - The following code is a hardcoded. The following information has not been sent from backend which is required to show CC
            subtitleTracks.push({
              description: langDescription
              trackname: "eia608/CC1"
            })
            channelContentNode.subtitleTracks = subtitleTracks
            channelContentNode.subtitleConfig = {TrackName: "eia608/CC1"}
          else
            channelContentNode.hasSubtitles = false
          end if

          if channelFromServer.needs_login = true AND isUserSignedIn = false
            channelContentNode.needsLogin = true
          end if

          channelContentNode.pubId = channelFromServer.publisher_id

          channelContentNode.state = "partial"

          ' If programs does not show up for the channel during next call, epg/programs, then below program serves as default program node for entire channel.
          ' This child node helps with basic channel metadata and user can play the channel without entire program list.
          program = channelContentNode.createChild("EPGContentNode")
          program.id = channelFromServer.id
          program.title = channelFromServer.title
          program.description = channelFromServer.description
          program.FHDItemWidth = 1700


          if channelFromServer.images <> invalid
            if channelFromServer.images.poster <> invalid
              program.FHDPosterUrl = channelFromServer.images.poster[0]
            end if

            if  channelFromServer.images.thumbnail <> invalid
              channelContentNode.HDSMALLICONURL = channelFromServer.images.thumbnail[0]
            end if

            if channelFromServer.images.background <> invalid
              channelContentNode.backgrounds = m.dedupeBackgrounds(channelFromServer.images.background)
            end if
          end if

          program.ReleaseDate = "24/7"
          if channelFromServer.tags <> invalid AND channelFromServer.tags.Count() > 0
            program.descriptors = channelFromServer.tags
          end if

          'programlevel
          if channelFromServer.needs_login = true AND isUserSignedIn = false
            program.needsLogin = true
          end if
        end if

      end for
    end for
  end if
  return translated
End Function


' @contentToTranslate: AA, json parsed response from the epgProgramming endpoint
Function tubiMetadataTranslate_translateEPGPrograms(contentToTranslate, requestorID, isUserSignedIn = false, fetchId = 0 )
  tubiLog("TubiMetadataTranslate tubiMetadataTranslate_translateEPGPrograms()")
  contentNode = CreateObject("roSGNode", "ContentNode")
  channelArray= []
  updateAA = {
    "requestorID": requestorID
    "fetchId": fetchId
    "children": channelArray
  }

  rows = contentToTranslate.rows
  totalRows = rows.count()
  for rowIndex = 0 to totalRows - 1
    channelFromServer = rows[rowIndex]
    if channelFromServer <> invalid AND channelFromServer.programs <> invalid AND channelFromServer.programs.count() > 0
      programArray = []
      channelNode = {
        "subtype": "TubiContentNode"
        "children": programArray
      }

      channelArray.push(channelNode)

      if channelFromServer.content_id <> invalid
        channelNode.id = channelFromServer.content_id
      end if

      if channelFromServer.title <> invalid
        channelNode.title = channelFromServer.title
        channelNode.channelName = channelFromServer.title
      end if

      if channelFromServer.images <> invalid AND channelFromServer.images.thumbnail <> invalid
        channelNode.HDSMALLICONURL = channelFromServer.images.thumbnail[0]
      end if

      ' Setting the channelFromServer type as linear, as the backend is not returning type.
      ' //REMOVE this once the roku_dash experiment is graduated, because in future api may return type in response.
      channelFromServer.type = m.constants.ui.categoryTypes.linear

      channelNode.type = m.contentTypes.linear

      'This is part of program metadata. We need videoresources when we fetch single channel to play for deeplink
      channelNode.videoResources = m.composeVideoResources(channelNode, channelFromServer)

      channelNode.description = channelFromServer.description
      if contentToTranslate.valid_duration <> invalid
        channelNode.validUntil = Uptime(0) + contentToTranslate.valid_duration
      else
        channelNode.validUntil = UpTime(0) + m.constants.cacheTimes.epgscreen
      end if

      if channelFromServer.has_subtitle <> invalid
        channelNode.hasSubtitles = channelFromServer.has_subtitle
        if channelNode.hasSubtitles = true
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
          channelNode.subtitleTracks = subtitleTracks
          channelNode.subtitleConfig = {TrackName: "eia608/CC1"}
        end if
      end if

      if channelFromServer.publisher_id <> invalid
        channelNode.pubId = channelFromServer.publisher_id
      end if

      channelNode.state = "loaded"

      'channel level needs_login
      if channelFromServer.needs_login = true AND isUserSignedIn = false
        channelNode.needsLogin = true
      end if

      channelNode.backgrounds = m.dedupeBackgrounds(channelFromServer.images.background)

      programs = channelFromServer.programs
      programCount = programs.count()

      for i=0 to programCount -1
        programFromServer = programs[i]
        if programFromServer <> invalid
          translatedProgram = {
            "subtype": "EPGContentNode"
          }
          m.translateProgram(channelFromServer, programFromServer, translatedProgram, requestorID, isUserSignedIn)
          programArray.push(translatedProgram)
        end if
      end for
    end if
  end for

  contentNode.update(updateAA, true)
  return contentNode
End Function


Function tubiMetadataTranslate_translateProgram(channelFromServer, programFromServer, translatedProgram, requestorID, isUserSignedIn = false)

  if channelFromServer.content_id  <> invalid
    translatedProgram.id = channelFromServer.content_id
  end if

  translatedProgram.title = programFromServer.title

  'Add episode title
  if isNonEmptyString(programFromServer.episode_title)
    translatedProgram.epgProgramTitle = programFromServer.episode_title
  end if

  startTime = ""
  dayOfMonth = ""
  dayOfWeek = ""
  dateString = ""
  startTimeFromServer = programFromServer.start_time
  if isNonEmptyString(startTimeFromServer)
    datetimeObj = CreateObject("roDateTime")
    datetimeObj.FromISO8601String(startTimeFromServer)
    datetimeObj.ToLocalTime()
    translatedProgram.startTime = datetimeObj.asSeconds()
    dateString = datetimeObj.AsDateString("short-date")
    dayOfWeek = "day_" + StrI(datetimeObj.GetDayOfWeek()).trim()
    dayOfMonth = StrI(datetimeObj.GetDayOfMonth()).trim()
    startTime = GetAMPMTimeString(datetimeObj, false)
  end if

  endTime = ""
  endTimeFromServer = programFromServer.end_time
  if isNonEmptyString(endTimeFromServer)
    datetimeObjEnd = CreateObject("roDateTime") 'create new dateTime object otherwise local time returned will be wrong.
    datetimeObjEnd.FromISO8601String(endTimeFromServer)
    datetimeObjEnd.ToLocalTime()
    translatedProgram.endTime = datetimeObjEnd.asSeconds()

    endTime = GetAMPMTimeString(datetimeObjEnd, false)
  end if

  sFDPosterURL = ""
  sHDGridPosterURL = ""
  if programFromServer.images <> invalid
    if isNonEmptyArray(programFromServer.images.poster)
      sFDPosterURL = programFromServer.images.poster[0]
    end if

    if isNonEmptyArray(programFromServer.images.landscape)
      sHDGridPosterURL = programFromServer.images.landscape[0]
    end if

  else if channelFromServer.images <> invalid 'if program images are not available, consider channel images for substitute.
    if isNonEmptyArray(channelFromServer.images.poster)
      sFDPosterURL = channelFromServer.images.poster[0]
    end if

    if isNonEmptyArray(channelFromServer.landscape_image)
      sHDGridPosterURL = channelFromServer.landscape_images[0]
    end if
  end if

  sFDPosterURL = m.getRoundedCornersURL(sFDPosterURL)
  sHDGridPosterURL = m.getRoundedCornersURL(sHDGridPosterURL)
  translatedProgram.FHDPosterUrl  = sFDPosterURL
  translatedProgram.hdgridposterurl  = sHDGridPosterURL

  if programFromServer.has_subtitle <> invalid
    translatedProgram.hasSubtitles = programFromServer.has_subtitle
  end if

  if programFromServer.year <> invalid
    translatedProgram.releaseDate = programFromServer.year
  end if

  if startTime <> "" AND endTime <> ""
    translatedProgram.hoursOfAiring = startTime + " - " +  endTime
  end if

  if programFromServer.ratings <> invalid AND programFromServer.ratings[0] <> invalid AND programFromServer.ratings[0].value <> invalid
    translatedProgram.Rating = programFromServer.ratings[0].value
  end if

  if channelFromServer.needs_login = true AND isUserSignedIn = false
    translatedProgram.needsLogin = true
  end if

  if programFromServer.videoRenditions <> invalid
    ' for now, only worry about 4k
    if programFromServer.videoRenditions[0] = m.constants.serverValues.tensorVideoRenditions.fourK
      if m.constants.deviceInfo.videoMode.toInt() >= 2160
        translatedProgram.highestRendition = m.constants.serverValues.tensorVideoRenditions.fourK
      end if
    end if
  end if

  if programFromServer.description <> invalid and programFromServer.description <> ""
    translatedProgram.description = programFromServer.description
  else
    translatedProgram.description = channelFromServer.description
  end if

  if programFromServer.tags <> invalid AND programFromServer.tags.Count() > 0
    translatedProgram.descriptors = programFromServer.tags
  end if

  now  = CreateObject("roDateTime")
  now.ToLocalTime()
  nowTime = now.asSeconds()
  tomorrowSecs = nowTime + 86400 'seconds per day
  tomorrow = CreateObject("roDateTime")
  tomorrow.FromSeconds(tomorrowSecs)

  'Today
  if dateString = now.AsDateString("short-date")
    if translatedProgram.startTime <= nowTime AND translatedProgram.endTime > nowTime  ' current program eg:20M left
      timeLeft = (translatedProgram.endTime -  nowTime) / 60
      translatedProgram.ShortDescriptionLine1 = getTranslation("epg_minutes_left", {minutes: toStr(convertSecondsToMins(translatedProgram.endTime - nowTime))})
    else   'Today future program eg: 10:00 AM
      timeLeft = (translatedProgram.endTime - translatedProgram.startTime) / 60
      translatedProgram.ShortDescriptionLine1 = startTime
    end if
  else if dateString = tomorrow.AsDateString("short-date") ' tomorrow programs eg: 10:00AM, TOMORROW
    timeLeft = (translatedProgram.endTime - translatedProgram.startTime) / 60
    translatedTomorrow = getTranslation("tomorrow")
    translatedProgram.ShortDescriptionLine1 =  startTime + ", " + translatedTomorrow
  else 'future day programs eg: Jan, 8 10:00 AM
    timeLeft = (translatedProgram.endTime - translatedProgram.startTime) / 60
    translatedProgram.ShortDescriptionLine1 = startTime + ", " + getTranslation(dayOfWeek) + dayOfMonth
  end if

  'the value 19.2 is the width for every minute of the program as per the EPG Design. This value will change if EPG design changes in future.
  '186 is min width
  width = timeLeft * 19.2
  if width < 186
    translatedProgram.FHDItemWidth = 186
  else
    translatedProgram.FHDItemWidth = width
  end if


  if programFromServer.genres <> invalid AND programFromServer.genres.count() > 0
    translatedProgram.Categories = programFromServer.genres
  end if

  selectedAttributeText = getTranslation("epg_starts_at") + " "

  itemAttributes = {
    "title" : selectedAttributeText
  }

  if programFromServer.keywords <> invalid AND programFromServer.keywords.count() > 0
    for each keyword in programFromServer.keywords
      if keyword = "EpisodeTitle_IsPreferred" and isNonEmptyString(programFromServer.episode_title)
        itemAttributes["EpisodeTitle_IsPreferred"] = true
        exit for
      end if
    end for

  end if

  translatedProgram.itemAttributes = itemAttributes

  End Function


Function tubiMetadataTranslate_translateTournamentScreen(contentToTranslate, requestorID, isSignedInUser = false)
  tubiLog("TubiMetadataTranslate.tubiMetadataTranslate_translateTournamentScreen")
  contentNode = CreateObject("roSGNode", "TubiContentNode")
  contentNode.addField("requestorID", "string", false)
  contentNode.requestorID = requestorID
  'store the validUntil in main contentNode Until Container specific validUntil is available

  if contentToTranslate.valid_duration <> invalid
    contentNode.validUntil = UpTime(0) + contentToTranslate.valid_duration
  else
    contentNode.validUntil = UpTime(0) + m.constants.cacheTimes.content
  end if

  if contentToTranslate <> invalid
    epgRowToTranslate = {}
    epgRowToTranslate.rows = []
    epgRowToTranslate.rows[0] = contentToTranslate.epg_row
    epgRowToTranslate.valid_duration = contentToTranslate.valid_duration
    epgContentNode = m.translateEPGPrograms(epgRowToTranslate, requestorID, isSignedInUser)
    contentNode.appendChild(epgContentNode)
    contentToTranslate.epg_row = invalid
    contentToTranslate.Delete("epg_row")
  end if

  categoryContent = m.translateHomescreen(contentToTranslate, "tournamentScreen", false, "standard", "tournamentScreen", isSignedInUser)
  contentNode.appendChild(categoryContent)

  return contentNode
End Function


' @content: roAssocArray, series/movie content directly from the server
' @upnextContentItem: Node, Empty tubicontentNode to be passed over to translateRecursive Function.
' @isSignedInUser: boolean, value based on user logged In or not
'
' This function will wrap the TranslateRecursive function and removes any series without seasons and any seasons without episode

Function tubiMetadataTranslate_upNextTranslateRecursiveWrapper(content, upnextContentItem, isSignedInUser = false)
  bInclude = true

  if content.type <> invalid
    sType = m.translateBackendTypeToClientSideType(content.type)
    if sType = m.contentTypes.series
      if content.children <> invalid
        if content.children.count() <= 0 'no seasons
          bInclude = false
        else if content.children.count() > 0 'there are seasons so check each season for emptiness
          for i = content.children.count() -1 to 0 step -1
            season = content.children[i]
            if season.children = invalid or (season.children <> invalid AND season.children.count() <= 0) 'empty season
              content.children.delete(i) 'remove season
            end if
          end for
          if content.children.count() <= 0
            bInclude = false
          end if
        end if
      else
        bInclude = false
      end if
    end if
  end if

  if bInclude = true
    m.translateRecursive(content, upnextContentItem, isSignedInUser)
  else
    parent = upnextContentItem.getParent()
    parent.removeChild(upnextContentItem)
  end if
End Function


' read the descriptors and set value for descriptorCode and descriptorDescription fields in contentNode
'
' @content: TubiContentNode, which has descriptorCode & descriptorDescription fields also on it. Value will be set based on descriptors param.
' @descriptors: roArray, array of roAssociativeArray.
'   eg.
'     [
'        {
'           code: "L"
'           description: "Coarse or crude language"
'        }
'        {
'           code: "V"
'           description: "Violence"
'        }
'     ]
Function tubiMetadataTranslate_setDescriptorCodeAndDescription(content, descriptors)

  if content <> invalid AND descriptors <> invalid AND descriptors.Count() > 1

    descriptor_code = ""
    descriptor_desc = ""

    descriptorsCount = descriptors.Count()

    for i = 0 to descriptorsCount - 1
      if descriptors[i].code <> invalid
        descriptor_code += descriptors[i].code.Trim() + " "
      end if
      if descriptors[i].description <> invalid
        if Len(descriptor_desc) > 0
          descriptor_desc += ", " + descriptors[i].description.Trim()
        else
          descriptor_desc += descriptors[i].description.Trim()
        end if
      end if
    end for
    content.descriptorCode = UCase(descriptor_code)
    content.descriptorDescription = descriptor_desc

  end if

End Function
