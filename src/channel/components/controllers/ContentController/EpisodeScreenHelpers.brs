Function showEpisodeScreenWithNavigationTracking(content)
  showEpisodeScreen(content, true)
End Function

Function showEpisodeScreenWithoutNavigationTracking(content)
  showEpisodeScreen(content, false)
End Function


'@content: roSGNode, a series content node with seasons and episodes as children and grandchildren, respectively
'@shouldSendAnalytics: boolean, dictates if navigate_to_page and page_load analytics are sent for the episode screen
Function showEpisodeScreen(content, shouldSendNavigationAnalytics)
  episodesScreen = CreateObject("roSGNode", "EpisodesScreen")
  episodesScreen.id = m.constants.ui.screenIds.episodeScreen
  episodesScreen.shouldFocusWhenPushed = m.top.fadeInContentController
  episodesScreen.content = content
  episodesScreen.updateContent = true
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
End Function


Function onEpisodeSelected(msg)
  episodesScreen = msg.getRoSGNode()
  if episodesScreen.content <> invalid
    season = episodesScreen.content.getChild(episodesScreen.episodeSelected[0])
    if season <> invalid
      episode = season.getChild(episodesScreen.episodeSelected[1])
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
          col = episodesScreen.episodeSelected[1] + 1
          row = episodesScreen.episodeSelected[0] + 1
          episodesScreen.trackingComponentInfo = {
            componentType: "episode_video_list_component"
            componentValues: {
              content_tile: m.Tracking.getAnalyticsTile(episode, col, row)
            }
          }

          playVideoContent(content, "unknown", nowPos)
        end if
      end if
    end if
  end if
End Function


Function onEpisodeBackPressed()
  onKeyEvent("back", true)
  onKeyEvent("back", false)
End Function