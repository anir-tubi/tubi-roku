Function showEpisodeScreenWithNavigationTracking(content, playbackSource)
  showEpisodeScreen(content, true, playbackSource )
End Function


Function showEpisodeScreenWithoutNavigationTracking(content, playbackSource )
  showEpisodeScreen(content, false, playbackSource)
End Function


'@content: roSGNode, a series content node with seasons and episodes as children and grandchildren, respectively
'@shouldSendAnalytics: boolean, dictates if navigate_to_page and page_load analytics are sent for the episode screen
' @playbackSource: associative Array, format : srcForAnalytic - this value is used for sending analytics;
'                                                   valid values are "automatic", "deliberate", "unknown" or "previews"
'                                               srcForAds - used for rainmaker request
'                                                    valid values are "deeplink" , "ap_auto", "ap_select", "container", "ymal", "search", "epg", "unknown"

'                                               playbackContainer - if srcForAds = container, then playbackContainer is set to the id of the container that was the source, otherwise not used.
Function showEpisodeScreen(content, shouldSendNavigationAnalytics, playbackSource)
  episodesScreen = CreateObject("roSGNode", "EpisodesScreen")
  episodesScreen.id = m.constants.ui.screenIds.episodeScreen
  episodesScreen.shouldFocusWhenPushed = m.top.fadeInContentController
  episodesScreen.content = content
  episodesScreen.updateContent = true
  episodesScreen.playbackSource = playbackSource
  episodesScreen.observeFieldScoped("episodeSelected", "onEpisodeSelected")
  episodesScreen.observeFieldScoped("backgroundUriList", "onEpisodeBackgroundChange")
  episodesScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  episodesScreen.observeFieldScoped("backButtonPressed", "onEpisodeBackPressed")
  episodesScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
  if episodesScreen.content <> invalid AND episodesScreen.content.id <> invalid
    contentId = Mid(episodesScreen.content.id, 2)  ' trim leading "0" off series id

    'update tracking info - have to set the whole AA, can't update only a portion on the AA field
    episodesScreen.trackingPageInfo = {
      pageType: "episode_video_list_page"
      pageValues: {
        series_id: contentId
      }
    }
  end if

  episodesScreen.episodeToFocus = findEpisode2dIndex(content.currentEpisodeId, content)
  pushScreen(episodesScreen, shouldSendNavigationAnalytics, true)

  ' send the exposure event when user landed on episodes detail screen
  getExperimentResource("roku_series_season_order", "roku_series_season_order_v1")
End Function


Function onEpisodeSelected(msg)
  episodesScreen = msg.getRoSGNode()
  index = msg.getData()
  playEpisodeIndex(episodesScreen, index)
End Function


' @episodesScreen: roSGNode, an instance of the EpisodesScreen
' @index: array, vector2d index of what episode to play, with the 0th index representing the season with the series and 1st index representing the content within the season
Function playEpisodeIndex(episodesScreen, index)
  if episodesScreen.content <> invalid
    season = episodesScreen.content.getChild(index[0])
    if season <> invalid
      episode = season.getChild(index[1])
      if episode <> invalid then
        content = episode.clone(false)
        bMature = isMatureRating(content)
        if isLoggedInUser() = false AND bMature = true
          '//if user is a guest and is trying to play content geared for only adults, then ask them to register
          displayMaturePlayWarning("mature-episode", episodesScreen.trackingPageInfo)
        else
          nowPos = 0
          ' find the position in global history
          history = getHistory(content.id)

          if history <> invalid AND history.nowPos > 0
            nowPos = history.nowPos
            content.nowPos = nowPos
          end if

          'Set the tracking component of the item that was selected so it can be accessed as part of the navigateToPage event
          col = index[1] + 1
          row = index[0] + 1
          episodesScreen.trackingComponentInfo = {
            componentType: "episode_video_list_component"
            componentValues: {
              content_tile: m.Tracking.getAnalyticsTile(episode, col, row)
            }
          }
          srcForAd = m.constants.player.playbackOrigin.container
          playbackContainerId = ""

          if episodesScreen.playbackSource <> invalid
            srcForAd = episodesScreen.playbackSource.srcForAds
            playbackContainerId = episodesScreen.playbackSource.playbackContainer
          end if

          playbackSource = {
            "srcForAnalytic": m.constants.player.playbackSource.unknown
            "srcForAds": srcForAd
            "playbackContainer": playbackContainerId
          }

          playVideoContent(content, playbackSource, nowPos)
        end if
      end if
    end if
  end if
End Function


Function onEpisodeBackPressed()
  onKeyEvent("back", true)
  onKeyEvent("back", false)
End Function


Function episodeScreenResumeHelper(episodeScreen)
  playEpisodeIndex(episodeScreen, episodeScreen.episodeFocused)
End Function
