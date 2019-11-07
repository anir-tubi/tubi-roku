Function TestSuite_TubiTracking()
  this = BaseTestSuite()
  this.name = "TubiTrackingTestSuite"
  this.addTest("getAnalyticsRequestIdempotency", testCase_tubiTracking_getAnalyticsRequestIdempotency)
  this.addTest("getAnalyticsTimestamp", testCase_tubiTracking_getAnalyticsTimestamp)
  this.addTest("getAnalyticsUser", testCase_tubiTracking_getAnalyticsUser)
  this.addTest("getAnalyticsDevice", testCase_tubiTracking_getAnalyticsDevice)
  this.addTest("getAnalyticsApp", testCase_tubiTracking_getAnalyticsApp)
  this.addTest("getAnalyticsConnection", testCase_tubiTracking_getAnalyticsConnection)
  this.addTest("getAnalyticsEvent", testCase_tubiTracking_getAnalyticsEvent)
  this.addTest("getAnalyticsPage", testCase_tubiTracking_getAnalyticsPage)
  this.addTest("getAnalyticsComponent", testCase_tubiTracking_getAnalyticsComponent)
  this.addTest("getAnalyticsTile", testCase_tubiTracking_getAnalyticsTile)
  this.addTest("getAnalyticsAd", testCase_tubiTracking_getAnalyticsAd)
  this.addTest("populateMessage", testCase_tubiTracking_populateMessage)
  this.addTest("isEmptyValue", testCase_tubiTracking_isEmptyValue)
  this.addTest("isNumeric", testCase_tubiTracking_isNumeric)
  return this
End Function


Function testHelper_tubiTracking_createTubiTracking()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  tracking = TubiTracking(constants, request, auth)
  return Tracking
End Function


Function testCase_tubiTracking_getAnalyticsRequestIdempotency()
  Tracking = testHelper_tubiTracking_createTubiTracking()
  idempotency = Tracking.getAnalyticsRequestIdempotency()
  
  'test that the key named "key" exists and the value is a string
  result = m.assertNotInvalid(idempotency.key)
  result += m.assertTrue(type(idempotency.key) = "roString" or type(idempotency.key) = "String")

  'test the value has the form of a UUID
  uuidBlocks = idempotency.key.split("-")
  result += m.assertTrue(uuidBlocks.count() = 5)
  result += m.assertTrue(uuidBlocks[0].len() = 8)
  result += m.assertTrue(uuidBlocks[1].len() = 4)
  result += m.assertTrue(uuidBlocks[2].len() = 4)
  result += m.assertTrue(uuidBlocks[3].len() = 4)
  result += m.assertTrue(uuidBlocks[4].len() = 12)
  return result
End Function

Function testCase_tubiTracking_getAnalyticsTimestamp()
  dateTime = CreateObject("roDateTime")
  Tracking = testHelper_tubiTracking_createTubiTracking()
  trackingTimestamp = Tracking.getAnalyticsTimestamp()
  testTimestamp = dateTime.ToISOString()

  result = m.assertEqual(trackingTimestamp, testTimestamp)
  return result
End Function

Function testCase_tubiTracking_getAnalyticsUser()
  deviceInfo = CreateObject("roDeviceInfo")
  Tracking = testHelper_tubiTracking_createTubiTracking()
  user = Tracking.getAnalyticsUser()

  result = ""
  result += m.assertNotInvalid(user.user_id)
  result += m.assertNotInvalid(user.auth_type)
  result += m.assertTrue(user.auth_type = "UNKNOWN" or user.auth_type = "NOT_AUTHED")
  result += m.assertTrue(type(user.user_id) = "roInteger")
  result += m.assertTrue((user.auth_type = "UNKNOWN" and user.user_id > 0) or (user.auth_type = "NOT_AUTHED" and user.user_id = 0))

  return result
End Function

