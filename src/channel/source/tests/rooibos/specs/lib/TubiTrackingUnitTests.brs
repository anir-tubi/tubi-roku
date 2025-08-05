'@TestSuite [TubiTracking] TubiTracking.brs

'@Setup
Function TubiTrackingSetup()
  m.Tracking = tubiTracking_createTubiTracking_testHelper()
End Function


Function tubiTracking_createTubiTracking_testHelper()
  constants = getConstants()
  auth = TubiAuth(constants)
  tracking = TubiTracking(constants, auth)
  return tracking
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiTracking.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test getAnalyticsRequestIdempotency unit tests
Function tubiTracking_getAnalyticsRequestIdempotency_test()
  Tracking = m.Tracking
  idempotency = Tracking.getAnalyticsRequestIdempotency()

  'test that the key named "key" exists and the value is a string
  m.assertNotInvalid(idempotency.key)
  m.assertTrue(type(idempotency.key) = "roString" OR type(idempotency.key) = "String")

  'test the value has the form of a UUID
  uuidBlocks = idempotency.key.split("-")
  m.assertTrue(uuidBlocks.count() = 5)
  m.assertTrue(uuidBlocks[0].len() = 8)
  m.assertTrue(uuidBlocks[1].len() = 4)
  m.assertTrue(uuidBlocks[2].len() = 4)
  m.assertTrue(uuidBlocks[3].len() = 4)
  m.assertTrue(uuidBlocks[4].len() = 12)
End Function


'@Test getAnalyticsTimestamp unit tests
Function tubiTracking_getAnalyticsTimestamp_test()
  ' We use a loop here since it's possible that the two times are generated at different milliseconds
  for i = 0 to 100
    Tracking = m.Tracking
    trackingTimestamp = Tracking.getAnalyticsTimestamp()
    dateTime = CreateObject("roDateTime")
    testTimestamp = dateTime.ToISOString("milliseconds")

    if trackingTimestamp = testTimestamp OR i = 100 then
      m.assertEqual(trackingTimestamp, testTimestamp)
      exit for
    end if
  end for
End Function


'@Test getAnalyticsUser unit tests
Function tubiTracking_getAnalyticsUser_test()
  Tracking = m.Tracking
  user = Tracking.getAnalyticsUser()

  m.assertNotInvalid(user.user_id)
  m.assertNotInvalid(user.auth_type)
  m.assertTrue(user.auth_type = "UNKNOWN" OR user.auth_type = "NOT_AUTHED" OR user.auth_type = "EMAIL")
  m.assertTrue(type(user.user_id) = "roInteger")
  m.assertTrue((user.auth_type = "UNKNOWN" AND user.user_id > 0) OR (user.auth_type = "NOT_AUTHED" AND user.user_id = 0) OR (user.auth_type = "EMAIL" AND user.user_id > 0))

End Function


'@Test getAnalyticsDevice unit tests
Function tubiTracking_getAnalyticsDevice_test()
  constants = getConstants()
  Tracking = m.Tracking
  device = Tracking.getAnalyticsDevice()

  m.assertNotInvalid(device.device_id)
  m.assertNotInvalid(device.model)
  m.assertNotInvalid(device.os)
  m.assertNotInvalid(device.os_version)
  m.assertNotInvalid(device.user_agent)
  m.assertNotInvalid(device.is_mobile)
  m.assertNotInvalid(device.device_height)
  m.assertNotInvalid(device.device_width)

  if constants.deviceInfo.isAdIdTrackingDisabled <> true
    m.assertNotInvalid(device.advertiser_id)
  else
    m.assertEqual(device.advertiser_id, "00000000-0000-0000-0000-000000000000")
  end if

End Function


'@Test getAnalyticsApp unit tests
Function tubiTracking_getAnalyticsApp_test()
  Tracking = m.Tracking
  app = Tracking.getAnalyticsApp({ appMode: "" })

  m.assertNotInvalid(app.platform)
  m.assertNotInvalid(app.app_version)
  m.assertNotInvalid(app.app_version_numeric)
  m.assertNotInvalid(app.app_height)
  m.assertNotInvalid(app.app_width)

