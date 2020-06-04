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
  m.assertInvalid(ads.getAdsListViaRoku(episodeTemplate))

  ' test RAF.setContentLength
  episodeWithoutLength = {}
  episodeWithoutLength.append(episodeTemplate)
  episodeWithoutLength.delete("length")
  m.assertInvalid(ads.getAdsListViaRoku(episodeWithoutLength))

  ' test RAF.setContentGenre
  episodeWithGenres = {}
  episodeWithGenres.append(episodeTemplate)
  episodeWithGenres.delete("rokuGenres")
  m.assertInvalid(ads.getAdsListViaRoku(episodeWithGenres))
  ' empty genres
  episodeWithGenres["rokuGenres"] = []
  m.assertInvalid(ads.getAdsListViaRoku(episodeWithGenres))
  ' non-kids genres
  episodeWithGenres["rokuGenres"] = ["Comedy", "Drama"]
  m.assertInvalid(ads.getAdsListViaRoku(episodeWithGenres))
  ' kids genres
  episodeWithGenres["rokuGenres"] = ["Children", "Drama"]
  m.assertInvalid(ads.getAdsListViaRoku(episodeWithGenres))

  ' test RAF.setContentId
  episodeIds = {}
  episodeIds.append(episodeTemplate)
  ' no series info
  episodeIds.delete("isParentSeries")
  episodeIds.delete("parentTitle")
  m.assertInvalid(ads.getAdsListViaRoku(episodeIds))
  ' missing only parent title
  episodeIds["isParentSeries"] = true
  episodeIds.delete("parentTitle")
  m.assertInvalid(ads.getAdsListViaRoku(episodeIds))
  ' missing only isParentSeries
  episodeIds.delete("isParentSeries")
  episodeIds["parentTitle"] = "Fake Parent"
  m.assertInvalid(ads.getAdsListViaRoku(episodeIds))
  ' valid series
  episodeIds["isParentSeries"] = true
  episodeIds["parentTitle"] = "Fake Parent"
  m.assertInvalid(ads.getAdsListViaRoku(episodeIds))
  ' invalid series and missing title fallback
  episodeIds.delete("isParentSeries")
  episodeIds.delete("parentTitle")
  episodeIds.delete("title")
  m.assertInvalid(ads.getAdsListViaRoku(episodeIds))
  
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
