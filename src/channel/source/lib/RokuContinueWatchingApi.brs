' Thin wrapper for the Roku Continue Watching API requests
Function RokuContinueWatchingApi(constants)
  return {
    ' dependencies
    constants: constants
    rokuReservedHeaders: {
      "x-roku-reserved-jwt": ""
      "x-roku-reserved-channel-id": m.constants.productionApplicationId
      "x-roku-reserved-channel-store-code": ""
      "x-roku-reserved-virtual-user-id": ""
      "x-roku-reserved-device-id": ""
      "x-roku-reserved-serial-number": ""
    }

    ' public
    createUpdateContinueWatchingReqInfo: rokuContinueWatchingApi_createUpdateContinueWatchingReqInfo
    createDeleteContinueWatchingReqInfo: rokuContinueWatchingApi_createDeleteContinueWatchingReqInfo
  }
End Function


' @body: assocarray, contains a key value pair for ex: {"items":[{"contentId":"abc123","episodeId":"def123","lastInteractionTime":123456,"position":854,"duration":1678,"waitForNextEpisodeAvailability":true}]}.
Function rokuContinueWatchingApi_createUpdateContinueWatchingReqInfo(body)
  options = {
    method: m.constants.reqTypes.post
    body: FormatJson(body)
    headers: m.rokuReservedHeaders
  }
  return {
    url: m.constants.urls.rokuContinueWatchingEndpoint
    options: options
  }
End Function


' @body: assocarray, contains a key value pair for ex: {"items":[{"contentId":"abc123","episodeId":"def123"}]}.
Function rokuContinueWatchingApi_createDeleteContinueWatchingReqInfo(body)
  options = {
    method: m.constants.reqTypes.del
    body: FormatJson(body)
    headers: m.rokuReservedHeaders
  }
  return {
    url: m.constants.urls.rokuContinueWatchingEndpoint
    options: options
  }
End Function