End Function


'@Test getAnalyticsConnection unit tests
Function tubiTracking_getAnalyticsConnection_test()
  Tracking = m.Tracking

  'event values with nominal_speed (ie. play_progress)
  eventValues = {
    nominal_speed: 130
  }
  connection = Tracking.getAnalyticsConnection(eventValues)

  m.assertNotInvalid(connection.network)
  m.assertNotInvalid(connection.nominal_speed)
  m.assertInvalid(connection.isp)
  m.assertInvalid(connection.carrier)
  m.assertTrue(connection.network = "WIFI" OR connection.network = "ETHERNET" OR connection.network = "UNKNOWN_NETWORK")


  'event values without nominal_speed (ie. play_progress)
  eventValues = {}
  connection = Tracking.getAnalyticsConnection(eventValues)

  m.assertNotInvalid(connection.network)
  m.assertInvalid(connection.nominal_speed)
  m.assertInvalid(connection.isp)
  m.assertInvalid(connection.carrier)
  m.assertTrue(connection.network = "WIFI" OR connection.network = "ETHERNET" OR connection.network = "UNKNOWN_NETWORK")

End Function


'@Test getAnalyticsEvent unit tests
Function tubiTracking_getAnalyticsEvent_test()
  Tracking = m.Tracking

  'test will all values
  pageLoadValues = {
    pageOneof: {
      category_page: {
        category_slug: "featured"
      }
    }
    load_time: 124
    status: "SUCCESS"
  }
  pageLoadEvent = Tracking.getAnalyticsEvent("page_load", pageLoadValues)
  m.assertNotInvalid(pageLoadEvent.page_load.load_time)
  m.assertNotInvalid(pageLoadEvent.page_load.status)
  m.assertNotInvalid(pageLoadEvent.page_load.category_page)

  'test with partial values - no page
  pageLoadValues = {
    pageOneof: {
      nonexist_page: {
        fake: "fake"
      }
    }
    load_time: 124
    status: "SUCCESS"
  }
  pageLoadEvent = Tracking.getAnalyticsEvent("page_load", pageLoadValues)

  m.assertNotInvalid(pageLoadEvent.page_load.load_time)
  m.assertNotInvalid(pageLoadEvent.page_load.status)
  m.assertInvalid(pageLoadEvent.page_load.category_page)

  'test with partial values - no load time
  pageLoadValues = {
    pageOneof: {
      category_page: {
        category_slug: "featured"
      }
    }
    load_time: -1
    status: "SUCCESS"
  }
  pageLoadEvent = Tracking.getAnalyticsEvent("page_load", pageLoadValues)

  m.assertNotInvalid(pageLoadEvent.page_load.load_time)
  m.assertNotInvalid(pageLoadEvent.page_load.status)
  m.assertNotInvalid(pageLoadEvent.page_load.category_page)

End Function


'@Test getAnalyticsPage unit tests
Function tubiTracking_getAnalyticsPage_test()
  Tracking = m.Tracking

  'valid page
  page = Tracking.getAnalyticsPage("search_page", { query: "home" })
  m.assertNotInvalid(page.search_page.query)
  m.assertTrue(page.search_page.query = "home")

  'valid page, empty value
  page = Tracking.getAnalyticsPage("search_page", { query: "" })
  m.assertInvalid(page.search_page.query)

  'not valid page
  page = Tracking.getAnalyticsPage("fake_page", { query: "home" })
  m.assertInvalid(page)

End Function


