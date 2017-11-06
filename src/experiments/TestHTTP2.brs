' call this directly from main() in Tubi channel to get Tubi library dependencies
'
' See docs/http2.md for analysis which uses this code.
'
Function TestHTTP2()

  m.urls = [
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=featured"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=most_popular"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=romance"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=comedy"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=trending"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=movie_night"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=drama"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=indie_films"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=leaving_soon"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=highly_rated_on_rotten_tomatoes"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=family_movies"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=tv_comedies"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=new_arrivals"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=not_on_netflix"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=award_winners_and_nominees"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=most_popular_tv_shows"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=tv_dramas"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=thrillers"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=documentary"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=sci_fi_and_fantasy"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=reality_tv"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=action"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=kids_shows"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=horror"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=black_cinema"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=fan_favorites"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=foreign_favorites%2Fsub%2Fchinese_drama"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=foreign_favorites%2Fsub%2Ftodo_en_espanol"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=foreign_favorites%2Fsub%2Fkorean_drama"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=foreign_favorites%2Fsub%2Finternational_film"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=special_interest%2Fsub%2Fgood_eats"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=special_interest%2Fsub%2Flifestyle_movies"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=foreign_favorites%2Fsub%2Fbritish_tv"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=special_interest%2Fsub%2Fget_fit"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=special_interest%2Fsub%2Fmusic_and_musicals"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=special_interest%2Fsub%2Fwild_things"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=special_interest%2Fsub%2Ffaith"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=classics"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=docuseries"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=comic_con_hq"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=cult_favorites"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=stand_up_comedy"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=crime_tv"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=preschool"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=anime"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=impact"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=martial_arts"
    "https://uapi.adrise.tv/cms/categories?page=1&device_id=YR00HE640232&per_page=200&app_id=tubitv&all=false&page_enabled=true&platform=roku&cat_id=after_hours"
  ]

  batches = []
  batchSize = 10
  for i=0 to (m.urls.count() \ batchSize)
    batches[i] = []
    for j=0 to batchSize-1
      url = m.urls[i*batchSize + j]
      if url <> invalid
        batches[i].push(url)
      end if
    end for
  end for

  m.constants = getConstants()
  m.port = CreateObject("roMessagePort")
  m.queue = TubiRequestQueue().create(m.port)
  m.timespan = CreateObject("roTimeSpan")
  m.timespan.mark()
  m.Request = TubiRequest()
  m.Auth = TubiAuth(m.constants, m.Request)  
  m.epoch = m.timespan.TotalMilliseconds()

  ' ====== BEGIN TEST CASES ======
  ' only invoke one of these at a time, using batchSize above to vary batch sizes

  ' All simultaneously
  'requestAll(m.urls, true, false, false)
  'requestAll(m.urls, false, false, false)
  requestAll(m.urls, false, true, false)
  'requestAll(m.urls, false, false, true)

'  for each batch in batches
    'requestAll(batch, true, false, false)
    'requestAll(batch, false, false, false)
    'requestAll(batch, false, true, false)
    'requestAll(batch, false, false, true)
'  end for

  ' ====== END TEST CASES ======

  print "Finished all requests in "; m.timespan.TotalMilliseconds(); " ms"
  
  ' exit the app
  END

End Function

Function requestAll(urls, queued, http2, freshConnection)
  pending = 0
  start = m.timespan.TotalMilliseconds()
  unqueuedRequests = []  ' keep a reference so they don't get garbage collected
  for each url in urls
    print "Requesting "; url
    request = createRequest({
        url: url
        name: "getCategory"
        options: {}
      })
    if queued then
      m.queue.pushRequest(request)
    else
      urltransfer = CreateObject("roUrlTransfer")
      urltransfer.SetMessagePort(m.port)
      if http2 then
        urltransfer.SetHttpVersion("http2")
      end if
      if freshConnection then
        urltransfer.EnableFreshConnection(true)
      end if
      request.start(urltransfer)
      unqueuedRequests.push(request)
    end if
    pending = pending + 1
  end for

  while true
    msg = wait(0, m.port)
    print "Received message type "; type(msg)
    if type(msg) = "roUrlEvent" then
      ' just ignore rather than trying to handle responses
      if msg.GetInt() = 1 and msg.GetResponseCode() <> 200 then
        print "HTTP ERROR "; msg.GetResponseCode()
        print "Failure Reason: "; msg.GetFailureReason()
        END  ' exit
      end if
      pending = pending - 1
      if pending = 0 then
        exit while
      end if
    end if
  end while

  print "Finished "; urls.count(); " requests in "; (m.timespan.TotalMilliseconds() - start) ; " ms"
End Function


Function createRequest(metadataRequest)
  httpRequest = m.Auth.createAuthRequest(metadataRequest.url, metadataRequest.name, metadataRequest.options)
  if httpRequest = invalid
    httpRequest = m.Request.createAsync(metadataRequest.url, metadataRequest.name, metadataRequest.options)
  end if
  if httpRequest = invalid then
    tubiLog("MetadataFetchTask.createRequest: createAsyncHTTPRequest returned invalid")
    return invalid
  end if
  ' store some context in the request object
  context = {}
  context.append(metadataRequest)
  context.request_start_time = m.timespan.TotalMilliseconds()
  httpRequest.context = context
  return httpRequest
End Function
