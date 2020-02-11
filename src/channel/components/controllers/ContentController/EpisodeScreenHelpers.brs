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
  episodesScreen.content = content
  episodesScreen.updateContent = true
  episodesScreen.observeFieldScoped("episodeSelected", "onEpisodeSelected")
  episodesScreen.observeFieldScoped("backgroundUriList", "onEpisodeBackgroundChange")
  episodesScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  if episodesScreen.content <> invalid and episodesScreen.content.id <> invalid
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
        nowPos = 0
        ' find the position in global history
        history = m.global.historyIds.findNode(content.id)
        if history <> invalid then
          nowPos = history.nowPos
          content.nowPos = nowPos
        end if

        'Set the tracking component of the item that was selected so it can be accessed as part of the navigateToPage event
        episodesScreen.trackingComponentInfo = {
          componentType: "episode_video_list_component"
          componentValues: {
            content_tile: m.Tracking.getAnalyticsTile(episode, episodesScreen.episodeSelected[1])
          }
        }

        playVideoContent(content, "none", nowPos)
      end if
    end if
  end if
End Function
