Function init()
  m.top.functionName = "getExperiments"
End Function


Function getExperiments()
  port = CreateObject("roMessagePort")
  request = TubiRequest()
  externalConfig = TubiExternalConfig(request, m.top.constants)
  experiments = TubiExperiments(m.top.constants)

  experimentsReq = experiments.getNamespaceRequest(request)
  experimentsReq.start(port)
  externalConfigReq = externalConfig.getConfigsRequest(request, m.top.constants)
  externalConfigReq.start(port)

  while true
    msg = wait(0, port)

    if type(msg) = "roUrlEvent"
      if experimentsReq <> invalid and experimentsReq.urltransfer <> invalid and msg.getSourceIdentity() = experimentsReq.urltransfer.getIdentity()
        ' handle experiments
        experimentsReq.handleEvent(msg)
        if experimentsReq.response <> invalid and resIsValid(experimentsReq.response) = true
          m.top.experimentsInfo = experiments.handleAsyncNamespaceResponse(experimentsReq.response.data)
        else
          m.top.experimentsInfo = {}
        end if
      else if externalConfigReq <> invalid and externalConfigReq.urltransfer <> invalid and msg.getSourceIdentity() = externalConfigReq.urltransfer.getIdentity()
        ' handle external config
        externalConfigReq.handleEvent(msg)
        if externalConfigReq.response <> invalid and resIsValid(externalConfigReq.response) = true
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
  if res.code >= 200 and res.code < 400
    return true
  else
    return false
  end if
End Function