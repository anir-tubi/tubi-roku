' getExperimentResource
'
' Get more info about the experiment
' Note: the component calling getExperimentResource using the ExperimentMixin, must also
' have pkg:/source/lib/Request.brs and pkg:/source/lib/TubiExperiments.brs added as scripts
Function getExperimentResource(namespaceName as string, experimentName as string, sendEvent=true as Boolean)
  if m.constants = invalid
    m.constants = getConstantsFromGlobal()
  end if
  experiments = TubiExperiments(m.constants)
  resource = experiments.getExperimentResource(namespaceName, experimentName)

  if sendEvent = true AND resource <> invalid
    sendOutExperimentTracking(namespaceName, experimentName, experiments)
  end if

  return resource
End Function


Function sendOutExperimentTracking(namespaceName as string, experimentName as string, experiments)
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
Function getExperimentResult(namespaceName as string, experimentName as string) as Object

  if m.constants = invalid
    m.constants = m.global.constants
  end if

  experiments = TubiExperiments(m.constants)
  return experiments.getExperimentResult(namespaceName, experimentName)
End Function
