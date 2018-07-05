Function showEpisodeScreen(content)
  episodesScreen = CreateObject("roSGNode", "EpisodesScreen")
  episodesScreen.content = content
  episodesScreen.observeFieldScoped("episodeSelected", "onEpisodeSelected")
  episodesScreen.observeFieldScoped("backgroundUriList", "onEpisodeBackgroundChange")
  if episodesScreen.content <> invalid and episodesScreen.content.id <> invalid
    contentId = Mid(episodesScreen.content.id, 2)  ' trim leading "0" off series id
    episodesScreen.trackingUri = episodesScreen.trackingUri + contentId
  end if
  episodesScreen.episodeToFocus = findEpisode2dIndex(content.currentEpisodeId, content)
  pushScreen(episodesScreen, true)
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
        popScreen(true)
        playVideoContent(content, false, nowPos)
      end if
    end if
  end if
End Function
