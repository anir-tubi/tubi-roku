Function getSaveLogConsentdata(viewData, consentData)
  data = {
    method: "POST",
    name: "saveLogConsent"
    body: getPayload(viewData, consentData),
    headers: m.global.OT_Data["headers"],
    functionName: "fetchApi"
  }
  return data
End Function

Function getPayload(viewData, consentData)
  data = {
    "interactionType": viewData.interactionType,
    "userAgent": ""
  }
  if data.interactionType.Instr("_CONFIRM") <> -1
    data["consent"] = {
      "purposesStatus": getStatusData(consentData.purposesStatus),
      "iabVendorsStatus": getStatusData(consentData.iabVendorsStatus),
      "googleVendorsStatus": getStatusData(consentData.googleVendorsStatus),
      "sdkStatus": getStatusData(consentData.sdkStatus)
    }
  end if
  return data
End Function

Function getStatusData(data)
  purposesStatus = []
  if data <> invalid AND data.count()
    for each item in data.items()
      purposesStatus.push(item.value)
    end for
  end if
  return purposesStatus
End Function

'function userAgent()
'    data = ""
'    request = CreateObject("roUrlTransfer")
'    if FindMemberFunction(request, "GetUserAgent") <> invalid then data = request.GetUserAgent()
'    return data
'end function