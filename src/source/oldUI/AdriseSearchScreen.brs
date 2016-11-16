function AdriseSearchScreen(utils, cp, searchResultsScreen)
  
  searchScreenObj = {
    'properties
    cp: cp
    utils: utils
    searchResultsScreen: searchResultsScreen
    urlBase: "http://cms.adrise.com/"
    searchPort:CreateObject("roMessagePort")
    throttleTime: 500 'in ms

    'methods
    show: SearchScreen_show
    setSearchUrl: SearchScreen_setSearchUrl
  }

  return searchScreenObj

end function

'----------------------SearchScreen_show()--------------------
'display the search screen
function SearchScreen_show()
  port = m.searchPort
  screen = CreateObject("roSearchScreen")
  screen.SetMessagePort(port)

  screen.SetSearchTermHeaderText("Search Suggestions: ")
  screen.SetSearchButtonText("search")
  screen.SetClearButtonEnabled(false)
  throttler = CreateObject("roTimespan")

  screen.Show()
  m.utils.trackEvent({
    trackType: "pageLoad"
    value: "/search"
    port: port
  })

  searchString = ""
  searching = true
  suggestionCount = 0

  while searching = true
    msg = wait(0, port)
    if type(msg) = "roUrlEvent"
      'needed for user event tracking that takes place for navigating to the search screen (occurs in handleItemPicked() in AdriseApp.brs)
      m.utils.getAsyncResponse(msg, 0)

    else if type(msg) = "roSearchScreenEvent"
      if msg.isScreenClosed()
        print "screen closed"
        searching = false
      else if msg.isCleared()
        print "search terms cleared"
        history.Clear()
      else if msg.isPartialResult() 'letter/number added to the search string
        print "partial search: "; msg.GetMessage()

        'throttle the amount of requests made
        if throttler.TotalMilliseconds() > m.throttleTime
          throttler.Mark()
          searchString = msg.GetMessage()

          if searchString = ""
            screen.ClearSearchTerms()
            suggestionCount = 0

          else if Len(searchString) > 1 and Right(searchString, 1) <> " "
            url = m.setSearchUrl(searchString)

            localPort = CreateObject("roMessagePort")

            'send async request to search API
            'if the request is send succesfully wait 1 second for a response
            'if a response happens within that time get the response and act on it'
            asyncId = m.utils.sendAsyncRequest(url, localPort, "searchAPI")

            m.utils.trackEvent({
              trackType: "search"
              value: Left(searchString, 1000)
              port: localPort
            })     
            if (asyncId <> 0)
              while true
                msg = wait(1000, localPort)
                if msg <> invalid
                  response = m.utils.getAsyncResponse(msg, asyncId) 'response.data should be xml object

                  if response <> invalid and response.data <> invalid
                    xml = ParseXML(response.data)
                    if xml <> invalid and xml.children.level.children.getChildElements() <> invalid
                      screen.ClearSearchTerms()
                      for each child in xml.children.level.children.getChildElements()
                        suggestionTitle = child.title.GetText()
                        screen.AddSearchTerm(suggestionTitle)
                        if suggestionCount >= 8
                          exit for
                        end if
                        suggestionCount = suggestionCount + 1
                      end for
                      suggestionCount = 0
                    end if
                    exit while
                  end if
                end if

              end while
            end if
          end if
        end if

      else if msg.isFullResult()
        print "full search: "; msg.GetMessage()
        searchString = msg.GetMessage()
        url = m.setSearchUrl(searchString)

        searchResultsXml = m.utils.getXml(url, "getSearchResults")

        m.utils.trackEvent({
          trackType: "search"
          value: Left(searchString, 1000)
          port: port
        })        

        searchPlaylist = m.cp.getPlaylistFromXmlObj(searchResultsXml.children.level, "250x250", 1, invalid, "search")
        m.cp.getAllEpisodesForPlaylistFromServer(searchPlaylist, "search")

        m.utils.trackEvent({
          trackType: "navigate"
          value: "/search/results"
          ctx: "/search"
          port: m.searchResultsScreen.searchResultsPort
        })

        m.searchResultsScreen.showVertical(searchPlaylist)

      else if msg.isButtonInfo()
        print "button info "; msg.GetMessage()
      else
        print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
      end if
    end if
  end while 

end function

'----------------------SearchScreen_setSearchUrl()--------------------
'creates the url for interacting with the Search API
function SearchScreen_setSearchUrl(searchString)
  'replace spaces with "%20"
  searchstring = searchString.Replace(" ", "%20")
  apiString = "v2/app.php?&id=" + m.cp.shortAppName + "&platform=roku&content-type=hls&video-fields=title&sdk=3.0&format=xml&search-mode=t&search="
  url = m.urlBase + apiString + searchString
  return url
end function