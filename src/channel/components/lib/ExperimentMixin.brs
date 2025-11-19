' getExperimentResource
'
' Get more info about the experiment
' Note: the component calling getExperimentResource using the ExperimentMixin, must also
' have pkg:/source/lib/Request.brs, pkg:/source/lib/GlobalMixin.brs, and pkg:/source/lib/TubiExperiments.brs added as scripts
Function getExperimentResource(namespaceName as String, experimentName as String, sendEvent = true as Boolean)
  if m.experimentsInfo = invalid then
    m.experimentsInfo = getExperimentsInfoFromGlobal()
  end if

  experiments = TubiExperiments(m.experimentsInfo)
  resource = experiments.getExperimentResource(namespaceName, experimentName)

  if sendEvent = true AND resource <> invalid
    sendOutExperimentTracking(namespaceName, experimentName, experiments)
  end if

  return resource
End Function


Function sendOutExperimentTracking(namespaceName as String, experimentName as String, experiments)
  ' set up a list of experiment parameters that we've already sent exposure events for
  ' this will prevent multiple exposure events per session for the same experiment
  if m.global <> invalid AND m.global.exposedExperimentParameters = invalid
    m.global.addField("exposedExperimentParameters", "assocarray", false)
    m.global.exposedExperimentParameters = {}
  end if

  localGlobal = m.global
  if localGlobal <> invalid AND localGlobal.trackingLoggingTask <> invalid
    experimentTracking = experiments.getExperimentTracking(namespaceName, experimentName)
    if experimentTracking <> invalid AND localGlobal.exposedExperimentParameters[experimentName] <> true
      localGlobal.trackingLoggingTask.trackEvent = experimentTracking

      'set the parameter on the global store
      exposedExperimentParameters = localGlobal.exposedExperimentParameters
      exposedExperimentParameters[experimentName] = true
      m.global.exposedExperimentParameters = exposedExperimentParameters
    end if
  end if
End Function


' getExperimentResult
'
' @namespaceName: string, namespace of experiment
' @experimentName: string, name of experiment
'
' returns the experiment result in assocarray if experiment is running in popper, or else returns invalid
'   eg. "experiment_name": "qa.roku_in_pod_stitching_v2",
'       "treatment": "in_pod_stitching",
'       "segment": "WHITELISTED"
' this result can be used in youbora requests
Function getExperimentResult(namespaceName as String, experimentName as String) as Object
  if m.experimentsInfo = invalid then
    m.experimentsInfo = getExperimentsInfoFromGlobal()
  end if

  experiments = TubiExperiments(m.experimentsInfo)
  return experiments.getExperimentResult(namespaceName, experimentName)
End Function