'@Test getAnalyticsComponent unit tests
Function tubiTracking_getAnalyticsComponent_test()
  Tracking = m.Tracking

  'valid component
  componentValues = {
    category_slug: "my_queue"
    category_row: "5"
    content_tile: {
      video_id: 54321
      col: 16
      row: 1
    }
  }
  component = Tracking.getAnalyticsComponent("category_component", componentValues)
  m.assertNotInvalid(component.category_component.category_slug)
  m.assertNotInvalid(component.category_component.category_row)
  m.assertNotInvalid(component.category_component.content_tile)
  m.assertNotInvalid(component.category_component.content_tile.video_id)
  m.assertNotInvalid(component.category_component.content_tile.col)
  m.assertNotInvalid(component.category_component.content_tile.row)

  'not valid component'
  component = Tracking.getAnalyticsComponent("fake_component", componentValues)
  m.assertInvalid(component)

  'empty value
  componentValues.category_row = -1
  component = Tracking.getAnalyticsComponent("category_component", componentValues)
  m.assertNotInvalid(component.category_component.category_slug)
  m.assertNotInvalid(component.category_component.category_row)
  m.assertNotInvalid(component.category_component.content_tile)
  m.assertNotInvalid(component.category_component.content_tile.col)
  m.assertNotInvalid(component.category_component.content_tile.row)
  m.assertNotInvalid(component.category_component.content_tile.video_id)

End Function


'@Test getAnalyticsTile unit tests
Function tubiTracking_getAnalyticsTile_test()
  Tracking = m.Tracking
  content = CreateObject("roSGNode", "TubiContentNode")

  'test series with correct id format
  content.type = "series"
  content.id = "0123"
  col = 4
  row = 2
  tile = Tracking.getAnalyticsTile(content, col, row)
  m.assertInvalid(tile.video_id)
  m.assertTrue(tile.series_id = 123)
  m.assertTrue(tile.col = col)
  m.assertTrue(tile.row = row)

  'test series with wrong id format
  content.type = "series"
  content.id = "123"
  col = 4
  row = 2
  tile = Tracking.getAnalyticsTile(content, col, row)
  m.assertInvalid(tile.video_id)
  m.assertTrue(tile.series_id = 123)
  m.assertTrue(tile.col = col)
  m.assertTrue(tile.row = row)

  'test video with wrong id format
  content.type = "video"
  content.id = "456"
  col = 1
  row = 3
  tile = Tracking.getAnalyticsTile(content, col, row)
  m.assertInvalid(tile.series_id)
  m.assertTrue(tile.video_id = 456)
  m.assertTrue(tile.col = col)
  m.assertTrue(tile.row = row)

End Function


