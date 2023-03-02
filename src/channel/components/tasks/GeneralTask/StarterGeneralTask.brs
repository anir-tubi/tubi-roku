Function registerParsingCallbacks()
    ' generic requests
    m.requestTypes[m.constants.reqNames.getExternalConfigs] = {
        parseSuccess: parseGenericSuccess
        parseError: parseGenericError
    }

    'tubi experiments.
    m.requestTypes[m.constants.reqNames.getNamespaces] = {
        parseSuccess: parseTubiExperimentsNamespaceRequestSuccess
        parseError: parseGenericError
    }
End Function
