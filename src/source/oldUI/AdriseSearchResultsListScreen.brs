function AdriseSearchResultsListScreen(player, cp, settings, utils)

return {

  player: player
  cp: cp
  settings: settings
  utils: utils
  searchResultsPort: CreateObject("roMessagePort")
  ' episodeListScreen: episodeListScreen
  ' detailScreen: detailScreen

  'methods
  showVertical: SearchResults_showVertical
}


end function

'----------------------SearchResults_showVertical()--------------------
' display the search results list page as a vertical list on left with image to the right
function SearchResults_showVertical(searchList)
  port = m.searchResultsPort
  screen = CreateObject("roListScreen")
  screen.SetMessagePort(port)

  screen.setHeader("Tubi TV Search Results")
  screen.setContent(searchList.episodes)
  screen.Show()

  m.utils.trackEvent({
    trackType: "pageLoad"
    value: "/search/results"
    port: port
  })

  viewingSearchResults = true
  while viewingSearchResults = true
    msg = wait(0, screen.GetMessagePort())

    if type(msg) = "roUrlEvent"
      m.utils.getAsyncResponse(msg, 0)

    else if type(msg) = "roListScreenEvent"
      if msg.isScreenClosed()
            
        m.utils.trackEvent({
          trackType: "navigate"
          value: "/search/results"
          ctx: "/search"
          port: GetGlobalAA().app.searchScreen.searchPort
        })

        viewingSearchResults = false

      else if msg.isListItemSelected()
        listIndex = msg.GetIndex()
        episode = searchList.episodes[listIndex]

        if episode.type = "video"   'episode is a movie
          ' does this app have you go through a details screen?
          if m.settings.show_details_screen
            
            m.utils.trackEvent({
              trackType: "navigate"
              value: "/video/" + episode.id
              ctx: "/search/results"
              port: GetGlobalAA().app.detailScreen.detailsPort
            })

            itemIndex = GetGlobalAA().app.detailScreen.show(episode, searchList, listIndex)
          else
            while episode <> invalid
              episode.PlayStart = 0
              if m.player.playVideo(episode) = "CLOSED"
                exit while
              end if
              episode = cp.getEpisodeInPlaylist(playlist, itemIndex+1)
              if episode <> invalid
                itemIndex = itemIndex + 1
              end if
            end while
          end if
        else   'episode is a series
          episodeScreen = GetGlobalAA().app.episodeListScreen

          if episode.playlist <> invalid
            if (m.cp.autoplayData = invalid)

              m.utils.trackEvent({
                trackType: "navigate"
                value: "/series/episodelist/" + episode.id
                ctx: "/search/results"
                port: episodeScreen.episodePort
              })

              episodeScreen.show(episode)
            else
              episodeScreen.autoPlay(episode.playlist, m.cp.autoplayData.path[2], m.cp.autoplayData.path[3], false)
              m.cp.autoplayData = invalid
            end if
          end if
        end if
      end if
    end if

  end while
end function