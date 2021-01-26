'@TestSuite [TubiAds] TubiAds.brs 
Library "Roku_Ads.brs"


'@Setup
Function TubiAdsSetup()
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiAds.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

' TESTED WITH RAF 2.0314 on firmware 8.0.0-4128-04

'@Test getAdsListViaRoku failure unit tests
Function tubiAds_getAdsListViaRoku_failure_test()
  ads = testHelper_tubiAds_createTubiAds_test()
  episodeTemplate = {
    "title": "Fake Episode"
    "length": 1000
    "rokuGenres": []
    "isParentSeries": false
    "parentTitle": "Fake Parent"
    "nowPos": 0
  }

  ' test default flow
  m.assertInvalid(ads.getAdsListViaRoku(episodeTemplate, 0))

  ' test RAF.setContentLength
  episodeWithoutLength = {}
  episodeWithoutLength.append(episodeTemplate)
  episodeWithoutLength.delete("length")
  m.assertInvalid(ads.getAdsListViaRoku(episodeWithoutLength, 0))

  ' test RAF.setContentGenre
  episodeWithGenres = {}
  episodeWithGenres.append(episodeTemplate)
  episodeWithGenres.delete("rokuGenres")
  m.assertInvalid(ads.getAdsListViaRoku(episodeWithGenres, 0))
  ' empty genres
  episodeWithGenres["rokuGenres"] = []
  m.assertInvalid(ads.getAdsListViaRoku(episodeWithGenres, 0))
  ' non-kids genres
  episodeWithGenres["rokuGenres"] = ["Comedy", "Drama"]
  m.assertInvalid(ads.getAdsListViaRoku(episodeWithGenres, 0))
  ' kids genres
  episodeWithGenres["rokuGenres"] = ["Children", "Drama"]
  m.assertInvalid(ads.getAdsListViaRoku(episodeWithGenres, 0))

  ' test RAF.setContentId
  episodeIds = {}
  episodeIds.append(episodeTemplate)
  ' no series info
  episodeIds.delete("isParentSeries")
  episodeIds.delete("parentTitle")
  m.assertInvalid(ads.getAdsListViaRoku(episodeIds, 0))
  ' missing only parent title
  episodeIds["isParentSeries"] = true
  episodeIds.delete("parentTitle")
  m.assertInvalid(ads.getAdsListViaRoku(episodeIds, 0))
  ' missing only isParentSeries
  episodeIds.delete("isParentSeries")
  episodeIds["parentTitle"] = "Fake Parent"
  m.assertInvalid(ads.getAdsListViaRoku(episodeIds, 0))
  ' valid series
  episodeIds["isParentSeries"] = true
  episodeIds["parentTitle"] = "Fake Parent"
  m.assertInvalid(ads.getAdsListViaRoku(episodeIds, 0))
  ' invalid series and missing title fallback
  episodeIds.delete("isParentSeries")
  episodeIds.delete("parentTitle")
  episodeIds.delete("title")
  m.assertInvalid(ads.getAdsListViaRoku(episodeIds, 0))
  
End Function


' helper to initialize TubiAds module and stub the request so get ads always returns nothing
Function testHelper_tubiAds_createTubiAds_test()
  constants = getConstants()
  request = TubiRequest()
  requestQueue = TubiRequestQueue()
  auth = TubiAuth(constants, request)
  translate = TubiMetadataTranslate(constants)
  tracking = TubiTracking(constants, request, auth)
  log = TubiLogger(constants, request, auth)

  port = CreateObject("roMessagePort")
  ads = TubiAds(constants, log, request, requestQueue, auth, tracking, "hls")
  ads.populateUrl = Function(episode)
    ' deliberately fake so it fails and RAF.getAds() returns invalid
    return "http://127.0.0.1/"
  end Function
  return ads
End Function
