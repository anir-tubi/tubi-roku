' StatsigExperimentMixin - Provides easy access to Statsig experiments
' Similar to ExperimentMixin but for Statsig experiments
'
' @namespaceName: experiment namespace
' @experimentName: experiment name
' @sendEvent: whether to send exposure tracking event (default true)
' @returns: resource config object or default if not available
'
Function getStatsigExperimentResource(namespaceName as String, experimentName as String, sendEvent = true as Boolean)
  if m.statsigExperimentsInfo = invalid then
    m.statsigExperimentsInfo = getStatsigExperimentsInfoFromGlobal()
  end if

  experiments = StatsigExperimentsInterface(m.statsigExperimentsInfo)
  resource = experiments.getExperimentResource(namespaceName, experimentName)

  if sendEvent = true AND resource <> invalid
    sendOutStatsigExperimentTracking(namespaceName, experimentName, experiments)
  end if

  return resource
End Function


' Send out Statsig experiment tracking (uses TubiTracking module)
' @namespaceName: experiment namespace
' @experimentName: experiment name
' @experiments: StatsigExperiments instance
'
Function sendOutStatsigExperimentTracking(namespaceName as String, experimentName as String, experiments)
  localGlobal = m.global

  if localGlobal <> invalid AND localGlobal.exposedStatsigExperimentParameters = invalid
    localGlobal.addField("exposedStatsigExperimentParameters", "assocarray", false)
    localGlobal.exposedStatsigExperimentParameters = {}
  end if

  if localGlobal <> invalid
    experimentTracking = experiments.getExperimentTracking(namespaceName, experimentName)

    if experimentTracking <> invalid AND localGlobal.exposedStatsigExperimentParameters[experimentName] <> true
      localGlobal.statsigExposureInfo = experimentTracking 'triggers callback in ContentController
      'set the parameter on the global store
      exposedStatsigExperimentParameters = localGlobal.exposedStatsigExperimentParameters
      exposedStatsigExperimentParameters[experimentName] = true
      m.global.exposedStatsigExperimentParameters = exposedStatsigExperimentParameters
    end if
  end if
End Function