'@Test getAnalyticsSelector unit tests
Function tubiTracking_getAnalyticsSelector_test()
  Tracking = m.Tracking

  ' test string selector
  stringSelectorValues = {
    options: "red, blue, pink, yellow"
    selections: [2]
    string_selector_type: "GENERIC_SURVEY" 'StringSelectorComponent.type enum
    sub_type: "favorite-color"
  }
  stringSelector = Tracking.getAnalyticsSelector("string_selector", stringSelectorValues)

  m.assertNotInvalid(stringSelector)
  m.assertNotInvalid(stringSelector.string_selector)
  m.assertNotInvalid(stringSelector.string_selector.options)
  m.assertEqual(stringSelector.string_selector.options, "red, blue, pink, yellow")
  m.assertNotInvalid(stringSelector.string_selector.selections)
  m.assertEqual(stringSelector.string_selector.selections[0], 2)
  m.assertNotInvalid(stringSelector.string_selector.string_selector_type)
  m.assertEqual(stringSelector.string_selector.string_selector_type, "GENERIC_SURVEY")
  m.assertNotInvalid(stringSelector.string_selector.sub_type)
  m.assertEqual(stringSelector.string_selector.sub_type, "favorite-color")

  ' test string selector empty selection
  stringSelectorValues = {
    options: "red, blue, pink, yellow"
    selections: []
    string_selector_type: "GENERIC_SURVEY" 'StringSelectorComponent.type enum
    sub_type: "favorite-color"
  }
  stringSelector = Tracking.getAnalyticsSelector("string_selector", stringSelectorValues)

  m.assertNotInvalid(stringSelector)
  m.assertNotInvalid(stringSelector.string_selector)
  m.assertNotInvalid(stringSelector.string_selector.options)
  m.assertEqual(stringSelector.string_selector.options, "red, blue, pink, yellow")
  m.assertNotInvalid(stringSelector.string_selector.selections)
  m.assertEqual(stringSelector.string_selector.selections.count(), 0)
  m.assertNotInvalid(stringSelector.string_selector.string_selector_type)
  m.assertEqual(stringSelector.string_selector.string_selector_type, "GENERIC_SURVEY")
  m.assertNotInvalid(stringSelector.string_selector.sub_type)
  m.assertEqual(stringSelector.string_selector.sub_type, "favorite-color")

  ' test content selector
  tile1 = {
    video_id: 34567
    row: 1
    col: 1
  }
  tile2 = {
    video_id: 34568
    row: 1
    col: 2
  }
  tile3 = {
    video_id: 34569
    row: 1
    col: 3
  }
  contentSelectorValues = {
    tiles: [tile1, tile2, tile3]
    selections: [1, 3]
  }
  contentSelector = Tracking.getAnalyticsSelector("content_selector", contentSelectorValues)

  m.assertNotInvalid(contentSelector)
  m.assertNotInvalid(contentSelector.content_selector)
  m.assertNotInvalid(contentSelector.content_selector.tiles)
  m.assertEqual(contentSelector.content_selector.tiles.count(), 3)
  m.assertEqual(contentSelector.content_selector.tiles[0].video_id, 34567)
  m.assertEqual(contentSelector.content_selector.tiles[1].video_id, 34568)
  m.assertEqual(contentSelector.content_selector.tiles[2].video_id, 34569)
  m.assertEqual(contentSelector.content_selector.tiles[0].row, 1)
  m.assertEqual(contentSelector.content_selector.tiles[1].row, 1)
  m.assertEqual(contentSelector.content_selector.tiles[2].row, 1)
  m.assertEqual(contentSelector.content_selector.tiles[0].col, 1)
  m.assertEqual(contentSelector.content_selector.tiles[1].col, 2)
  m.assertEqual(contentSelector.content_selector.tiles[2].col, 3)
  m.assertNotInvalid(contentSelector.content_selector.selections)
  m.assertEqual(contentSelector.content_selector.selections.count(), 2)
  m.assertEqual(contentSelector.content_selector.selections[0], 1)
  m.assertEqual(contentSelector.content_selector.selections[1], 3)
End Function


'@Test getAnalyticsAd unit tests
Function tubiTracking_getAnalyticsAd_test()
  Tracking = m.Tracking

  adVideoId = "10001694"
  streams = [
    {
      bitrate: 635
      height: 240
      mimetype: "video/mp4"
      provider: ""
      url: "http://paella.adrise.tv/020267/" + adVideoId + "/v1101141528-640x360-SD-762k.mp4"
      width: 320
      id: adVideoId
    }
  ]

  parentId = "k2pwCTksUNmYmsrnORPU"
  impressionId = parentId + "/1"
  adTracking = [
    {
      event: "Impression"
      time: 0
      triggered: true
      url: "https://rainmaker.staging-public.tubi.io/pixel/" + impressionId + "/progress0"
    }
  ]

  clickthrough = {
    breaks: [0.0, 512.0, 911.0, 1423.0, 1875.0, 2569.0, 3175.0, 3640.0, 4249.0]
    request_id: parentId
    impression_id: impressionId
    ad_video_id: adVideoId
  }

  ad = {
    adid: "preroll-1"
    adserver: "http://rainmaker.staging-public.tubi.io/rev/ROKU?now_pos=0&model=4400X&video_id=460055&app_id=tubitv&language=en&device_id=63961250-390b-543e-a1d2-7f761b049623&content_type=mp4&opt_out=0&adv_id=d0b0ea57-caa1-5a04-840b-741517492b7a&pub_id=f866e2677ea2f0dff719788e4f7f9195"
    adtitle: "In-Stream Video"
    advideoid: adVideoId
    clickthrough: FormatJson(clickthrough)
    ' companionads: companionAds
    creativeadid: "17722"
    creativeid: "28697"
    duration: 30
    impressionid: impressionId
    isadvertising: true
    minbandwidth: 250
    parentid: parentId
    programid: "RAF:preroll-1"
    streamformat: "mp4"
    streams: streams
    switchingstrategy: "full-adaptation"
    tracking: adTracking
  }

  adInfo = ParseJson(ad.clickthrough)
  ad.parentid = adInfo.request_id
  ad.impressionid = adInfo.impression_id
  ad.advideoid = adInfo.ad_video_id.toStr()

  ctx = {
    ad: ad
    adcount: 3
    adindex: 1
    adserver: "http://rainmaker.staging-public.tubi.io/rev/ROKU?now_pos=0&model=4400X&video_id=460055&app_id=tubitv&language=en&device_id=63961250-390b-543e-a1d2-7f761b049623&content_type=mp4&opt_out=0&adv_id=d0b0ea57-caa1-5a04-840b-741517492b7a&pub_id=f866e2677ea2f0dff719788e4f7f9195"
    duration: 30
    rendersequence: "preroll"
    time: 22
  }

  adEvent = Tracking.getAnalyticsAd(ctx)

  m.assertNotInvalid(adEvent.ad_type)
  m.assertTrue(adEvent.ad_type = "VAST")
  m.assertTrue(adEvent.ad_id = ad.creativeadid)
  m.assertTrue(adEvent.creative_id = ad.creativeId.toInt())
  m.assertTrue(adEvent.creative_url = streams[0].url)
  m.assertTrue(adEvent.ad_video_id = ad.adVideoId)
  m.assertTrue(adEvent.reported_duration = ad.duration * 1000)
  m.assertTrue(adEvent.index = ctx.adindex)
  m.assertTrue(adEvent.pod_size = ctx.adcount)
