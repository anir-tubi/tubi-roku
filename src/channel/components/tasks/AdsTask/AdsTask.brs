Library "Roku_Ads.brs"

Function init()
  m.top.functionName = "execAdsTask"
  m.constants = getConstantsFromGlobal()
End Function

Function execAdsTask()
  constants = m.constants
  videoPlayerNode = m.top.videoPlayerNode
  request = TubiRequest(constants.settings)
  requestQueue = TubiRequestQueue()
  auth = TubiAuth(constants, request)
  tracking = TubiTracking(constants, request, auth, videoPlayerNode.userConsentsOptOutStatus)

  m.tubiAds = TubiAds(constants, request, requestQueue, auth, tracking, m.top.adContentType)
  adShim = TubiSGAdShim(constants, m.tubiAds)
  adShim.run(videoPlayerNode)
End Function
