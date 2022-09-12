' getExperimentResource
'
' Get more info about the experiment
' Note: the component calling getExperimentResource using the ExperimentMixin, must also
' have pkg:/source/lib/Request.brs and pkg:/source/lib/TubiExperiments.brs added as scripts
Function getExperimentResource(namespaceName as string, experimentName as string, sendEvent=true as Boolean)
  if m.constants = invalid
    m.constants = m.global.constants
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
  if m.global.exposedExperimentParameters = invalid
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