End Function


'@Test populateMessage unit tests
Function tubiTracking_populateMessage_test()
  Tracking = m.Tracking

  messageType = "subtitles_toggle"
  messageBase = {
    video_id: -1
    toggle_state: "" 'ToggleState enum
    language_code: "" 'Language enum
  }
  messageValues = {
    video_id: 111770
    toggle_state: "ON" 'ToggleState enum
    language_code: "EN" 'Language enum
  }

  'with message base
  populatedMessage = Tracking.populateMessage(messageType, messageValues, messageBase)
  m.assertTrue(populatedMessage.subtitles_toggle.video_id = messageValues.video_id)
  m.assertTrue(populatedMessage.subtitles_toggle.toggle_state = messageValues.toggle_state)
  m.assertTrue(populatedMessage.subtitles_toggle.language = messageValues.language)

  'without message base
  populatedMessage = Tracking.populateMessage(messageType, messageValues, invalid)
  m.assertInvalid(populatedMessage)

  'with empty message values
  messageValues = {
    toggle_state: "" 'ToggleState enum
    language_code: "EN" 'Language enum
  }
  populatedMessage = Tracking.populateMessage(messageType, messageValues, messageBase)
  m.assertInvalid(populatedMessage.subtitles_toggle.video_id)
  m.assertInvalid(populatedMessage.subtitles_toggle.toggle_state)
  m.assertTrue(populatedMessage.subtitles_toggle.language = messageValues.language)

End Function


'@Test isEmptyValue unit tests
Function tubiTracking_isEmptyValue_test()
  Tracking = m.Tracking

  emptyString = ""
  fullString = "hi"
  emptyInt = -1
  fullInt0 = 0
  fullInt1 = 1
  emptyFloat = -1.23
  fullFloat = 4.56
  emptyDouble = -1.23#
  fullDouble = 1.23#
  emptyArray = []
  fullArray = ["a"]
  emptyAA = {}
  fullAA = { a: "hi" }

  m.assertTrue(Tracking.isEmptyValue(emptyString))
  m.assertFalse(Tracking.isEmptyValue(fullString))
  m.assertFalse(Tracking.isEmptyValue(emptyInt))
  m.assertFalse(Tracking.isEmptyValue(fullInt0))
  m.assertFalse(Tracking.isEmptyValue(fullInt1))
  m.assertFalse(Tracking.isEmptyValue(emptyFloat))
  m.assertFalse(Tracking.isEmptyValue(fullFloat))
  m.assertFalse(Tracking.isEmptyValue(emptyDouble))
  m.assertFalse(Tracking.isEmptyValue(fullDouble))
  m.assertTrue(Tracking.isEmptyValue(emptyArray))
  m.assertFalse(Tracking.isEmptyValue(fullArray))
  m.assertTrue(Tracking.isEmptyValue(emptyAA))
  m.assertFalse(Tracking.isEmptyValue(fullAA))

