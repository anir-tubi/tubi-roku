'@TestSuite [TubiAds] TubiAds.brs
Library "Roku_Ads.brs"


'@Setup
Function TubiAds_testSetup()
  m.constants = getConstants()
  request = TubiRequest()
  requestQueue = TubiRequestQueue()
  auth = TubiAuth(m.constants, request)
  tracking = TubiTracking(m.constants, request, auth)
  m.ads = TubiAds(m.constants, request, requestQueue, auth, tracking, "mp4")
  m.adsLimited = TubiAdsLimited(m.constants, auth)

  m.ads.populateUrl = Function(episode)
    ' deliberately fake so it fails and RAF.getAds() returns invalid
    return "http://127.0.0.1/"
  End Function
End Function


'@BeforeEach
Function TubiAds_testBeforeEach() as void
  m.stubContent = {
    id: "12345"
    pubid: "publisher_id"
    videoSponsorExposureId: ""
  }

  m.ads.constants.deviceInfo.isAdIdTrackingDisabled = true

  ' stub logged out user to start with
  m.ads.auth.getAuthInfo = Function()
    return {}
  End Function
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiAds.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

' TESTED WITH RAF 2.0314 on firmware 8.0.0-4128-04

'@Test tubiAds_getAdsListViaRoku failure unit tests
Function tubiAds_getAdsListViaRoku_failure_test()
  episodeTemplate = {
    "title": "Fake Episode"
    "length": 1000
    "rokuGenres": []
    "isParentSeries": false
    "parentTitle": "Fake Parent"
    "nowPos": 0
  }

  ' test default flow
  m.assertInvalid(m.ads.getAdsListViaRoku(episodeTemplate, 0))

  ' test RAF.setContentLength
  episodeWithoutLength = {}
  episodeWithoutLength.append(episodeTemplate)
  episodeWithoutLength.delete("length")
  m.assertInvalid(m.ads.getAdsListViaRoku(episodeWithoutLength, 0))

  ' test RAF.setContentGenre
  episodeWithGenres = {}
  episodeWithGenres.append(episodeTemplate)
  episodeWithGenres.delete("rokuGenres")
  m.assertInvalid(m.ads.getAdsListViaRoku(episodeWithGenres, 0))
  ' empty genres
  episodeWithGenres["rokuGenres"] = []
  m.assertInvalid(m.ads.getAdsListViaRoku(episodeWithGenres, 0))
  ' non-kids genres
  episodeWithGenres["rokuGenres"] = ["Comedy", "Drama"]
  m.assertInvalid(m.ads.getAdsListViaRoku(episodeWithGenres, 0))
  ' kids genres
  episodeWithGenres["rokuGenres"] = ["Children", "Drama"]
  m.assertInvalid(m.ads.getAdsListViaRoku(episodeWithGenres, 0))

  ' test RAF.setContentId
  episodeIds = {}
  episodeIds.append(episodeTemplate)
  ' no series info
  episodeIds.delete("isParentSeries")
  episodeIds.delete("parentTitle")
  m.assertInvalid(m.ads.getAdsListViaRoku(episodeIds, 0))
  ' missing only parent title
  episodeIds["isParentSeries"] = true
  episodeIds.delete("parentTitle")
  m.assertInvalid(m.ads.getAdsListViaRoku(episodeIds, 0))
  ' missing only isParentSeries
  episodeIds.delete("isParentSeries")
  episodeIds["parentTitle"] = "Fake Parent"
  m.assertInvalid(m.ads.getAdsListViaRoku(episodeIds, 0))
  ' valid series
  episodeIds["isParentSeries"] = true
  episodeIds["parentTitle"] = "Fake Parent"
  m.assertInvalid(m.ads.getAdsListViaRoku(episodeIds, 0))
  ' invalid series and missing title fallback
  episodeIds.delete("isParentSeries")
  episodeIds.delete("parentTitle")
  episodeIds.delete("title")
  m.assertInvalid(m.ads.getAdsListViaRoku(episodeIds, 0))
End Function


