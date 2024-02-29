' Thin wrapper for third party Rest API requests
Function ThirdPartyApi(constants)
  return {
    ' dependencies
    constants: constants

    ' public
    createBrazeMergeUsersReqInfo: thirdPartyApi_createBrazeMergeUsersReqInfo
  }
End Function


' @deviceId: string, contains the device id.
' @userId: string, contains the user id.
Function thirdPartyApi_createBrazeMergeUsersReqInfo(deviceId, userId)
  body = {
    "merge_updates": [
      {
        "identifier_to_merge": {
          "external_id": deviceId
        },
        "identifier_to_keep": {
          "external_id": userId
        }
      }
    ]
  }
  options = {
    method: m.constants.reqTypes.post
    body: FormatJson(body)
    headers: {
      "Authorization": "Bearer " + m.constants.thirdParty.braze.restApiKey
    }
  }
  return {
    url: m.constants.thirdParty.braze.endpoint + "users/merge"
    options: options
  }
End Function
