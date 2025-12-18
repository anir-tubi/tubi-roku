Library "Roku_Ads.brs"

Function init()
  m.top.functionName = "execAdsTask"
  m.constants = getConstantsFromGlobal()
  m.externalConfigInfo = getExternalConfigInfoFromGlobal()
End Function

Function execAdsTask()
  constants = m.constants
  videoPlayerNode = m.top.videoPlayerNode
  requestInstance = TubiRequest(constants.settings)
  requestQueue = TubiRequestQueue()
  auth = TubiAuth(constants)
  tracking = TubiTracking(constants, auth, videoPlayerNode.userConsentsOptOutStatus, requestInstance, m.externalConfigInfo)
  gdpr = isGDPR(constants)

  ' Get Statsig experiment for preroll timeout
  prerollTimeoutExperiment = getStatsigExperimentResource("roku_player_improvement", "roku_player_ad_preroll_timeout_v2", false)

  m.tubiAds = TubiAds(constants, requestInstance, requestQueue, auth, tracking, m.top.adContentType, videoPlayerNode.tcfString, videoPlayerNode.userConsentsOptOutStatus, gdpr, prerollTimeoutExperiment)
  adShim = TubiSGAdShim(constants, m.tubiAds)
  adShim.run(videoPlayerNode)
End Function
