Library "Roku_Ads.brs"

Function init()
  m.top.functionName = "execAdsTask"
  m.enableInPodStitching = getExperimentResource("roku_in_pod_stitching", "roku_in_pod_stitching_v1", false).enabled = true
  m.constants = getConstantsFromGlobal()
End Function

Function execAdsTask()
  constants = m.constants
  request = TubiRequest(constants.settings)
  requestQueue = TubiRequestQueue()
  auth = TubiAuth(constants, request)
  log = TubiLogger(constants, request, auth)
  tracking = TubiTracking(constants, request, auth)
  ads = TubiAds(constants, log, request, requestQueue, auth, tracking, m.top.adContentType)
  adShim = TubiSGAdShim(constants, ads)
  adShim.run(m.top.videoPlayerNode)
End Function
