Function showEpisodeScreen(content)
  episodesScreen = CreateObject("roSGNode", "EpisodesScreen")
  episodesScreen.content = content
  episodesScreen.observeFieldScoped("episodeSelected", "onEpisodeSelected")
  episodesScreen.observeFieldScoped("backgroundUriList", "onEpisodeBackgroundChange")
  episodesScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  if episodesScreen.content <> invalid and episodesScreen.content.id <> invalid
    contentId = Mid(episodesScreen.content.id, 2)  ' trim leading "0" off series id

    'update tracking info - have to set the whole AA, can't update only a portion on the AA field
    episodesScreen.trackingPageInfo = {
      pageType: "series_detail_page"
      pageValues: {
        series_id: contentId
      }
    }
  end if

  episodesScreen.episodeToFocus = findEpisode2dIndex(content.currentEpisodeId, content)
  pushScreen(episodesScreen, true, true)
End Function


Function onEpisodeSelected(msg)
  episodesScreen = msg.getRoSGNode()
  if episodesScreen.content <> invalid
    season = episodesScreen.content.getChild(episodesScreen.episodeSelected[0])
    if season <> invalid
      episode = season.getChild(episodesScreen.episodeSelected[1])
      if episode <> invalid then
        content = episode.clone(false)
        nowPos = invalid
        ' find the position in global history
        history = m.global.historyIds.findNode(content.id)
        if history <> invalid then
          content.nowPos = history.nowPos
        end if

        'Set the tracking component of the item that was selected so it can be accessed as part of the navigateToPage event
        episodesScreen.trackingComponentInfo = {
          componentType: "episode_video_list_component"
          componentValues: {
            content_tile: m.Tracking.getAnalyticsTile(episode, episodesScreen.episodeSelected[1])
          }
        }

        popScreen(false)
        playVideoContent(content, "none", nowPos)
      end if
    end if
  end if
End Function