'@Test tubiAds_getRainmakerParams unit tests
Function tubiAds_getRainmakerParams_test()
  params = m.ads.getRainmakerParams(m.stubContent, 126.4)

  m.assertEqual(type(params), "roAssociativeArray")
  m.assertEqual(params.content_id, "12345")
  m.assertEqual(params.pub_id, "publisher_id")
  m.assertEqual(params.now_pos, "126")
  m.assertEqual(params.content_type, "mp4")
  m.assertEqual(params.device_id, m.constants.deviceInfo.deviceId)
  m.assertEqual(params.model, m.constants.deviceInfo.model)
  m.assertEqual(params.app_id, m.constants.settings.shortAppName)
  m.assertEqual(params.language, m.constants.deviceInfo.language)
  m.assertEqual(params.app_mode, "DEFAULT_MODE")
  m.assertEqual(params.client_version, m.constants.deviceInfo.clientVersion)
  m.assertEqual(type(params.nsid), "String")
  m.assertEqual(params.nsid.len(), 16)
  m.assertInvalid(params.spon_exp) 'spon_exp not added by default
  m.assertEqual(params.adv_id, m.constants.deviceInfo.deviceAdId)
  m.assertEqual(params.opt_out, "true")
  m.assertInvalid(params.user_id)

  ' test non default values
  m.ads.constants.deviceInfo.isAdIdTrackingDisabled = false

  ' stub logged out user to start with
  m.ads.auth.getAuthInfo = Function()
    return {userId: "3333"}
  End Function

  m.ads.appMode = "KIDS_MODE"

  m.stubContent.videoSponsorExposureId = "toyoda"

  params = m.ads.getRainmakerParams(m.stubContent, 126.7)

  m.assertEqual(type(params), "roAssociativeArray")
  m.assertEqual(params.content_id, "12345")
  m.assertEqual(params.pub_id, "publisher_id")
  m.assertEqual(params.now_pos, "127")
  m.assertEqual(params.content_type, "mp4")
  m.assertEqual(params.device_id, m.constants.deviceInfo.deviceId)
  m.assertEqual(params.model, m.constants.deviceInfo.model)
  m.assertEqual(params.app_id, m.constants.settings.shortAppName)
  m.assertEqual(params.language, m.constants.deviceInfo.language)
  m.assertEqual(params.app_mode, "KIDS_MODE")
  m.assertEqual(params.client_version, m.constants.deviceInfo.clientVersion)
  m.assertEqual(type(params.nsid), "String")
  m.assertEqual(params.nsid.len(), 16)
  m.assertEqual(params.spon_exp, "toyoda")
  m.assertEqual(params.adv_id, m.constants.deviceInfo.deviceAdId)
  m.assertEqual(params.opt_out, "false")
  m.assertEqual(params.user_id, "3333")
End Function


'@Test tubiAds_getRainmakerParamsForLinear unit tests
Function tubiAds_getRainmakerParamsForLinear_test()
  params = m.adsLimited.getRainmakerParamsForLinear(m.stubContent)

  m.assertEqual(type(params), "roAssociativeArray")
  m.assertEqual(params.content_id, "12345")
  m.assertEqual(params.pub_id, "publisher_id")
  m.assertEqual(params.now_pos, "0")
  m.assertEqual(params.content_type, "mp4")
  m.assertEqual(params.device_id, m.constants.deviceInfo.deviceId)
  m.assertEqual(params.model, m.constants.deviceInfo.model)
  m.assertEqual(params.app_id, m.constants.settings.shortAppName)
  m.assertEqual(params.language, m.constants.deviceInfo.language)
  m.assertEqual(params.app_mode, "DEFAULT_MODE")
  m.assertEqual(params.client_version, m.constants.deviceInfo.clientVersion)
  m.assertInvalid(params.nsid)
  m.assertInvalid(params.spon_exp) 'spon_exp not added by default
  m.assertEqual(params.adv_id, m.constants.deviceInfo.deviceAdId)
  m.assertEqual(params.opt_out, "true")
  m.assertInvalid(params.user_id)
  m.assertEqual(params.platform, m.constants.analyticsPlatform)
End Function


