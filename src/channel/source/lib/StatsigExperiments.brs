' StatsigExperiments - Similar to TubiExperiments but for Statsig
'
Function StatsigExperiments(constants) as Object
  return {
    statsigLib: StatsigLib(constants)
    initialize: statsigExperiments_initialize
    processStatsigResponse: statsigExperiments_processStatsigResponse
    logExposure: statsigExperiments_logExposure
  }
End Function


Function StatsigExperimentsInterface(statsigExperimentsInfo) as Object
  return {
    ' Default resources - used when Statsig doesn't return a config or fails
    ' Same structure as TubiExperiments for consistency
    defaultResources: {

      ' POC Statsig "no change" experiment on search screen
      ' It is to validate Statsig integration, exposure logging, and experiment flow.
      roku_no_change_statsig_experiment: {
        roku_no_change_statsig_experiment_v1: {
          default: { "enabled": false }
        }
      }

      roku_player_improvement: {
        ' Ad request cuepoint alignment experiment with 5 variants:
        ' Control:   prefetchTime = 15, requestWithinWindow = false (request only before 15s, not within the 15s window)
        ' Variant 1: prefetchTime = 6,  requestWithinWindow = false (request only before 6s, not within the 6s window)
        ' Variant 2: prefetchTime = 6,  requestWithinWindow = true (request before 6s and also within the 6s window)
        ' Variant 3: prefetchTime = 3,  requestWithinWindow = false (request only before 3s, not within the 3s window)
        ' Variant 4: prefetchTime = 3,  requestWithinWindow = true (request before 3s and also within the 3s window)
        roku_player_align_ad_request_cuepoint_v3: {
          default: { "prefetchTime": 15, "requestWithinWindow": false }
        }
        ' Testing autoplay of content immediately after the trailer finishes
        roku_autoplay_after_trailer_v1: {
          default: { "enabled": false }
        }
        ' Retry logic for transient network errors (-1, -2, -3) with exponential backoff
        ' When enabled: 3 retries with delays [0.5s, 1s, 2s] for network errors before fallback
        roku_player_retry_network_errors_v1: {
          default: { "enabled": false }
        }
        ' Testing the subtitle overlay feature on the vod player
        roku_player_subtitle_overlay_v1: {
          default: { "enabled": false }
        }
        ' Testing the new player ui with old loader, Possible values are none, variant1
        roku_player_control_ui_refresh_v4: {
          default: { "type": "none" }
        }
        ' Testing by including hlsv6 widevine in drm selection order
        roku_player_drm_order_hlsv6_widevine: {
          default: { "enabled": false }
        }
        ' Postplay countdown timer experiment for series (roku_postplay_countdown_timer_series_v2):
        ' Control: 15s countdown
        ' Variant 1: 3s countdown
        ' Variant 2: 3s countdown + simplified UI (no posters, only a Next Episode button)
        ' Variant 3: 3s countdown + simplified UI + automatic skip recap after autoplay
        roku_postplay_countdown_timer_series_v2: {
          default: { countdown: 15, simplifiedUI: false, automaticSkipRecap: false }
        }
      }

      roku_linear_reg_gate: {
        roku_linear_reg_gate_v1_1: {
          default: { "enabled": false }
        }
      }

      '//This experiment will be for the new showcase ad campaigns.
      '//The default "enabled" values should be where the ads are shown. If Statsig is down, we want to show the ads.
      ads_homegrid_layer: {
        ads_hdc_all_holdback_v3: {
          '// Possible variants: enabled = true (show all ads), or enabled = false (no ads shown)
          default: { "enabled": true }
        }
      }

      roku_search_screen_animate_grid: {
        roku_search_screen_animate_grid_v1: {
          default: { "enabled": true }
        }
      }

      roku_video_tiles_1_9: {
        default: { enabled: false }
      }

      roku_sot_reverse_ui_test: {
        roku_sot_reverse_ui_test_v1: {
          default: { "enabled": false }
        }
      }

      roku_multi_account: {
        roku_multi_account_v0: {
          default: { "variant": "none" } ' "none", "adult_with_kids"
        }
      }

      roku_content_details: {
        ' New content details screen experiment
        roku_content_details_v2: {
          default: { "enabled": false, "enable_left_button_exit": false }
        }
      }

      roku_sot_reverse_ui_test_detail_screen: {
        roku_sot_reverse_ui_test_detail_screen_v1: {
          default: { "enabled": false }
        }
      }

      roku_disable_magic_link: {
        roku_disable_magic_link_v1: {
          default: { "disable": false }
        }
      }

      roku_start_up_performance_test: {
        ' We are adding an additional delay in the treatment group to measure its impact on user metrics
        roku_start_up_performance_test_v1: {
          default: { "delaySeconds": 0 }
        }
      }

      roku_disable_hdmi_cec: {
        roku_disable_hdmi_cec_v1: {
          default: { "disable": false }
        }
      }

      roku_no_layer_experiment: {
        default: { "no_layer": "no" }
      }
    }
    statsigExperimentsInfo: statsigExperimentsInfo
    getExperimentResource: statsigExperiments_getExperimentResource
    getExperimentActualResource: statsigExperiments_getExperimentActualResource
    getExperimentTracking: statsigExperiments_getExperimentTracking
    getExperiment: statsigExperiments_getExperiment
    getDefaultResource: statsigExperiments_getDefaultResource
    getHashValue: statsigExperiments_getHashValue
  }
