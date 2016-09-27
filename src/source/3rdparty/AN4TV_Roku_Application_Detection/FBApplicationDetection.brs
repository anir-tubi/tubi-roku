'**************************************************************
'Copyright (c) 2016 Facebook, Inc. All rights reserved.
'Your use of this software is subject to the Facebook Developer Principles and Policies [http://developers.facebook.com/policy/]
'*************************************************************

' Creates an FBApplicationDetection object that listens for application detection requests.
'   accessToken - this is the app token provided for you application from https://developers.facebook.com/tools/accesstoken/
'   trackingEnabled - boolean to control ad targeting
'   msgPort - listening port for incoming messages
'   loggedInEmail - optional, use false as default; non-hashed email of logged-in user. Email will be hashed using SHA256
'   errorCB - error callback function 

Function FBApplicationDetectionInit(accessToken, trackingEnabled, msgPort, loggedInEmail, errorCB)  
  ' Create the FBApplicationDetection object 
  FBApplicationDetection = {
    _accessToken: accessToken,
    _msgPort: msgPort,
    _email: loggedInEmail,
    _clientTrackingEnabled: trackingEnabled,
    _nextRefresh: UpTime(0) + 600

    _graphAPIEventHandlers: [],

    HandleError: errorCB,
    HandleEvent: FBApplicationDetectionHandleEvent,
    setMessagePort: FBApplicationDetectionSetMessagePort
  }

  FBApplicationDetectionGetDeviceID(FBApplicationDetection)
  return FBApplicationDetection
end Function


Function FBApplicationDetectionHandleEvent(event)
  FBApplicationDetectionReassignPortIfNeeded(m)
  if FBApplicationDetectionHandleGraphAPIEvents(m, event)
    return true
  else if FBApplicationDetectionHandleTCPEvent(m, event)
    return true
  end if  
  return false
end Function


Function FBApplicationDetectionReassignPortIfNeeded(FBApplicationDetection)
  if FBApplicationDetection._nextRefresh <> invalid and UpTime(0) > FBApplicationDetection._nextRefresh 
    FBApplicationDetection._nextRefresh = UpTime(0) + 600
    FBApplicationDetectionGetDeviceID(FBApplicationDetection)
  end if
end Function


Function FBApplicationDetectionSetMessagePort(port)
  for each handler in m._graphAPIEventHandlers
    handler._request.setMessagePort(port)
  end for
  if type(m._tcpListener) = "roStreamSocket"
    m._tcpListener.setMessagePort(port)
  end if

end Function


Function FBApplicationDetectionHandleGraphAPIEvents(FBApplicationDetection, event)
  i = 0
  while i < FBApplicationDetection._graphAPIEventHandlers.count()
    handler = FBApplicationDetection._graphAPIEventHandlers[i]
    if type(event) = "roUrlEvent" and event.GetSourceIdentity() = handler._request.GetIdentity()
      if event.GetInt() = 1 and event.GetResponseCode() = 200
        result = ParseJSON(event.GetString())
        if result <> invalid
          handler._responseHandler(FBApplicationDetection, result)
        else
          FBApplicationDetection.HandleError("Error calling GraphAPI. Response: " + event.GetString())
        endif      
      else 
        FBApplicationDetection.HandleError("Error calling GraphAPI. Error: " + event.GetResponseCode().ToStr())
      end if
      FBApplicationDetection._graphAPIEventHandlers.delete(i)
      return true
    end if
    i++
  end while
  return false
end Function


Function FBApplicationDetectionGraphAPICall(FBApplicationDetection, path, params, resultHandler, get = false)  
  graphAPIRequest = CreateObject("roUrlTransfer")
  graphAPIRequest.setMessagePort(FBApplicationDetection._msgPort)
  graphAPIRequest.SetCertificatesFile("common:/certs/ca-bundle.crt")   
  graphAPIRequest.seturl("https://graph.facebook.com" + path)

  if get
    graphAPIRequest.AsyncGetToString()
  else
    graphAPIRequest.AsyncPostFromString(params)
  end if
  FBApplicationDetection._graphAPIEventHandlers.push({
    _request: graphAPIRequest,
    _responseHandler: resultHandler
  })
end Function


Function FBApplicationDetectionGetDeviceID(FBApplicationDetection)
  deviceInfo = CreateObject("roDeviceInfo")
  idfa = deviceInfo.GetAdvertisingId()
  trackingEnabled = FBApplicationDetection._clientTrackingEnabled and not deviceInfo.IsAdIdTrackingDisabled()
  if type(FBApplicationDetection._deviceID) = "String" and idfa = FBApplicationDetection._idfa and FBApplicationDetection._trackingEnabled = trackingEnabled
    return FBApplicationDetectionGetPortRange(FBApplicationDetection)
  end if

  FBApplicationDetection._idfa = idfa
  FBApplicationDetection._trackingEnabled = trackingEnabled 
  params = "platform=roku&advertising_identifier=" + idfa + "&access_token=" + FBApplicationDetection._accessToken + "&advertising_tracking_enabled=" + trackingEnabled.ToStr()
  if FBApplicationDetection._email
    params = params + "&logged_in_email=" + HashEmail(FBApplicationDetection._email)
  end if
  FBApplicationDetectionGraphAPICall(FBApplicationDetection, "/app/connected_devices", params, FBApplicationDetectionHandleDeviceIDResponse)