'@Test getNielsenPingRequestInfo unit tests
Function tubiAds_getNielsenPingRequestInfo_test()
  content = CreateObject("roSGNode", "TubiContentNode")
  content.id = "12345"
  sessionStart = m.constants.thirdParty.nielsen.pingTypes.sessionStart
  reqInfo = m.adsLimited.getNielsenPingRequestInfo(m.ads.constants, sessionStart)

  m.assertNotInvalid(reqInfo.url)
  m.assertNotInvalid(reqInfo.options)
  m.assertNotInvalid(reqInfo.options.params)
  m.assertEqual(reqInfo.options.headers["Content-Type"], "text/plain")

  m.assertEqual(reqInfo.options.params.prd, "audit")
  m.assertEqual(reqInfo.options.params.apid, m.ads.constants.thirdParty.nielsen.pingToken)
  m.assertEqual(type(reqInfo.options.params.sessionid), "String")
  m.assertEqual(reqInfo.options.params.sessionid.len(), 16)
  m.assertEqual(reqInfo.options.params.pingtype, "0")
  m.assertEqual(reqInfo.options.params.product, "dar")
  m.assertEqual(type(reqInfo.options.params.createtm), "roInteger")
  m.assertInvalid(reqInfo.options.params.streamId)
  m.assertEqual(reqInfo.options.params.devid, m.ads.constants.deviceInfo.deviceAdId)
  m.assertEqual(reqInfo.options.params.uoo, "1")
  m.assertEqual(reqInfo.options.params.intid, m.ads.constants.thirdParty.nielsen.intId)


  ' test with some non default values
  m.ads.constants.deviceInfo.isAdIdTrackingDisabled = false
  streamStart = m.constants.thirdParty.nielsen.pingTypes.streamStart
  reqInfo = m.adsLimited.getNielsenPingRequestInfo(m.ads.constants, streamStart, content)

  m.assertEqual(reqInfo.options.params.prd, "audit")
  m.assertEqual(reqInfo.options.params.apid, m.ads.constants.thirdParty.nielsen.pingToken)
  m.assertEqual(type(reqInfo.options.params.sessionid), "String")
  m.assertEqual(reqInfo.options.params.sessionid.len(), 16)
  m.assertEqual(reqInfo.options.params.pingtype, "1")
  m.assertEqual(reqInfo.options.params.product, "dar")
  m.assertEqual(type(reqInfo.options.params.createtm), "roInteger")
  m.assertEqual(type(reqInfo.options.params.streamid), "String")
  m.assertEqual(reqInfo.options.params.streamid.len(), 16)
  m.assertEqual(reqInfo.options.params.devid, m.ads.constants.deviceInfo.deviceAdId)
  m.assertEqual(reqInfo.options.params.uoo, "0")
  m.assertEqual(reqInfo.options.params.intid, m.ads.constants.thirdParty.nielsen.intId)

  sessionEnd = m.constants.thirdParty.nielsen.pingTypes.sessionEnd
  reqInfo = m.adsLimited.getNielsenPingRequestInfo(m.ads.constants, sessionEnd)

  m.assertEqual(reqInfo.options.params.prd, "audit")
  m.assertEqual(reqInfo.options.params.apid, m.ads.constants.thirdParty.nielsen.pingToken)
  m.assertEqual(type(reqInfo.options.params.sessionid), "String")
  m.assertEqual(reqInfo.options.params.sessionid.len(), 16)
  m.assertEqual(reqInfo.options.params.pingtype, "2")
  m.assertEqual(reqInfo.options.params.product, "dar")
  m.assertEqual(type(reqInfo.options.params.createtm), "roInteger")
  m.assertInvalid(reqInfo.options.params.streamId)
  m.assertEqual(reqInfo.options.params.devid, m.ads.constants.deviceInfo.deviceAdId)
  m.assertEqual(reqInfo.options.params.uoo, "0")
  m.assertEqual(reqInfo.options.params.intid, m.ads.constants.thirdParty.nielsen.intId)

  streamEnd = m.constants.thirdParty.nielsen.pingTypes.streamEnd
  reqInfo = m.adsLimited.getNielsenPingRequestInfo(m.ads.constants, streamEnd, content)

  m.assertEqual(reqInfo.options.params.prd, "audit")
  m.assertEqual(reqInfo.options.params.apid, m.ads.constants.thirdParty.nielsen.pingToken)
  m.assertEqual(type(reqInfo.options.params.sessionid), "String")
  m.assertEqual(reqInfo.options.params.sessionid.len(), 16)
  m.assertEqual(reqInfo.options.params.pingtype, "3")
  m.assertEqual(reqInfo.options.params.product, "dar")
  m.assertEqual(type(reqInfo.options.params.createtm), "roInteger")
  m.assertEqual(type(reqInfo.options.params.streamid), "String")
  m.assertEqual(reqInfo.options.params.streamid.len(), 16)
  m.assertEqual(reqInfo.options.params.devid, m.ads.constants.deviceInfo.deviceAdId)
  m.assertEqual(reqInfo.options.params.uoo, "0")
  m.assertEqual(reqInfo.options.params.intid, m.ads.constants.thirdParty.nielsen.intId)