End Function


' Initializes the Statsig experiments system.
' @param successCallback: callback for successful initialization
' @param errorCallback: callback for initialization errors
'
Function statsigExperiments_initialize(successCallback = invalid, errorCallback = invalid)
  if m.statsigLib <> invalid
    m.statsigLib.initialize(successCallback, errorCallback)
  end if
End Function


' Logs an exposure event for a Statsig experiment.
' @param exposureData: assocarray, exposure information which needs to be attached in exposure event
'
Function statsigExperiments_logExposure(exposureData)
  if m.statsigLib <> invalid
    m.statsigLib.logExposure(exposureData)
  end if
End Function


' Process Statsig response and store experiments
' @param experimentInfo: Statsig initialization response after parsing
Function statsigExperiments_processStatsigResponse(experimentInfo)
  m.statsigExperimentsInfo = experimentInfo
  return experimentInfo
End Function


Function statsigExperiments_getHashValue(name as String) as String
  ba1 = CreateObject("roByteArray")
  ba1.FromAsciiString(name)
  digest = CreateObject("roEVPDigest")
  digest.Setup("sha256")
  digest.Update(ba1)
  hash = digest.Final()

  ' base64 encode the hash
  ba2 = CreateObject("roByteArray")
  ba2.FromHexString(hash)
  return ba2.ToBase64String()
End Function


' Get experiment resource from stored statsig initialize api response
' @namespaceName: experiment namespace
' @experimentName: experiment name
'
' @returns: experiment config or default if not found
'
Function statsigExperiments_getExperimentResource(namespaceName as String, experimentName as String)
  defaultResource = m.getDefaultResource(namespaceName, experimentName)
  experimentResource = m.getExperimentActualResource(namespaceName, experimentName)

  if experimentResource <> invalid
    return experimentResource
  else
    return defaultResource
  end if
End Function


' Get actual experiment resource from Statsig experiments response
' @namespaceName: experiment namespace
' @experimentName: experiment name
'
' @returns: experiment config value or invalid
Function statsigExperiments_getExperimentActualResource(namespaceName as String, experimentName as String)
  experiment = m.getExperiment(namespaceName, experimentName)

  if experiment <> invalid AND experiment.config <> invalid AND experiment.config.value <> invalid
    value = experiment.config.value
    if type(value) = "roAssociativeArray" AND value.keys().isEmpty() = false
      return experiment.config.value
    end if
  end if

  return invalid
End Function


' Get experiment from Statsig experiments response
' @namespaceName: experiment namespace
' @experimentName: experiment name
'
' @returns: experiment object or invalid
'
Function statsigExperiments_getExperiment(namespaceName as String, experimentName as String)

  if m.statsigExperimentsInfo = invalid
    return invalid
  end if

  hashedExperimentName = m.getHashValue(experimentName)
  hashedNamespaceName = m.getHashValue(namespaceName)

  if m.statsigExperimentsInfo.DoesExist(hashedExperimentName) = true
    return m.statsigExperimentsInfo[hashedExperimentName]
  else if m.statsigExperimentsInfo.DoesExist(hashedNamespaceName) = true
    return m.statsigExperimentsInfo[hashedNamespaceName]
  else
    return invalid
  end if
End Function


Function statsigExperiments_getDefaultResource(namespaceName as String, experimentName as String)
  if m.defaultResources <> invalid AND namespaceName <> "" AND m.defaultResources[namespaceName] <> invalid AND m.defaultResources[namespaceName][experimentName] <> invalid
    return m.defaultResources[namespaceName][experimentName].default
  else if m.defaultResources <> invalid AND m.defaultResources[experimentName] <> invalid
    return m.defaultResources[experimentName].default
  end if

  return invalid
End Function


' Get experiment tracking info - returns tracking data for analytics
' @namespaceName: experiment namespace
' @experimentName: experiment name
'
' @returns: exposure, tracking info object or invalid
'
Function statsigExperiments_getExperimentTracking(namespaceName as String, experimentName as String)
  experiment = m.getExperiment(namespaceName, experimentName)
  exposure = invalid

  if experiment <> invalid
    exposure = {
      "experimentName": experimentName
      "group": experiment.groupName
    }
  end if

  return exposure
End Function
