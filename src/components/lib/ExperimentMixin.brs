
Function getExperimentValue(namespaceName as string, parameterName as string)
  if m.global <> invalid and m.global.trackingLoggingTask <> invalid
    request = TubiRequest()
    experiments = TubiExperiments(request, m.global.constants)

    experimentInfoAndTracking = experiments.getExperimentValue(namespaceName, parameterName)

    if experimentInfoAndTracking.trackInfo <> invalid
      m.global.trackingLoggingTask.trackEvent = experimentInfoAndTracking.trackInfo
    end if

    return experimentInfoAndTracking.experimentValue
  end if

  return invalid

End Function