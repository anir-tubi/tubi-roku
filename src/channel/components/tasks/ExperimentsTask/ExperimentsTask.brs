Function init()
  m.top.functionName = "getExperiments"
End Function


Function getExperiments()
  port = CreateObject("roMessagePort")
  constants = m.top.constants
  request = TubiRequest(constants.settings)
  externalConfig = TubiExternalConfig(request, constants)
  experiments = TubiExperiments(constants)

  experimentsReq = experiments.getNamespaceRequest(request)
  experimentsReq.start(port)
  externalConfigReq = externalConfig.getConfigsRequest(request, constants)
  externalConfigReq.start(port)

  while true
    msg = wait(0, port)

    if type(msg) = "roUrlEvent"
      if experimentsReq <> invalid AND experimentsReq.urltransfer <> invalid AND msg.getSourceIdentity() = experimentsReq.urltransfer.getIdentity()
        ' handle experiments
        experimentsReq.handleEvent(msg)
        if experimentsReq.response <> invalid AND resIsValid(experimentsReq.response) = true
          m.top.experimentsInfo = experiments.handleAsyncNamespaceResponse(experimentsReq.response.data)
        else
          m.top.experimentsInfo = {}
        end if
      else if externalConfigReq <> invalid AND externalConfigReq.urltransfer <> invalid AND msg.getSourceIdentity() = externalConfigReq.urltransfer.getIdentity()
        ' handle external config
        externalConfigReq.handleEvent(msg)
        if externalConfigReq.response <> invalid AND resIsValid(externalConfigReq.response) = true
          m.top.externalConfigInfo = externalConfig.parseConfigs(externalConfigReq.response.data)
        else
          m.top.externalConfigInfo = invalid
        end if
      end if
    end if
  end while
End Function


' @res: assocArray, as returned by Request().handleEvent with keys: code, data, failReason
Function resIsValid(res)
  if res.code >= 200 AND res.code < 400
    return true
  else
    return false
  end if
End Function