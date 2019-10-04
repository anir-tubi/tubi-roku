' Note: the component calling getExperimentValue using the ExperimentMixin, must also
' have pkg:/source/lib/Request.brs and pkg:/source/lib/TubiExperiments.brs added as scripts
'
Function getExperimentValue(namespaceName as string, parameterName as string)
  ' set up a list of experiment parameters that we've already sent exposure events for
  ' this will prevent multiple exposure events per session for the same experiment
  if m.global.exposedExperimentParameters = invalid
    m.global.addField("exposedExperimentParameters", "assocarray", false)
    m.global.exposedExperimentParameters = {}
  end if

  if m.global <> invalid and m.global.trackingLoggingTask <> invalid
    experiments = TubiExperiments(m.global.constants)

    experimentInfoAndTracking = experiments.getExperimentValue(namespaceName, parameterName)

    if experimentInfoAndTracking.trackInfo <> invalid and m.global.exposedExperimentParameters[parameterName] <> true
      m.global.trackingLoggingTask.trackEvent = experimentInfoAndTracking.trackInfo

      'set the parameter on the globl store
      exposedExperimentParameters = m.global.exposedExperimentParameters
      exposedExperimentParameters[parameterName] = true
      m.global.exposedExperimentParameters = exposedExperimentParameters
    end if

    return experimentInfoAndTracking.experimentValue
  end if

  return invalid
End Function