Function testCase_tubiTracking_getAnalyticsDevice()
  constants = getConstants()
  Tracking = testHelper_tubiTracking_createTubiTracking()
  device = Tracking.getAnalyticsDevice()

  result = m.assertNotInvalid(device.device_id)
  result += m.assertNotInvalid(device.model)
  result += m.assertNotInvalid(device.os)
  result += m.assertNotInvalid(device.os_version)
  result += m.assertNotInvalid(device.user_agent)
  result += m.assertNotInvalid(device.is_mobile)
  result += m.assertNotInvalid(device.device_height)
  result += m.assertNotInvalid(device.device_width)

  if constants.deviceInfo.isAdIdTrackingDisabled <> true
    result += m.assertNotInvalid(device.advertiser_id)
  else
    result += m.assertInvalid(device.advertiser_id)
  end if

  return result
End Function

Function testCase_tubiTracking_getAnalyticsApp()
  Tracking = testHelper_tubiTracking_createTubiTracking()
  app = Tracking.getAnalyticsApp({appMode: ""})

  result = m.assertNotInvalid(app.platform)
  result += m.assertNotInvalid(app.app_version)
  result += m.assertNotInvalid(app.app_version_numeric)
  result += m.assertNotInvalid(app.app_height)
  result += m.assertNotInvalid(app.app_width)

  return result
End Function

Function testCase_tubiTracking_getAnalyticsConnection()
  Tracking = testHelper_tubiTracking_createTubiTracking()

  'event values with nominal_speed (ie. play_progress)
  eventValues = {
    nominal_speed: 130
  }
  connection = Tracking.getAnalyticsConnection(eventValues)

  result = m.assertNotInvalid(connection.network)
  result += m.assertNotInvalid(connection.nominal_speed)
  result += m.assertInvalid(connection.isp)
  result += m.assertInvalid(connection.carrier)
  result += m.assertTrue(connection.network = "WIFI" or connection.network = "ETHERNET" or connection.network = "UNKNOWN_NETWORK")


  'event values without nominal_speed (ie. play_progress)
  eventValues = {}
  connection = Tracking.getAnalyticsConnection(eventValues)

  result = m.assertNotInvalid(connection.network)
  result += m.assertInvalid(connection.nominal_speed)
  result += m.assertInvalid(connection.isp)
  result += m.assertInvalid(connection.carrier)
  result += m.assertTrue(connection.network = "WIFI" or connection.network = "ETHERNET" or connection.network = "UNKNOWN_NETWORK")

  return result
End Function

Function testCase_tubiTracking_getAnalyticsEvent()
  Tracking = testHelper_tubiTracking_createTubiTracking()

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
  result = m.assertNotInvalid(pageLoadEvent.page_load.load_time)
  result += m.assertNotInvalid(pageLoadEvent.page_load.status)
  result += m.assertNotInvalid(pageLoadEvent.page_load.category_page)

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

  result += m.assertNotInvalid(pageLoadEvent.page_load.load_time)
  result += m.assertNotInvalid(pageLoadEvent.page_load.status)
  result += m.assertInvalid(pageLoadEvent.page_load.category_page)

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

  result += m.assertInvalid(pageLoadEvent.page_load.load_time)
  result += m.assertNotInvalid(pageLoadEvent.page_load.status)
  result += m.assertNotInvalid(pageLoadEvent.page_load.category_page)

  return result
End Function

Function testCase_tubiTracking_getAnalyticsPage()
  Tracking = testHelper_tubiTracking_createTubiTracking()


  'valid page
  page = Tracking.getAnalyticsPage("search_page", {query: "home"})
  result = m.assertNotInvalid(page.search_page.query)
  result += m.assertTrue(page.search_page.query = "home")

  'valid page, empty value
  page = Tracking.getAnalyticsPage("search_page", {query: ""})
  result += m.assertInvalid(page.search_page.query)

  'not valid page
  page = Tracking.getAnalyticsPage("fake_page", {query: "home"})
  result += m.assertInvalid(page)

  return result
End Function

Function testCase_tubiTracking_getAnalyticsComponent()
  Tracking = testHelper_tubiTracking_createTubiTracking()

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
  result = m.assertNotInvalid(component.category_component.category_slug)
  result += m.assertNotInvalid(component.category_component.category_row)
  result += m.assertNotInvalid(component.category_component.content_tile)
  result += m.assertNotInvalid(component.category_component.content_tile.video_id)
  result += m.assertNotInvalid(component.category_component.content_tile.col)
  result += m.assertNotInvalid(component.category_component.content_tile.row)

  'not valid component'
  component = Tracking.getAnalyticsComponent("fake_component", componentValues)
  result += m.assertInvalid(component)

  'empty value
  componentValues.category_row = -1
  component = Tracking.getAnalyticsComponent("category_component", componentValues)
  result += m.assertNotInvalid(component.category_component.category_slug)
  result += m.assertInvalid(component.category_component.category_row)
  result += m.assertNotInvalid(component.category_component.content_tile)
  result += m.assertNotInvalid(component.category_component.content_tile.col)
  result += m.assertNotInvalid(component.category_component.content_tile.row)
  result += m.assertNotInvalid(component.category_component.content_tile.video_id)

  return result
