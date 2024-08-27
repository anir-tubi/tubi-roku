Function registerParsingCallbacks()
  ' external config request
  m.requestTypes[m.constants.reqNames.getExternalConfigs] = {
    parseSuccess: parseGetExternalConfigSuccess
    parseError: parseGenericError
  }

  'tubi experiments.
  m.requestTypes[m.constants.reqNames.getNamespaces] = {
    parseSuccess: parseTubiExperimentsNamespaceRequestSuccess
    parseError: parseGenericError
  }
End Function


' Called from the base general task listen method. Below overridden method will be used to register helpers/utilities.
Function instantiateLibs()
  m.experiments = TubiExperiments(m.experimentsInfo)
End Function