End Function


'@Test tubiAds_getNielsenSessionId unit tests
Function tubiAds_getNielsenSessionId_test()
  nielsenSessionId = m.adsLimited.getNielsenSessionId(m.ads.constants)
  m.assertEqual(nielsenSessionId.len(), 16)
End Function


'@Test tubiAds_getNielsenStreamId unit tests
Function tubiAds_getNielsenStreamId_test()
  content = CreateObject("roSGNode", "TubiContentNode")
  content.id = "12345"

  nielsenStreamId = m.adsLimited.getNielsenStreamId(m.ads.constants, content)
  m.assertEqual(nielsenStreamId.len(), 16)

  nielsenStreamId = m.adsLimited.getNielsenStreamId(m.ads.constants, invalid)
  m.assertEqual(nielsenStreamId.len(), 0)

  content.id = ""
  nielsenStreamId = m.adsLimited.getNielsenStreamId(m.ads.constants, content)
  m.assertEqual(nielsenStreamId.len(), 0)
End Function


'@Test tubiAds_replaceMacro unit tests
Function tubiAds_replaceMacro_test()
  adUrl = "https://ads.staging-public.tubi.io/pixel/v3/pause/notUsed/ROKU?pos=1&id=YVmgBRQPXTADsAkZ6pkk&data=dTehrqeUCuaEqfAbqA9y-9CIo8PbikNRI46_zzkOBAJFzaceiXXAkgEC2FFOkrFie8fgXEbPzFOBOewd88vaSEPtZnB_vJj16HzYE1pGNMR2fBpQ4b4jOfz7OVQfP8LUCFy4GL1hLJW4oq90HOksvV543C13pmb_ZtS6wBSYbxuIinemL1VH75rbFEZ0Ko1PzD0NS7OUHopu8sGU-Z_0KoeOAdJhxvqeXgA7FhYzvb2qo5_0Mp4tu9RvbQS9LR4Co1HazvwzTptZdXq62cHyzdDlbnJisbUYSHT2zlkv41PNxvED&action=%5BTUBI:NOT_USED_ACTION%5D"
  newAdUrl = m.adsLimited.replaceMacro(adUrl, "[TUBI:NOT_USED_ACTION]", "exit_pre_pod")
  expectedAdUrl = "https://ads.staging-public.tubi.io/pixel/v3/pause/notUsed/ROKU?pos=1&id=YVmgBRQPXTADsAkZ6pkk&data=dTehrqeUCuaEqfAbqA9y-9CIo8PbikNRI46_zzkOBAJFzaceiXXAkgEC2FFOkrFie8fgXEbPzFOBOewd88vaSEPtZnB_vJj16HzYE1pGNMR2fBpQ4b4jOfz7OVQfP8LUCFy4GL1hLJW4oq90HOksvV543C13pmb_ZtS6wBSYbxuIinemL1VH75rbFEZ0Ko1PzD0NS7OUHopu8sGU-Z_0KoeOAdJhxvqeXgA7FhYzvb2qo5_0Mp4tu9RvbQS9LR4Co1HazvwzTptZdXq62cHyzdDlbnJisbUYSHT2zlkv41PNxvED&action=exit_pre_pod"

  m.assertNotInvalid(newAdUrl)
  m.assertEqual(newAdUrl, expectedAdUrl)
End Function