End Function

Function testCase_tubiTracking_getAnalyticsTile()
  Tracking = testHelper_tubiTracking_createTubiTracking()
  content = CreateObject("roSGNode", "TubiContentNode")
  
  'test series with correct id format
  content.type = "series"
  content.id = "0123"
  col = 4
  row = 2
  tile = Tracking.getAnalyticsTile(content, col, row)
  result = m.assertInvalid(tile.video_id)
  result += m.assertTrue(tile.series_id = 123)
  result += m.assertTrue(tile.col = col)
  result += m.assertTrue(tile.row = row)

  'test series with wrong id format
  content.type = "series"
  content.id = "123"
  col = 4
  row = 2
  tile = Tracking.getAnalyticsTile(content, col, row)
  result += m.assertInvalid(tile.video_id)
  result += m.assertTrue(tile.series_id = 123)
  result += m.assertTrue(tile.col = col)
  result += m.assertTrue(tile.row = row)

  'test video with wrong id format
  content.type = "video"
  content.id = "456"
  col = 1
  row = 3
  tile = Tracking.getAnalyticsTile(content, col, row)
  result += m.assertInvalid(tile.series_id)
  result += m.assertTrue(tile.video_id = 456)
  result += m.assertTrue(tile.col = col)
  result += m.assertTrue(tile.row = row)

  return result
End Function

Function testCase_tubiTracking_getAnalyticsAd()
  Tracking = testHelper_tubiTracking_createTubiTracking()

  creativeId = "3120465"
  streams = [
    {
      bitrate: 400
      height: 240
      mimetype: "application/x-mpegurl"
      provider: ""
      url: "http://paella.adrise.tv/002268/" + creativeId + "/v0912161820-,426x240-SD-351,640x360-SD-708,640x360-SD-1082,640x360-SD-1395,k.mp4.m3u8"
      width: 320
    }
  ]

  podId = "KtbUw-0-0"
  impressionId = "20190111231000-" + podId
  adTracking = [
    {
      event: "Impression"
      time: 0
      triggered: true
      url: "http://ads.adrise.tv/track/view.php?id=" + impressionId
    }
  ]

  ad = {
    adid: "2508"
    adserver: "http://ads.adrise.tv/?roku-v=2.6.1&appid=tubitv&deviceid=YY00G1976937&_=1378200017&model=4400X&m-language=en&content-type=hls&sdk=raf_vast&platform=roku&advid=d0b0ea57-caa1-5a04-840b-741517492b7a&opt-out=0&pubid=96f09f7ca1a637174ba81505fac4bb6d&nowpos=0&cid=418448"
    adtitle: ""
    clickthrough: "0,405,827,1303,1760,2073,2389,2852,3259,3812,4400,4716,5085"
    ' companionads: []
    creativeadid: ""
    creativeid: ""
    duration: 15
    isadvertising: true
    minbandwidth: 250
    programid: "RAF:2508"
    streamformat: "hls"
    streams: streams
    switchingstrategy: "full-adaptation"
    tracking: adTracking
  }
  ctx = {
    ad: ad
    adcount: 3
    adindex: 1
    adserver: "http://ads.adrise.tv/?roku-v=2.6.1&appid=tubitv&deviceid=YY00G1976937&_=514576113&model=4400X&m-language=en&content-type=hls&sdk=raf_vast&platform=roku&advid=d0b0ea57-caa1-5a04-840b-741517492b7a&opt-out=0&pubid=96f09f7ca1a637174ba81505fac4bb6d&nowpos=0&cid=418448"
    duration: 17
    rendersequence: "preroll"
    time: 1
  }

  adEvent = Tracking.getAnalyticsAd(ctx)

  result = m.assertNotInvalid(adEvent.ad_type)
  result += m.assertTrue(adEvent.ad_id = ad.adid)
  result += m.assertTrue(adEvent.creative_url = streams[0].url)
  result += m.assertTrue(adEvent.creative_id = creativeId.toInt())
  result += m.assertTrue(adEvent.reported_duration = ad.duration * 1000)
  result += m.assertTrue(adEvent.impression_id = impressionId)
  ' result += m.assertTrue(adEvent.pod_id = podId)  'commented out until podId is added
  result += m.assertTrue(adEvent.index = ctx.adindex)
  result += m.assertTrue(adEvent.pod_size = ctx.adcount)

  return result
