' getExperimentResource
' 
' Get more info about the experiement
' Note: the component calling getExperimentValue using the ExperimentMixin, must also
' have pkg:/source/lib/Request.brs and pkg:/source/lib/TubiExperiments.brs added as scripts
Function getExperimentResource(namespaceName as string, parameterName as string, sendEvent=true as Boolean)
  oMoreInfoReturn = invalid
  
  if m.global <> invalid and m.global.trackingLoggingTask <> invalid
    '//if you cannot track task, then do not proceed
    request = TubiRequest()
    experiments = TubiExperiments(m.global.constants)
    oMoreInfoReturn = experiments.getExperimentResource(namespaceName, parameterName)
    if sendEvent = true
      sendOutExperimentTracking(namespaceName, parameterName, experiments)
    end if
  end if

  return oMoreInfoReturn
End Function


' Note: the component calling getExperimentValue using the ExperimentMixin, must also
' have pkg:/source/lib/Request.brs and pkg:/source/lib/TubiExperiments.brs added as scripts
'
Function getExperimentValue(namespaceName as string, parameterName as string, sendEvent=true as Boolean)
  experimentInfo = invalid
  
  if m.global <> invalid and m.global.trackingLoggingTask <> invalid
    '//if you cannot track task, then do not proceed
    request = TubiRequest()
    experiments = TubiExperiments(m.global.constants)
    experimentInfo = experiments.getExperimentValue(namespaceName, parameterName)
    if sendEvent = true
      sendOutExperimentTracking(namespaceName, parameterName, experiments)
    end if
  end if

  return experimentInfo
End Function


Function sendOutExperimentTracking(namespaceName as string, parameterName as string, experiments)  
  ' set up a list of experiment parameters that we've already sent exposure events for
  ' this will prevent multiple exposure events per session for the same experiment
  if m.global.exposedExperimentParameters = invalid
    m.global.addField("exposedExperimentParameters", "assocarray", false)
    m.global.exposedExperimentParameters = {}
  end if

  if m.global <> invalid and m.global.trackingLoggingTask <> invalid
    experimentTracking = experiments.getExperimentTracking(namespaceName, parameterName)
    if experimentTracking <> invalid and m.global.exposedExperimentParameters[parameterName] <> true
      m.global.trackingLoggingTask.trackEvent = experimentTracking

      'set the parameter on the global store
      exposedExperimentParameters = m.global.exposedExperimentParameters
      exposedExperimentParameters[parameterName] = true
      m.global.exposedExperimentParameters = exposedExperimentParameters
    end if
  end if
End Function
