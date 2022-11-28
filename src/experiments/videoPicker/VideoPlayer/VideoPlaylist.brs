''''''''''''''''''''''''
' PLAYLIST MANAGEMENT
''''''''''''''''''''''''

Function onPlaylistChange(msg) As Void
  tubiLog("VideoPlayer.onPlaylistChange")
  if msg.GetData() = invalid or msg.GetData().getChildCount() = 0 return

  m.top.playlistIndex = 0
  m.Video.control = "stop"
  m.VideoState = "stop"
  m.VideoPicker.content = m.top.playlist
End Function


' Use cases:
'  - same index vs. different index (refresh must happen for latter)
'  - playing vs. not playing (seek must be applied after video refreshes and plays)
'
Function onSeekPlaylist(msg) As Void
  tubiLog("VideoPlayer.onSeekPlaylist")
  if msg.GetData() = invalid or type(msg.GetData()) <> "roArray" or msg.GetData().count() <> 2 return

  newIndex = msg.GetData()
  if newIndex[0] >= m.top.playlist.getChildCount() then
    newIndex = [0, 0]
  else if newIndex[0] < 0
    newIndex = [0, 0]
  end if
  tubiLog("VideoPlayer seeking to [" + stri(newIndex[0]) + "," + stri(newIndex[1]) + "]")

  m.top.playlistIndex = newIndex[0]
  m.Video.control = "stop"  ' refresh will start this when complete
  m.VideoState = "stop"
  refreshContent(newIndex[1])
End Function


Function currentPlaylistContent()
  if m.top.playlist <> invalid
    return m.top.playlist.getChild(m.top.playlistIndex)
  else
    return invalid
  end if
End Function


'Occurs when m.Video.state changes (not when m.top.state changes)
Function onVideoStateChange(msg)
  tubiLog("VideoPlayer.onVideoStateChange " + msg.GetData())
  state = msg.GetData()

  if state = "finished" and m.VideoState = "play"
    if m.didAdvanceDrm = true
      ' video player always changes state to "finished" after reaching a state of "error"
      ' so we wait until the "finished" state is reached to play the next available stream for the video
      ' in order to prevent race conditions due to video player state changing.
      m.didAdvanceDrm = false
      playContent()
    else if advancePlaylist() <> true
      m.top.state = state
    end if
  else if state = "error"
    content = m.Video.content
    errorInfo = getPlaybackErrorInfo(m.Video.position, m.Video.downloadedSegment, m.Video.streamingSegment, m.Video.streamingInfo,m.Video.errorCode, m.Video.errorMsg, content)
    tubiLog(FormatJSON(errorInfo), "error", "videoPlayback", "video-playback")
    m.top.sendYouboraError = true

    ' Set up the next DRM scheme. Playback of next DRM scheme is triggered when state = "finished",
    ' right after error state occurs.
    m.didAdvanceDrm = advanceDrmOnContent(content)
    if m.didAdvanceDrm <> true and advancePlaylist() <> true
      m.top.errorMsg = "There was an issue with video playback."  'is used in error modal
      m.top.state = state   'triggers error modal in ContentController
    end if
  end if

  ' Loading page visibility
  if state = "playing" or state = "paused" or m.top.isDocked then
    m.Loading.visible = false
    m.top.state = state
  else
    m.LoadingProgressBar.progress = 0
    m.Loading.visible = true
  end if
End Function

Function advancePlaylist() As Boolean
  tubiLog("VideoPlaylist.advancePlaylist")
  ' advance the playlist
  if m.top.playlist <> invalid
    newIndex = m.top.playlistIndex + 1
    if newIndex >= m.top.playlist.getChildCount()
      if m.top.loopPlaylist
        newIndex = 0
      else
        return false
      end if
    end if
    m.top.playlistIndex = newIndex
    refreshContent(0)
    return true
  else
    return false
  end if
End Function


