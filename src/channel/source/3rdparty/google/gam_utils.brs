' Copyright 2024 Google LLC
'
' Licensed under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License.
' You may obtain a copy of the License at
'
'     http://www.apache.org/licenses/LICENSE-2.0
'
' Unless required by applicable law or agreed to in writing, software
' distributed under the License is distributed on an "AS IS" BASIS,
' WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
' See the License for the specific language governing permissions and
' limitations under the License.
'
' GAM Utils v2.0.0b2
'
' GAM Utils is a small BrightScript library that helps enable programmatic
' monetization on Google Ad Manager for Roku apps. It serves as a lightweight
' alternative to the IMA SDK
' (https://developers.google.com/interactive-media-ads).


' Creates a new AppSession for the entire duration of the channel.
Function newAppSession() as Object
  deviceInfo = createObject("roDeviceInfo")
  instance = {
    _appInfo: createObject("roAppInfo"),
    _appManager: createObject("roAppManager"),
    _deviceInfo: deviceInfo,
    _hdmiStatus: createObject("roHdmiStatus"),
    _osVersion: deviceInfo.getOSVersion(),
    _sessionId: deviceInfo.getRandomUUID(),
    _urlTransfer: createObject("roUrlTransfer")
  }

  instance._booleanAsString = Function(booleanValue, trueValue, falseValue)
    if booleanValue = invalid then return invalid
    if booleanValue = True then return trueValue
    return falseValue
  End Function

  instance._buildUrlQueryString = Function(map as Object) as String
    keyValues = []
    for each keyValuePair in map.items()
      if keyValuePair.value <> invalid AND keyValuePair.value <> ""
        keyValues.push(keyValuePair.key + "=" + keyValuePair.value)
      end if
    end for
    return keyValues.join("&")
  End Function

  instance._webSafeBase64Encode = Function(uncodedString as String) as String
    byteArray = createObject("roByteArray")
    byteArray.fromAsciiString(uncodedString)
    return byteArray.toBase64String().replace("/", "_").replace("+", "-").replace("=", ".")
  End Function

  instance._getUserAgent = Function() as String
    product = m._appInfo.getTitle() + "/" + m._appInfo.getVersion()
    platformComponents = [
      "Roku " + m._osVersion.major + "." + m._osVersion.minor + "." + m._osVersion.revision,
      m._deviceInfo.getCurrentLocale(),
      m._deviceInfo.getModelDisplayName(),
      "Build/" + m._osVersion.build,
    ]
    return m._urlTransfer.escape(product + " (" + platformComponents.join("; ") + ")")
  End Function

  instance._buildGIVN = Function(args as Object) as String
    signals = {
      "url": m._urlTransfer.escape(m._appInfo.getTitle() + ".adsenseformobileapps.com/"),
      "vpa": m._booleanAsString(args.adWillAutoPlay, "auto", "click"),
      "vpmute": m._booleanAsString(args.adWillPlayMuted, "1", "0"),
      "vconp": m._booleanAsString(args.continuousPlayback, "2", "1"),
      "pss": m._booleanAsString(args.skippablesSupported, "1", "0"),
      "wta": m._booleanAsString(args.iconsSupported, "1", "0"),
      "ppid": args.publisherProvidedId,
      "sid": args.sessionId,
      "sdk_apis": m._urlTransfer.escape(args.supportedApiFrameworks.join(",")),
      "aselc": "3",
      "asscs_correlator": args.asscsCorrelator,
      "msid": m._appInfo.getId(),
      "ctv": "1",
      "is_lat": m._booleanAsString(m._deviceInfo.isRidaDisabled(), "1", "0"),
      "guv": "r.2.0.0b2",
      "imav": "r.3.2.2",
      "ua": m._getUserAgent()
    }
    if args.descriptionUrl <> invalid AND args.descriptionUrl <> "" then signals["url"] = args.descriptionUrl
    if args.descriptionUrl <> invalid AND args.descriptionUrl <> "" then signals["video_url_to_fetch"] = args.descriptionUrl
    if args.videoHeight <> invalid then signals["vp_h"] = args.videoHeight.toStr()
    if args.videoWidth <> invalid then signals["vp_w"] = args.videoWidth.toStr()
    if args.videoHeight <> invalid AND args.videoWidth <> invalid then signals["u_so"] = m._booleanAsString(args.videoHeight > args.videoWidth, "p", "l")
    if args.storageAllowed = True AND args.directedForChildOrUnknownAge = False
      signals["id_type"] = "rida"
      signals["rdid"] = m._deviceInfo.getRida()
    end if
    signalString = m._buildUrlQueryString(signals)
    return m._webSafeBase64Encode(signalString)
  End Function

  ' Creates a new content session, for a single given content or program.
  instance.newContentSession = Function(rawSessionArgs as Object) as Object
    sessionArgs = {
      adWillAutoPlay: invalid,
      adWillPlayMuted: invalid,
      continuousPlayback: invalid,
      descriptionUrl: invalid,
      directedForChildOrUnknownAge: False,
      iconsSupported: False,
      publisherProvidedId: invalid,
      raf: invalid,
      storageAllowed: False,
      supportedApiFrameworks: [],
      sessionId: m._sessionId,
      skippablesSupported: False,
      videoHeight: invalid,
      videoWidth: invalid
    }
    sessionArgs.append(rawSessionArgs)
    asscsCorrelator = m._deviceInfo.getRandomUUID()
    sessionArgs.append({ asscsCorrelator: asscsCorrelator })
    proto = {
      _activityTimer: createObject("roTimespan"),
      _asscsCorrelator: asscsCorrelator,
      _givn: m._buildGIVN(sessionArgs),
      _instance: m,
      _isActive: False,
      _raf: sessionArgs.raf
    }

    ' Returns the `givn=` value for making ads requests.
    proto.getGIVN = Function() as String
      return m._givn
    End Function

    ' Sends a beacon to indicate that a clickthrough on an ad has occurred.
    proto.sendAdClickBeacon = sub()
      m._sendBeacon("3", "Clicked", False, invalid)
    end sub

    ' Sends a beacon to indicate that a user touch or click on the ad other than
    ' a clickthrough (for example, skip, mute, tap, etc.) from `onKeyEvent`.
    proto.sendAdTouchBeacon = sub(key as String)
      m._sendBeacon("4", "Interaction", False, key)
    end sub

    ' Sends a beacon to indicate that the content activity has started. For
    ' video, this should be called on "video player start". This may be in
    ' response to a user-initiated action (click-to-play) or a channel initiated
    ' action (autoplay).
    proto.sendStartedBeacon = sub()
      m._isActive = True
      m._activityTimer.mark()
      m._sendBeacon("5", "ProgressStarted", True, invalid)
    end sub

    ' Triggers beacons that fire during content activity as time progresses.
    proto.poll = sub()
      if m._isActive = False then return
      if m._activityTimer.totalSeconds() < 5 then return
      m._activityTimer.mark()
      m._sendBeacon("6", "Progress", False, invalid)
    end sub

    ' Sends a beacon to indicate that the content activity has ended. For video
    ' this should be called when playback ends (for example, when the player
    ' reaches end of stream, or when the user exits playback mid-way, or when
    ' the user quits the channel, or when advancing to the next content item in
    ' a playlist setting).
    proto.sendEndedBeacon = sub()
      m._isActive = False
      m._sendBeacon("7", "ProgressEnded", False, invalid)
    end sub

    proto._sendBeacon = sub(eventType as String, rafEventType as String, includeAllSignals as Boolean, key)
      signals = {
        "asscs_correlator": m._asscsCorrelator,
        "ctv": "1",
        "dt": "1",
        "et": eventType,
        "id": "asscs",
        "iet": key,
        "hdmic": m._instance._booleanAsString(m._instance._hdmiStatus.isConnected(), "1", "0"),
        "aut": m._instance._appManager.getUpTime().totalMilliseconds().toStr(),
        "lkp": (m._instance._deviceInfo.timeSinceLastKeyPress() * 1000).toStr(),
        "sut": (upTime(0) * 1000).toStr()
      }
      if includeAllSignals
        signals.append({
          "aid": m._instance._appInfo.getId(),
          "av": m._instance._appInfo.getVersion(),
          "cc": m._instance._deviceInfo.getUserCountryCode(),
          "eip": m._instance._deviceInfo.getExternalIp(),
          "fv": m._instance._osVersion.major + "." + m._instance._osVersion.minor + "." + m._instance._osVersion.revision + "." + m._instance._osVersion.build,
          "lcl": m._instance._deviceInfo.getCurrentLocale(),
          "mdl": m._instance._deviceInfo.getModel(),
          "isd": m._instance._booleanAsString(m._instance._appInfo.isDev(), "1", "0")
        })
      end if
      signalString = m._instance._buildUrlQueryString(signals)
      m._raf.fireTrackingEvents({
        "tracking": [{
          "event": rafEventType, "triggered": False,
          "url": "https://pagead2.googlesyndication.com/pagead/gen_204?" + signalString
      }], "adServer": invalid }, { "type": rafEventType })
    end sub
    return proto
  End Function
  return instance
End Function
