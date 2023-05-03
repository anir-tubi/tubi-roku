Library "Roku_Ads.brs"
Library "IMA3.brs"

Function init()
  m.top.functionName = "execAdsTask"
  m.isGooglePalIntegration = getExperimentResource("ads_configuration_roku_google_pal_integration", "roku_ads_configuration_roku_google_pal_integration_v1", true).enabled = true
  m.enableInPodStitching = getExperimentResource("roku_in_pod_stitching", "roku_in_pod_stitching_v2", false).enabled = true
  m.constants = getConstantsFromGlobal()
End Function

Function execAdsTask()
  constants = m.constants
  request = TubiRequest(constants.settings)
  requestQueue = TubiRequestQueue()
  auth = TubiAuth(constants, request)
  tracking = TubiTracking(constants, request, auth)
  nonceFrameWork = invalid

  if m.isGooglePalIntegration = true
    nonceFrameWork = New_IMASDK() 'bs:disable-line 1001 LINT1001
  end if

  m.tubiAds = TubiAds(constants, request, requestQueue, auth, tracking, m.top.adContentType, nonceFrameWork)
  adShim = TubiSGAdShim(constants, m.tubiAds)
  adShim.run(m.top.videoPlayerNode)
End Function