End Function

Function testCase_tubiTracking_populateMessage()
  Tracking = testHelper_tubiTracking_createTubiTracking()

  messageType = "subtitles_toggle"
  messageBase = {
    video_id: -1
    toggle_state: ""  'ToggleState enum
    language: ""  'Language enum
  }
  messageValues = {
    video_id: 111770
    toggle_state: "ON"  'ToggleState enum
    language: "EN"  'Language enum
  }

  'with message base
  populatedMessage = Tracking.populateMessage(messageType, messageValues, messageBase)
  result = m.assertTrue(populatedMessage.subtitles_toggle.video_id = messageValues.video_id)
  result += m.assertTrue(populatedMessage.subtitles_toggle.toggle_state = messageValues.toggle_state)
  result += m.assertTrue(populatedMessage.subtitles_toggle.language = messageValues.language)

  'without message base
  populatedMessage = Tracking.populateMessage(messageType, messageValues, invalid)
  result += m.assertInvalid(populatedMessage)

  'with empty message values
  messageValues = {
    toggle_state: ""  'ToggleState enum
    language: "EN"  'Language enum
  }
  populatedMessage = Tracking.populateMessage(messageType, messageValues, messageBase)
  result += m.assertInvalid(populatedMessage.subtitles_toggle.video_id)
  result += m.assertInvalid(populatedMessage.subtitles_toggle.toggle_state)
  result += m.assertTrue(populatedMessage.subtitles_toggle.language = messageValues.language)

  return result
End Function

Function testCase_tubiTracking_isEmptyValue()
  Tracking = testHelper_tubiTracking_createTubiTracking()

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
  fullAA = {a: "hi"}

  result = m.assertTrue(Tracking.isEmptyValue(emptyString))
  result += m.assertFalse(Tracking.isEmptyValue(fullString))
  result += m.assertTrue(Tracking.isEmptyValue(emptyInt))
  result += m.assertFalse(Tracking.isEmptyValue(fullInt0))
  result += m.assertFalse(Tracking.isEmptyValue(fullInt1))
  result += m.assertTrue(Tracking.isEmptyValue(emptyFloat))
  result += m.assertFalse(Tracking.isEmptyValue(fullFloat))
  result += m.assertTrue(Tracking.isEmptyValue(emptyDouble))
  result += m.assertFalse(Tracking.isEmptyValue(fullDouble))
  result += m.assertTrue(Tracking.isEmptyValue(emptyArray))
  result += m.assertFalse(Tracking.isEmptyValue(fullArray))
  result += m.assertTrue(Tracking.isEmptyValue(emptyAA))
  result += m.assertFalse(Tracking.isEmptyValue(fullAA))

  return result
End Function

Function testCase_tubiTracking_isNumeric()
  Tracking = testHelper_tubiTracking_createTubiTracking()

  i = 4
  d = 1.45#
  f = 1.23
  s = "hi"
  a = [0]
  aa = {a:0}
  n = CreateObject("roSGNode", "ContentNode")
  inv = invalid

  result = m.assertTrue(Tracking.isNumeric(i))
  result += m.assertTrue(Tracking.isNumeric(d))
  result += m.assertTrue(Tracking.isNumeric(f))
  result += m.assertFalse(Tracking.isNumeric(s))
  result += m.assertFalse(Tracking.isNumeric(a))
  result += m.assertFalse(Tracking.isNumeric(aa))
  result += m.assertFalse(Tracking.isNumeric(n))
  result += m.assertFalse(Tracking.isNumeric(inv))

  return result
End Function