end Function


Function FBApplicationDetectionHandleDeviceIDResponse(FBApplicationDetection, result)      
  FBApplicationDetection._deviceID = result["connected_device_id"]
  FBApplicationDetectionGetPortRange(FBApplicationDetection)
end Function


Function FBApplicationDetectionGetPortRange(FBApplicationDetection)
  if type(FBApplicationDetection._deviceID) <> "String"
    FBApplicationDetection.HandleError("No device ID, can't get port range")
    return false
  end if
  path = "/" + FBApplicationDetection._deviceID + "/assigned_port_ranges"
  params = "access_token=" + FBApplicationDetection._accessToken
  FBApplicationDetectionGraphAPICall(FBApplicationDetection, path, params, FBApplicationDetectionHandleGetPortResponse)
end Function


Function FBApplicationDetectionHandleGetPortResponse(FBApplicationDetection, result)
  FBApplicationDetection._minPort = result["port_min_inclusive"]
  FBApplicationDetection._maxPort = result["port_max_inclusive"]
  FBApplicationDetection._responseToken = result["response_token"]
  FBApplicationDetection._nextRefresh = UpTime(0) + result["expiration_time_from_now_secs"]
  FBApplicationDetectionTryOpenPort(FBApplicationDetection)
end Function


Function FBApplicationDetectionTryOpenPort(FBApplicationDetection)
  if type(FBApplicationDetection._tcpListener) = "roStreamSocket"
    FBApplicationDetection._tcpListener.close()    
  end if
  port = FBApplicationDetection._minPort + Rnd(1 + FBApplicationDetection._maxPort - FBApplicationDetection._minPort) - 1
  tcpListen = CreateObject("roStreamSocket")
  tcpListen.setMessagePort(FBApplicationDetection._msgPort)
  addr = CreateObject("roSocketAddress")
  addr.setPort(port)
  tcpListen.setAddress(addr)
  tcpListen.notifyReadable(true)
  tcpListen.listen(20)
  
  if not tcpListen.eOK()
    FBApplicationDetection.HandleError("Cant listen at port" + port)
  else
    FBApplicationDetection._tcpListener = tcpListen
    FBApplicationDetectionReportListeningPort(FBApplicationDetection, port)
  end if  
end Function


Function FBApplicationDetectionReportListeningPort(FBApplicationDetection, port)
  deviceInfo = CreateObject("roDeviceInfo")
  ipAddresses = deviceInfo.GetIPAddrs()
  if ipAddresses.count() < 1
    FBApplicationDetection.HandleError("No local ip")
    return false
  end if
  ip = ipAddresses[ipAddresses.keys()[0]]
  path = "/" + FBApplicationDetection._deviceID + "/listen_port_opened"
  params = "access_token=" + FBApplicationDetection._accessToken + "&port=" + port.ToStr() + "&local_ip=" + ip  
  FBApplicationDetectionGraphAPICall(FBApplicationDetection, path, params, FBApplicationDetectionHandleReportListeningPortResponse)
end Function


Function FBApplicationDetectionHandleReportListeningPortResponse(FBApplicationDetection, result)  
  nextRefresh = UpTime(0) + result["refresh_time_from_now_secs"]
  if nextRefresh < FBApplicationDetection._nextRefresh then
    FBApplicationDetection._nextRefresh = nextRefresh
  end if
end Function


Function FBApplicationDetectionHandleTCPEvent(FBApplicationDetection, event)  
  if type(event) = "roSocketEvent"
    socket = FBApplicationDetection._tcpListener
    if event.getSocketID() = socket.getID() and socket.isReadable()
      newConnection = socket.accept()
      if newConnection <> Invalid          
        newConnection.notifyReadable(true)
        newConnection.SendStr(FBApplicationDetection._responseToken)
        newConnection.close()
      end if
      return true
    end if
  end if           
  return false
end Function

Function HashEmail(email) 
  if type(email) = "roString"
    ba1 = CreateObject("roByteArray")
    ba2 = CreateObject("roByteArray")
    ba2.FromAsciiString(email)
    digest = CreateObject("roEVPDigest")
    digest.Setup("sha256")
    digest.Update(ba1)
    digest.Update(ba2)
    return digest.Final()
  else
    return email.ToStr()
  end if
end Function