''''''''''''''''''''''
' METADATA REFRESH
''''''''''''''''''''''
Function refreshContent(nowPos)
  tubiLog("VideoPlayer.refreshContent")
  content = currentPlaylistContent()

  if content <> invalid then
    tubiLog("VideoPlayer current content id = " + content.id)

    'reset thumbnail state
    m.Thumbnail.visible = false
    m.Thumbnail.numSprites = 0
    m.Thumbnail.spriteUrls = []

    if content.url <> invalid and content.url <> "" and content.validUntil <> invalid and content.validUntil >= UpTime(0)
      ' we already have a valid url, so only need to get thumbnail/sprites
      prepareToStartVideo(content, 0)
      requestDetails = {
        contentId: content.id
        getThumbnails: true
      }
      runRefreshTask(requestDetails)
      playContent()
    else
      requestDetails = {
        contentId: content.id
        getContent: true
        refresh: true
      }

      ' trailers don't have thumbnails
      if content.isTrailer <> true
        requestDetails.getThumbnails = true
      end if

      runRefreshTask(requestDetails)
    end if
  end if
End Function


' @requestDetails: assocArray, lets the refresh (DetailMetadataTask) task know what requests to make.
'                  Consists of the following key/values:
'                  {
'                     contentId: string
'                     getContent: bool     'get updated content metadata including latest video uri
'                     getThumbnails: bool  'get thumbnail "sprites" used during ffw/rew
'                     getRelated: bool     'get "You May Also Like" content
'                     refresh: bool        'this dictates if m.VideoState is set to "refresh"
'                  }
Function runRefreshTask(requestDetails)
  tubiLog("VideoPlayer.runRefreshTask")
  if m.refreshTask <> invalid
    m.refreshTask.unobserveField("response")
    m.refreshTask.unobserveField("error")
    m.refreshTask.unobserveField("thumbnailsResponse")
  else
    ' refreshTask can't just be overwritten, or else it creates two DetailMetaDataTasks.
    ' When refreshTask.control = "RUN" happens if it was overwritten, the task's functionName
    ' actually runs for each of the tasks that had been ever been assigned to m.refreshTask.
    ' This becomes an issue if a user selects play multiple times.
    m.refreshTask = CreateObject("roSGNode", "DetailMetadataTask")
  end if

  m.refreshTask.request = requestDetails
  m.refreshTask.observeField("response", "onRefreshResponse")
  m.refreshTask.observeField("error", "onRefreshError")
  m.refreshTask.observeField("thumbnailsResponse", "onThumbnailsResponse")
  m.refreshTask.control = "RUN"
  if requestDetails.refresh = true
    m.VideoState = "refresh"
  end if
End Function


Function onRefreshResponse(msg)
  tubiLog("VideoPlayer.onRefreshResponse")
  refreshedContent = msg.GetData()
  refreshTask = msg.getRoSGNode()
  playlistContent = currentPlaylistContent()
  m.VideoState = "stop"
  if refreshedContent.id = playlistContent.id
    ' While the refresh content may not hold all the information we need (e.g. isLiveTV), it's
    ' only used for the stream urls and subtitle urls really and should be ok here without merging
    ' fields from the original content.
    mergedFields = ["isLiveTV", "isTrailer", "title", "nowPos", "parentType", "parentTitle"]
    for each f in mergedFields
      refreshedContent.setField(f, playlistContent.getField(f))
    end for

    ' In the case that we are attempting to watch a trailer, overwrite the video urls of the refreshed content
    ' with the trailer urls
    if playlistContent.isTrailer and not m._.empty(refreshedContent.trailerUrls)
      refreshedContent.url = refreshedContent.trailerUrls[0]
      refreshedContent.subtitleTracks = []
      refreshedContent.subtitleConfig = invalid
    end if

    prepareToStartVideo(refreshedContent, 0)
    playContent()
  end if
End Function


Function onRefreshError(msg)
  tubiLog("VideoPlayer.onRefreshError")
  ' TODO: When do we shown an error vs. skip content and continue on?
  if m.VideoState = "refresh" or m.VideoState = "pause"
    m.VideoState = "stop"
    if advancePlaylist() <> true
      m.top.errorMsg = "Could not refresh the content or play next content."
      m.top.state = "error"
    end if
  end if
End Function


