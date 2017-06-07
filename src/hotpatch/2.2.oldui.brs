print "Hot Patch 2.2.oldui"

'add protection to the url generating function in order to fix crashes as seen in roku's crash repoport UI
m.app.player.ads.populateUrl = function(episode, playerSettings)
  settings = m.utils.getSettings()

  deviceId = "&deviceId=" + m.utils.deviceInfo.deviceId
  model = "&model=" + m.utils.deviceInfo.model

  ' add Roku Advertiser Id (RIDA) to ad call url  
  urlAdId = ""
  if m.utils.deviceInfo.deviceAdId <> invalid
    urlAdId = "&advid=" + m.utils.deviceInfo.deviceAdId
  end if

  optOut = "&opt-out=0"
  if m.utils.deviceInfo.isAdIdTrackingDisabled = true
    optOut = "&opt-out=1"
  end if

  'add TubiTV user/registration id to ad call url
  urlTubiId = ""
  userData = m.utils.getUserData()
  if userData <> invalid and userData.token <> invalid
    urlTubiId = "&tubitvid=" + userData.token
  end if

  'add if Linear/Live TV is on or off to ad call url
  isLinear = ""
  if GetGlobalAA().app.linearTV.linearTvOn = true
    isLinear = "&linear=1"
  end if

  'select the ad sdk
  adSdk = "&sdk=5.0_video"
  if m.isRokuAdFrameworkOn = true
    adSdk = "&sdk=raf_vast"
  end if

  appId = "&appId=" + settings.shortAppName
  pubId = "&pubid=" + settings.pubId  'default pub id from settings
  contentType = "&content-type=hls"
  if playerSettings <> invalid
    if type(playerSettings.appId) = "String" or type(playerSettings.appId) = "roString"
      appId = "&appId=" + playerSettings.appId
    end if

    if type(playerSettings.pubId) = "String" or type(playerSettings.pubId) = "roString"
      pubId = "&pubid=" + playerSettings.pubId
    end if

    if type(playerSettings.contentType) = "String" or type(playerSettings.contentType) = "roString"
      contentType = "&content-type=" + playerSettings.contentType
    end if
  end if

  cid = ""
  nowPos = "&nowpos=0"
  if episode <> invalid
    if type(episode.id) = "String" or type(episode.id) = "roString"
      cid = "&cid=" + episode.id
    end if

    if type(episode.nowPos) = "roFloat" or type(episode.nowPos) = "roInteger"
      nowPos = "&nowpos=" + Int(episode.nowPos).ToStr()
    end if
  end if

  'create the url to be used for ad calls'
  url = m.baseUrl + "?platform=roku" + appId + adSdk + cid + nowPos + model + deviceId + optOut + urlAdId + urlTubiId + pubId + contentType + isLinear + "&_=" + RND(1000000000000).ToStr()

  return url
end function
