Library "Roku_Ads.brs"

Function init()
  m.top.functionName = "execTubiAdsTask"
  m.constants = getConstantsFromGlobal()
  m.externalConfigInfo = getExternalConfigInfoFromGlobal()
End Function


Function execTubiAdsTask()
  constants = m.constants
  adPlayerNode = m.top.adPlayerNode
  requestInstance = TubiRequest(constants.settings)
  requestQueue = TubiRequestQueue()
  auth = TubiAuth(constants)
  tracking = TubiTracking(constants, auth, adPlayerNode.userConsentsOptOutStatus, requestInstance, m.externalConfigInfo)
  m.tubiAds = TubiAds(constants, requestInstance, requestQueue, auth, tracking, m.top.adContentType)
  adShim = TubiSGPreloadedAdShim(constants, m.tubiAds)
  adShim.run(adPlayerNode)
End Function
