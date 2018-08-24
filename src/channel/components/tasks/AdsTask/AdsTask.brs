Library "Roku_Ads.brs"

Function init()
  m.top.functionName = "execAdsTask"
End Function

Function execAdsTask()
  constants = m.global.constants
  request = TubiRequest()
  requestQueue = TubiRequestQueue()
  auth = TubiAuth(constants, request)
  log = TubiLogger(constants, request, auth)
  ads = TubiAds(constants, log, request, requestQueue, auth)
  adShim = TubiSGAdShim(constants, ads)
  adShim.run(m.top.videoPlayerNode)
End Function