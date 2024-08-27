Library "Roku_Ads.brs"

Function init()
  m.top.functionName = "execAdsTask"
  m.constants = getConstantsFromGlobal()
  m.externalConfigInfo = getExternalConfigInfoFromGlobal()
End Function

Function execAdsTask()
  constants = m.constants
  videoPlayerNode = m.top.videoPlayerNode
  request = TubiRequest(constants.settings)
  requestQueue = TubiRequestQueue()
  auth = TubiAuth(constants)
  tracking = TubiTracking(constants, auth, videoPlayerNode.userConsentsOptOutStatus, request, m.externalConfigInfo)
  gdpr = isGDPR(constants)
  m.tubiAds = TubiAds(constants, request, requestQueue, auth, tracking, m.top.adContentType, videoPlayerNode.tcfString, videoPlayerNode.userConsentsOptOutStatus, gdpr)
  adShim = TubiSGAdShim(constants, m.tubiAds)
  adShim.run(videoPlayerNode)
End Function