Function onThumbnailsResponse(msg)
  tubiLog("VideoPlayer.onThumbnailsResponse")
  thumbnailsInfo = msg.getData()  'expect a TubiContentNode with thumbnail fields populated
  m.Thumbnail.visible = false   ' always start with thumbnail invisible, then show it when scrubbing

  if thumbnailsInfo <> invalid
    if thumbnailsInfo.thumbnailUrls <> invalid and thumbnailsInfo.thumbnailUrls.count() > 0
      m.Thumbnail.numSprites = thumbnailsInfo.thumbnailSpan
      ' This should bring the 4400px image width down below the 4kx4k texture size limit
      ' which would otherwise cause the images to fail to load.
      scaleFactor = 0.75
      m.Thumbnail.spriteSheetWidth = thumbnailsInfo.thumbnailSize[0] * thumbnailsInfo.thumbnailSpan * scaleFactor
      m.Thumbnail.spriteSheetHeight = thumbnailsInfo.thumbnailSize[1] * scaleFactor
      m.Thumbnail.spriteUrls = thumbnailsInfo.thumbnailUrls
      m.Thumbnail.jumpToSprite = 0
      ' Always keep height of thumbnail the same, varying the width if necessary
      thumbnailAspect = thumbnailsInfo.thumbnailSize[0] / thumbnailsInfo.thumbnailSize[1]
      m.Thumbnail.width = m.Thumbnail.height * thumbnailAspect
      m.thumbnailMaxXOffset = 1920 - 238 - m.Thumbnail.width
      m.Thumbnail.translation = [m.thumbnailMinXOffset, m.thumbnailMaxYOffset - m.Thumbnail.height]
    end if
  end if
End Function


' Helper function that aggregates any tasks that need to be done before playing a new video
Function prepareToStartVideo(content, drmIndex)
  resetVideoPlayerState(content)
  setDrmOnContent(content, drmIndex)
  m.top.content = content  'sends content to video node and makes current content available to contentController
  m.top.sendVideoTrackingStart = true
End Function


' Reset video player state to a basic state
' @content: TubiContentNode
Function resetVideoPlayerState(content = invalid)
  m.LoadingProgressBar.progress = 0
  m.LoadingMessage.text = ""
  cancelReplayCaptions()
  m.AdHeadsUp.visible = false
  if content <> invalid
    updateVideoPlayerState(content)
  end if
End Function


' Set video player state based on passed in content
' @content: TubiContentNode
Function updateVideoPlayerState(content) as Void
  if type(content) <> "roSGNode" then return

  ' add the title and episode title to the overlay
  title = m.Overlay.findNode("VideoOverlayTitle")
  episodeTitle = m.Overlay.findNode("VideoOverlayEpisodeTitle")
  if content.parentType = "series"
    title.text = content.parentTitle
    episodeTitle.text = content.title
  else
    title.text = content.title
    episodeTitle.text = ""
  end if

  'there are no subtitles so grey out the captions button
  if content.subtitleTracks = invalid or content.subtitleTracks.count() = 0
    m.TransportButtons.removeChild(m.ClosedCaption)
    m.ClosedCaptionDisabled.visible = true

  'there are subtitles, so check if captions button has been greyed out previously
  else if m.NodeHelpers.getChildIndex(m.TransportButtons, m.ClosedCaption) < 0
    m.TransportButtons.appendChild(m.ClosedCaption)
    m.ClosedCaptionDisabled.visible = false
  end if

  liveTVGroup = m.top.findNode("LiveTVGroup")

  if content.isLiveTV then
    liveTVGroup.visible = true
  else
    liveTVGroup.visible = false
  end if

  'if it's not a trailer, remove the skip trailer button
  if content.isTrailer = false
    m.TransportButtons.removeChild(m.SkipTrailerButton)

  'add the skip trailer button if it's a trailer and it doesn't already exist on the transport
  else if m.NodeHelpers.getChildIndex(m.TransportButtons, m.SkipTrailerButton) < 0
    m.TransportButtons.insertChild(m.SkipTrailerButton, 0)
  end if
End Function


Function advanceDrmOnContent(contentNode)
  tubiLog("VideoPlaylist.advanceDrmOnContent")
  nextIndex = 0
  if contentNode.drmType <> ""
    for i=0 to contentNode.videoResources.count()-1
      resource = contentNode.videoResources[i]
      if contentNode.drmType = resource.type
        nextIndex = i + 1
        exit for
      end if
    end for
  end if
  return setDrmOnContent(contentNode, nextIndex)