End Function


'@Test isNumeric unit tests
Function tubiTracking_isNumeric_test()
  Tracking = m.Tracking

  i = 4
  d = 1.45#
  f = 1.23
  s = "hi"
  a = [0]
  aa = { a: 0 }
  n = CreateObject("roSGNode", "ContentNode")
  inv = invalid

  m.assertTrue(Tracking.isNumeric(i))
  m.assertTrue(Tracking.isNumeric(d))
  m.assertTrue(Tracking.isNumeric(f))
  m.assertFalse(Tracking.isNumeric(s))
  m.assertFalse(Tracking.isNumeric(a))
  m.assertFalse(Tracking.isNumeric(aa))
  m.assertFalse(Tracking.isNumeric(n))
  m.assertFalse(Tracking.isNumeric(inv))

End Function


'@Test getLanguageCode unit tests
Function tubiTracking_getLanguageCode_test()

  languageCode = m.Tracking.getLanguageCode("ENG")
  m.assertEqual(languageCode, "EN")

  languageCode = m.Tracking.getLanguageCode("en")
  m.assertEqual(languageCode, "EN")

  languageCode = m.Tracking.getLanguageCode("SPA")
  m.assertEqual(languageCode, "ES")

  languageCode = m.Tracking.getLanguageCode("es")
  m.assertEqual(languageCode, "ES")

  languageCode = m.Tracking.getLanguageCode("FRA")
  m.assertEqual(languageCode, "FR")

  languageCode = m.Tracking.getLanguageCode("FRE")
  m.assertEqual(languageCode, "FR")

  languageCode = m.Tracking.getLanguageCode("fr")
  m.assertEqual(languageCode, "FR")

  languageCode = m.Tracking.getLanguageCode("GER")
  m.assertEqual(languageCode, "DE")

  languageCode = m.Tracking.getLanguageCode("DUE")
  m.assertEqual(languageCode, "DE")

  languageCode = m.Tracking.getLanguageCode("de")
  m.assertEqual(languageCode, "DE")

  languageCode = m.Tracking.getLanguageCode("POR")
  m.assertEqual(languageCode, "PT")

  languageCode = m.Tracking.getLanguageCode("pt")
  m.assertEqual(languageCode, "PT")

  languageCode = m.Tracking.getLanguageCode("ITA")
  m.assertEqual(languageCode, "IT")

  languageCode = m.Tracking.getLanguageCode("it")
  m.assertEqual(languageCode, "IT")

  languageCode = m.Tracking.getLanguageCode("JPN")
  m.assertEqual(languageCode, "JA")

  languageCode = m.Tracking.getLanguageCode("ja")
  m.assertEqual(languageCode, "JA")

  languageCode = m.Tracking.getLanguageCode("KOR")
  m.assertEqual(languageCode, "KO")

  languageCode = m.Tracking.getLanguageCode("ko")
  m.assertEqual(languageCode, "KO")

  languageCode = m.Tracking.getLanguageCode("CHI")
  m.assertEqual(languageCode, "ZH")

  languageCode = m.Tracking.getLanguageCode("ZHO")
  m.assertEqual(languageCode, "ZH")

  languageCode = m.Tracking.getLanguageCode("zh")
  m.assertEqual(languageCode, "ZH")

  ' Passing a 4 digit code which is not in the if else conditions.
  languageCode = m.Tracking.getLanguageCode("abcd")
  m.assertEqual(languageCode, "UNKNOWN")

  ' Passing a code which is not in the if else conditions.
  languageCode = m.Tracking.getLanguageCode("jfk")
  m.assertEqual(languageCode, "UNKNOWN")

  ' Passing invalid which will return UNKNOWN.
  languageCode = m.Tracking.getLanguageCode(invalid)
  m.assertEqual(languageCode, "UNKNOWN")

  ' Passing an integer which will return UNKNOWN.
  languageCode = m.Tracking.getLanguageCode(5)
  m.assertEqual(languageCode, "UNKNOWN")

  ' Passing a empty string which will return UNKNOWN.
  languageCode = m.Tracking.getLanguageCode("")
  m.assertEqual(languageCode, "UNKNOWN")

