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
        ' ymal container in BWW section inside player if experiment is enabled
        roku_player_bww_ymal_v1: {
          default: { "enabled": false }
        }
        ' Ad request cuepoint alignment - fetch Ad anywhere between 3~15 second before cuepoint if experiment is enabled
        roku_player_align_ad_request_cuepoint_v1: {
          default: { "enabled": false }
        }
      }

      roku_linear_age_gate: {
        roku_linear_age_gate_v1: {
          default: { "enabled": false }
        }
      }

      roku_search_screen_animate_grid: {
        roku_search_screen_animate_grid_v1: {
          default: { "enabled": true }
        }
      }

      roku_home_screen_redesign: {
        roku_home_screen_redesign_v_1_6: {
          ' default: { "design_type": "withDescriptionPortraitSmall", should_debounce: false, gridItemSize: [310, 442], featuredRowPosterSize: [788, 442], variant: "billboard", should_dim: true }
          default: { "design_type": "none", should_debounce: false, gridItemSize: [], featuredRowPosterSize: [], variant: "", should_dim: false, debounce_time: 0 }
          holdout_control: { "design_type": "none", should_debounce: false, gridItemSize: [], featuredRowPosterSize: [], should_dim: false, debounce_time: 0 }
          holdout_winning: { "design_type": "none", should_debounce: false, gridItemSize: [], featuredRowPosterSize: [], should_dim: false, debounce_time: 0 }
        }
      }

      roku_player_ad_preroll_timeout: {
        ' Shorten the preroll ad timeout from 10s to 5s
        roku_player_ad_preroll_timeout_v1: {
          default: { "enabled": false }
        }
      }

    }
    statsigExperimentsInfo: statsigExperimentsInfo
    getExperimentResource: statsigExperiments_getExperimentResource
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
  experiment = m.getExperiment(namespaceName, experimentName)

  if experiment <> invalid AND experiment.config <> invalid AND experiment.config.value <> invalid
    return experiment.config.value
  else
    return defaultResource
  end if
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

  if m.statsigExperimentsInfo.DoesExist(hashedExperimentName)
    return m.statsigExperimentsInfo[hashedExperimentName]
  else
    return invalid
  end if
End Function


Function statsigExperiments_getDefaultResource(namespaceName as String, experimentName as String)
  if m.defaultResources <> invalid AND m.defaultResources[namespaceName] <> invalid AND m.defaultResources[namespaceName][experimentName] <> invalid
    return m.defaultResources[namespaceName][experimentName].default
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