End Function


' Updates the content node's url and httpHeaders fields with the videoResource info indicated by the index value
'
' @contentNode: roSGNode, a TubiContentNode
' @index: int, the index of the video resource we want to use for DRM
Function setDrmOnContent(contentNode, index)
  tubiLog("VideoPlaylist.setDrmOnContent")
  if contentNode.videoResources <> invalid and contentNode.videoResources.count() > 0 and contentNode.videoResources[index] <> invalid and contentNode.isTrailer <> true
    ' reset DRM fields
    contentNode.drmParams = {}
    contentNode.encodingType = ""
    contentNode.encodingKey = ""

    resource = contentNode.videoResources[index]

    ' set general fields related to DRM
    contentNode.httpHeaders = resource.drmHeaders
    contentNode.url = resource.url
    contentNode.titan_version = resource.titan_version
    contentNode.length = resource.length
    contentNode.streamFormat = resource.streamFormat
    contentNode.drmType = resource.type

    ' set DRM scheme specific fields
    if resource.type = m.constants.player.drmTypes.dashWidevine
      contentNode.drmParams = resource.drmParams
    else if resource.type = m.constants.player.drmTypes.dashPlayready
      contentNode.encodingType = resource.encodingType
      contentNode.encodingKey = resource.encodingKey
    end if
    return true
  end if
  return false
End Function

Function getPlaybackErrorInfo(position, downloadedSegment, streamingSegment, streamInfo, errorCode, errorMsg, content)
  errorInfo = {
    video_id: ""
    video_url: ""
  }
  if errorCode = -3
    errorInfo.error_message = "Server did not respond with hls segment. Potential 504 or 404. Following segment likely has issue."
    ' Check for position to be > 0 in order to prevent segments from previous videos to populate
    ' the error messaging for the current video.
    if position > 0 and downloadedSegment <> invalid
      ' in the case of errorCode = -3, it likely means there was a 504 or 404 response from the server which ultimately was the source of the error.
      ' we get the last downloaded segment which is the last good segment instead of the current streaming segment, which may be several segments ahead of the bad segment.
      ' in this case, the segment causing the error is the segment AFTER the logged segment.
      errorInfo.segment_sequence = downloadedSegment.segSequence
      errorInfo.segment_url = removeExcessUrl(downloadedSegment.SegUrl)
      errorInfo.segment_bitrate = downloadedSegment.BitrateBps
    end if
  else if errorMsg <> invalid
    if errorCode = 0
      ' original network error message is to long:
      ' "Network error.  This could be caused by any of the following problems: (1) The server is down or unresponsive. (2) The server is unreachable. (3) There is a network setup issue on the client."
      errorInfo.error_message = "Network error"
    else
      errorInfo.error_message = errorMsg
    end if
    if position > 0 and streamingSegment <> invalid
      ' streamingSegment can be invalid when the server returns a 504, 404, etc.
      errorInfo.segment_url = removeExcessUrl(streamingSegment.segUrl)
      errorInfo.segment_start_time = streamingSegment.segStartTime
      errorInfo.segment_sequence = streamingSegment.segSequence
      errorInfo.segment_bitrate = streamingSegment.segBitrateBps
    end if
  end if
  errorInfo.error_code = errorCode

  if content <> invalid then errorInfo.video_id = content.id

  if position > 0 and streamInfo <> invalid
    errorInfo.video_url = removeExcessUrl(streamInfo.streamUrl)
  else if content <> invalid
    errorInfo.video_url = removeExcessUrl(content.url)
  end if

  return errorInfo
End Function


'Helper function that removes all characters after the ? in the url
Function removeExcessUrl(url)
  cutUrl = ""
  if type(url) = "roString" or type(url) = "String"
    position = url.Instr(Chr(63)) 'checks for the position of the "?" in the url string
    if position > -1
      cutUrl = url.Left(position)
    else
      cutUrl = url
    end if
  end if
  return cutUrl
End Function