End Function


'@Test createViewableImpressionTrackingReqInfo unit tests
Function tubiTracking_createViewableImpressionTrackingReqInfo_test()
  constants = getConstants()
  body = {
    platform: "Roku"
    user_id: "1234"
  }
  req = m.Tracking.createViewableImpressionTrackingReqInfo(body)
  requestBody = ParseJson(req.options.body)
  m.assertNotInvalid(req)
  m.assertEqual(req.options.method, "POST")
  m.assertNotEmpty(req.options.body)
  m.assertEqual(constants.urls.impressionEvents.singleEvent, req.url)
  m.assertEqual(body.platform, requestBody.platform)
  m.assertEqual(body.user_id, requestBody.user_id)
End Function


'@Test getViewableImpressionEvent unit tests
Function tubiTracking_getViewableImpressionEvent_test()
  constants = getConstants()
  data = {
    containers: [
      {
        id: "featured"
        contents: []
      }
    ]
  }
  eventInfo = m.Tracking.getViewableImpressionEvent(data)

  m.assertEqual(eventInfo.device_id, constants.deviceInfo.deviceId)
  date = CreateObject("roDateTime")
  currentDay = date.GetDayOfMonth()
  date.FromISO8601String(eventInfo.sent_timestamp)
  m.assertEqual(currentDay, date.GetDayOfMonth())
  m.assertEqual(eventInfo.platform, constants.analyticsPlatform)
  m.assertArrayCount(eventInfo.containers, 1)
  m.assertAAHasKey(eventInfo, "user_id")
End Function


'@Test generateQoSRealtimeMetrics unit tests
Function tubiTracking_generateQoSRealtimeMetrics_test()
  tracking = m.tracking

  data = {
    adViewTime: 0
    contentFirstFrameDuration: 1445
    startupFailure: 0
    viewTime: 5
    adFirstFrameDuration: 3
    dummyInfo: 8
    seekCount: 2
  }

  cdn = "cloudfront"
  trackData = tracking.generateQoSRealtimeMetrics(data, cdn)
  m.assertNotInvalid(trackData)
  m.assertNotInvalid(trackData.distribution)
  m.assertArrayCount(trackData.distribution, 2)
  m.assertEqual(trackData.distribution[0].tags.cdn, "cloudfront")
  m.assertNotInvalid(trackData.increment)
  m.assertArrayCount(trackData.increment, 4)
  m.assertEqual(trackData.increment[0].tags.cdn, "cloudfront")

  data = {
    adViewTime: 0
    contentFirstFrameDuration: 1445
    viewTime: 5
    adFirstFrameDuration: 3
    dummyInfo: 8
  }

  cdn = "akamai"
  trackData = tracking.generateQoSRealtimeMetrics(data, cdn)
  m.assertNotInvalid(trackData)
  m.assertNotInvalid(trackData.distribution)
  m.assertArrayCount(trackData.distribution, 0)
  m.assertNotInvalid(trackData.increment)
  m.assertArrayCount(trackData.increment, 4)
  m.assertEqual(trackData.increment[0].tags.cdn, "akamai")

  data = {
    dummyInfo: 8
  }

  trackData = tracking.generateQoSRealtimeMetrics(data, cdn)
  m.assertNotInvalid(trackData)
  m.assertNotInvalid(trackData.distribution)
  m.assertArrayCount(trackData.distribution, 0)
  m.assertNotInvalid(trackData.increment)
  m.assertArrayCount(trackData.increment, 0)
End Function
