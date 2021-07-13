' getExperimentResource
' 
' Get more info about the experiment
' Note: the component calling getExperimentResource using the ExperimentMixin, must also
' have pkg:/source/lib/Request.brs and pkg:/source/lib/TubiExperiments.brs added as scripts
Function getExperimentResource(namespaceName as string, experimentName as string, sendEvent=true as Boolean)
  oMoreInfoReturn = invalid
  
  if m.global <> invalid and m.global.trackingLoggingTask <> invalid
    '//if you cannot track task, then do not proceed
    if m.constants = invalid
      m.constants = m.global.constants
    end if
    request = TubiRequest(m.constants.settings)
    experiments = TubiExperiments(m.constants)
    oMoreInfoReturn = experiments.getExperimentResource(namespaceName, experimentName)
    if sendEvent = true
      sendOutExperimentTracking(namespaceName, experimentName, experiments)
    end if
  end if

  return oMoreInfoReturn
End Function


Function sendOutExperimentTracking(namespaceName as string, experimentName as string, experiments)
  ' set up a list of experiment parameters that we've already sent exposure events for
  ' this will prevent multiple exposure events per session for the same experiment
  if m.global.exposedExperimentParameters = invalid
    m.global.addField("exposedExperimentParameters", "assocarray", false)
    m.global.exposedExperimentParameters = {}
  end if

  if m.global <> invalid and m.global.trackingLoggingTask <> invalid
    experimentTracking = experiments.getExperimentTracking(namespaceName, experimentName)
    if experimentTracking <> invalid and m.global.exposedExperimentParameters[experimentName] <> true
      m.global.trackingLoggingTask.trackEvent = experimentTracking

      'set the parameter on the global store
      exposedExperimentParameters = m.global.exposedExperimentParameters
      exposedExperimentParameters[experimentName] = true
      m.global.exposedExperimentParameters = exposedExperimentParameters
    end if
  end if
End Function
