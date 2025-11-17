''''''''''''''''''''''''''''''
' PlayerStatsMixin
'
' Shared mixin for player stats overlay functionality used by both VOD and Linear video players
''''''''''''''''''''''''''''''
'
'
' Updates player stats overlay with current video data
' @constants: associative array, constants object containing settings
' @Video: roSGNode, Video node reference
' @showPlayerStats: boolean, flag to determine if player stats should be shown
' @playerStatsOverlay: roSGNode, PlayerStatsOverlay node reference
Function updatePlayerStatsOverlayMixin(constants, video, showPlayerStats, playerStatsOverlay)

  if constants.settings.mode <> "production" AND video.width = 1920 AND showPlayerStats = true
    if playerStatsOverlay <> invalid
      stats = {}

      if video.streamInfo <> invalid
        stats.streamInfo = video.streamInfo
      else
        stats.streamInfo = {}
      end if

      content = video.content
      if content <> invalid
        stats.streamInfo.streamUrl = content.url
        stats.streamInfo.resolution = content.resolution
        stats.streamInfo.drmType = content.drmType
        stats.streamInfo.codec = content.codec
        stats.streamInfo.videoResources = content.videoResources
        stats.streamInfo.videoRenditions = content.videoRenditions
        stats.streamInfo.currentVideoResourceIndex = content.currentVideoResourceIndex
      end if

      if video.streamingSegment <> invalid
        stats.streamingSegment = video.streamingSegment
      else
        stats.streamingSegment = {}
      end if

      if video.downloadedSegment <> invalid
        stats.downloadedSegment = video.downloadedSegment
      else
        stats.downloadedSegment = {}
      end if

      playerStatsOverlay.playerStats = stats
      playerStatsOverlay.opacity = 0.8

    else if playerStatsOverlay <> invalid
      playerStatsOverlay.opacity = 0.0
    end if

  else if playerStatsOverlay <> invalid
    playerStatsOverlay.opacity = 0.0
  end if

End Function

