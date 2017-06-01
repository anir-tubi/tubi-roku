print "Hot Patch 15"

settings = m.app.utils.getSettings()

'themesFolder = "http://cdn.adrise.com/hotpatches/roku/themes/"

' theme = {
'   GridScreenLogoHD: themesFolder + "narrow_banner_HD.png"
'   GridScreenLogoSD: themesFolder + "narrow_banner_SD.png"
'   ' GridScreenDescriptionImageHD: themesFolder + "bubble-hd.png"
'   ' GridScreenDescriptionImageSD: themesFolder + "red_call_out_HD.png"
'   TallBannerHD: themesFolder + "wide_banner_HD.png"
'   TallBannerSD: themesFolder + "wide_banner_SD.png"
'   OverhangLogoHD: themesFolder + "wide_banner_HD.png"
'   OverhangLogoSD: themesFolder + "wide_banner_SD.png"
'   GridScreenBackgroundColor: "#000000"
'   BackgroundColor: "#000000"
' }


m.app.player.ads.isRokuAdFrameworkOn = true
m.app.player.useCustomPlayer = true


'use to change the theme (the theme details are above), ie. headers and background colors
' m.app.utils.appManager.setTheme(theme)

m.app.linearTv.showLinearTv = true
m.app.cp.showLinearTv = true
m.app.cp.maxContent = 50
m.app.cp.allowAfterHours = false

' m.app.utils.log.idsToLog["1GS3CY077172"] = true


'change urls from V2 to UAPI legacy_cms
'--------------------------------------------------------------------------------------------------------------'
m.app.cp.server = "https://uapi.adrise.tv"

m.app.cp.setUrlsWithContentType = Function(contentType as String)
  version = m.utils.deviceInfo.firmwareVersion
  major = Int(version)
  if major = 3
    contentType = "mp4"
  else
    contentType = "hls"
  end if

  model = m.utils.deviceInfo.model
  authInfo = m.utils.getAuthInfo()

  userIdQueryString = ""
  if authInfo.userId <> invalid
    userIdQueryString = "&user_id=" + authInfo.userId
  end if

  deviceIdQueryString = "&device_id=" + m.utils.deviceInfo.deviceId

  m.urls = {
    getPlaylists: m.server + "/legacy_cms/v2/app/xml?platform=roku&model=" + model + userIdQueryString + deviceIdQueryString
    getVideos: m.server + "/legacy_cms/v2/videos/xml?platform=roku" + userIdQueryString + deviceIdQueryString + "&content_ids="
  }
End Function

' Since this is called in AdriseApp() we need to initialize the URLs again
m.app.cp.setUrlsWithContentType(m.app.player.contentType)


m.app.searchScreen.urlBase = "https://uapi.adrise.tv"

m.app.searchScreen.setSearchUrl = Function(searchString)
  'replace spaces with "%20"
  searchstring = searchString.Replace(" ", "%20")

  apiString = "/legacy_cms/v2/search/xml?platform=roku&search="
  url = m.urlBase + apiString + searchString
  return url
End Function


m.app.searchScreen.show =  function()
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
            asyncId = m.utils.sendAsyncRequest(url, localPort, "searchAPI", invalid, true)

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

        ' Empty placeholder for failed results. User will see an empty screen but can go back and retry the search
        if searchResultsXml = invalid then
          searchResultsXml = CreateObject("roXMLElement")
        end if

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



m.app.utils.getTextFile = Function(url as String, name = "" as String) as Object
  h = CreateObject("roUrlTransfer")
  h.SetPort(CreateObject("roMessagePort"))

  m.log.info(invalid, "clientInfo", name, url)
  print ""

  if url.Left(5) = "https"
    h.SetCertificatesFile("common:/certs/ca-bundle.crt")
    h.AddHeader("X-Roku-Reserved-Dev-Id", "")
  end if

  url = m.buildUrl(url, name, h)
  h.SetUrl(url)

  h.AddHeader("Content-Type", "application/x-www-form-urlencoded")
  h.AddHeader("User-Agent", m.deviceInfo.userAgent + " " + m.deviceInfo.model)
  h.EnableEncodings(true)
  rsp = h.GetToString()
  return rsp
End Function
'--------------------------------------------------------------------------------------------------------------'
