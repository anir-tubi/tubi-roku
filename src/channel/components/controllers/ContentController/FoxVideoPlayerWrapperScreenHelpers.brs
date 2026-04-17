' Call to play linear video with fox player
' @param content: The content we want to play as returned by homescreen and container endpoints
Function playLinearVideoWithFoxPlayer(content = invalid)
  ' Used to route fox player watch call through Charles
  ' m.global.update({
  '   proxyParameters: {
  '     "isProxyEnabled": true
  '     "proxyIp": "192.168.10.117"
  '   }
  ' }, true)

  m.lastSentFoxPlayerProgressPosition = 0

  stopVideoPreview()

  ' We immediately show the player screen so we can show the loading spinner but have to wait until we are ready to actually try playing video
  foxVideoPlayerWrapperScreen = createObject("roSGNode", "FoxVideoPlayerWrapperScreen")
  foxVideoPlayerWrapperScreen.id = m.constants.ui.screenIds.foxVideoPlayerWrapperScreen
  foxVideoPlayerWrapperScreen.observeFieldScoped("willPlayerClose", "onFoxVideoPlayerWillPlayerClose")
  foxVideoPlayerWrapperScreen.observeFieldScoped("loadTime", "onFoxVideoPlayerLoadTimeChange")

  if content <> invalid then
    foxVideoPlayerWrapperScreen.tubiId = content.id
  end if

  pushScreen(foxVideoPlayerWrapperScreen, true, false)

  ' If we haven't retrieved the fox player yet then start loading it
  if m.isFoxPlayerLoadRequired = true
    loadFoxVideoPlayerComponentLibrary()
  else if m.foxRpfInstance <> invalid then
    assignProfileIdToFoxVideoPlayer(m.foxRpfInstance)

    ' If the fox player has finished loading then we can start playing the video. We check for this by looking if m.foxRpfInstance has been set which we set after load is completed. Else we will wait for the load to complete with the already set onFoxVideoPlayerComponentLibraryLoadStatus observer
    foxVideoPlayerWrapperScreen.isFoxVideoPlayerAvailable = true
  end if

  retrieveFoxListingResponse()
End Function


' Used to assign the profile id to the fox player for use in Conviva and mux.
' Uses the user id if the user is logged in, otherwise uses the device id
' @param foxRpfInstance: The fox player instance
Function assignProfileIdToFoxVideoPlayer(foxRpfInstance)
  profile = foxRpfInstance.profile
  if isNode(profile) = true then
    authInfo = m.tubiAuthUpdate.getAuthInfo()
    if isLoggedInUser(authInfo) = true then
      profile.profileId = authInfo.userId
    else
      profile.profileId = m.constants.deviceInfo.deviceId
    end if
  end if
End Function


Function loadFoxVideoPlayerComponentLibrary()
  tubiLog("loadFoxVideoPlayerComponentLibrary")
  m.isFoxPlayerLoadRequired = false
  componentLibrary = m.top.createChild("ComponentLibrary")
  componentLibrary.observeField("loadStatus", "onFoxVideoPlayerComponentLibraryLoadStatus")
  componentLibrary.uri = m.constants.settings.foxVideoPlayerComponentsUrl
End Function


Function onFoxVideoPlayerComponentLibraryLoadStatus(msg)
  status = msg.getData()

  if status = "ready" then
    ' If we couldn't make the initializer then the component library didn't load correctly
    initializer = createObject("roSGNode", "FoxVideoPlayer:FoxVideoPlayerInitializer")
    didFoxPlayerLoadFail = false
    if initializer = invalid then
      didFoxPlayerLoadFail = true
    else
      ' Setting the config triggers the fox player to initialize
      initializer.config = getFoxVideoPlayerConfig()

      foxRpfInstance = initializer.foxRpfInstance

      if foxRpfInstance = invalid then
        didFoxPlayerLoadFail = true
      else
        m.foxRpfInstance = foxRpfInstance

        foxVideoPlayerAdTraceId = regRead("foxVideoPlayerAdTraceId", m.constants.registrySectionIDs.settingsOverride)
        if foxVideoPlayerAdTraceId <> invalid then
          foxRpfInstance.adTraceId = foxVideoPlayerAdTraceId
        end if

        assignProfileIdToFoxVideoPlayer(foxRpfInstance)

        ' Set the strings for the fox player that we are overriding
        strings = {
          "error_contentUnavailableMessage": getTranslation("foxVideoPlayer_error_contentUnavailableMessage"),
          "error_generic": getTranslation("foxVideoPlayer_error_generic"),
          "global_retryButton": getTranslation("retry"),
          "global_cancelButton": getTranslation("dialog_button_cancel"),
        }
        foxRpfInstance.callFunc("setStrings", strings)

        if foxRpfInstance.playerEvent <> invalid then
          foxRpfInstance.playerEvent.observeFieldScoped("exitStream", "onFoxVideoPlayerExitStreamChange")

          foxRpfInstance.playerEvent.observeFieldScoped("liveAssetInfo", "onLiveAssetInfoChange")

          foxRpfInstance.playerEvent.observeFieldScoped("playerPosition", "onFoxVideoPlayerPlayerPositionChange")

          foxRpfInstance.playerEvent.observeFieldScoped("adState", "onFoxVideoPlayerAdStateChange", ["playerPosition"])
        end if

        foxRpfInstance.observeFieldScoped("errorInfo", "onFoxVideoPlayerError")
        foxRpfInstance.observeFieldScoped("alertDialogCancelled", "onFoxVideoPlayerAlertDialogCancelledChange")

        currentScreen = getCurrentScreen()
        if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.foxVideoPlayerWrapperScreen then
          currentScreen.isFoxVideoPlayerAvailable = true
        end if
      end if
    end if

    if didFoxPlayerLoadFail = true then
      m.isFoxPlayerLoadRequired = true
      tubiLog("Fox video player failed to initialize")
      closeFoxVideoPlayer()
    end if
  else if status = "failed" then
    m.isFoxPlayerLoadRequired = true
    tubiLog("Fox video player component library failed to load")
    sendFoxPlayerErrorBeforePlayEvent("Fox video player component library failed to load")
    closeFoxVideoPlayer()
  end if
End Function


Function onLiveAssetInfoChange(msg)
  liveAssetInfo = msg.getData()
  if isArray(m.foxListingEndpointResponse) = true AND liveAssetInfo <> invalid AND isString(liveAssetInfo.id) = true then
    for each item in m.foxListingEndpointResponse
      if item.asset <> invalid AND item.asset.listing <> invalid then
        listing = item.asset.listing
        if isString(listing.id) = true AND listing.id = liveAssetInfo.id AND isString(listing.tubi_id) = true then
          m.foxPlayerCurrentListing = listing
          exit for
        end if
      end if
    end for
  end if
End Function


Function getFoxVideoPlayerConfig()
  usPrivacyString = "{dnsParams}"
  if isNonEmptyString(m.pub_serverPersistentData.usPrivacyString) = true then
    usPrivacyString = m.pub_serverPersistentData.usPrivacyString
  end if

  muxEnvironmentKey = "aa7at5lkvspdg2ju2r42gf559"
  if m.constants.settings.mode = "production" then
    muxEnvironmentKey = "18lus0524edvcif1pa0hruc0e"
  end if

  convivaCustomerKey = "611c005357f6991f5b731265d461ee49fe92a8cc"
  if m.constants.settings.mode = "production" then
    convivaCustomerKey = "1ff98d3f0df77fc9fdedf4209cc4db4cc1844a69"
  end if

  clientRemoteConfigEnv = "dev"
  if m.constants.settings.mode = "production" then
    clientRemoteConfigEnv = "prod"
  end if

  config = {
    "clientRemoteConfig": {
      "clientKey": "tubi_roku",
      "env": clientRemoteConfigEnv
    },
    "ads": {
      "adsParam": "{doNotSellInfo}&extra=%257Cis_lat%257C{limitedAdTracking}%26ad.sssb%3D1",
      "debugParam": "%26ad._debug%3D{userDebugValue}",
      "doNotSellParam": "_fw_us_privacy=" + usPrivacyString,
      "doNotSellParamOptions": {
        "default": "---",
        "disabled": "YNN",
        "enabled": "YYN"
      }
      "raf": {
        "disableAdMeasurements": false
      }
      "yospace": {
        "sdkDisabled": false
      }
    },
    "api": {
      "content": {
        "@note": "Currently pointed at QA Tomato APIs for development.",
        "appConfig": "{foxApiRoot}/v2.0/appconfigs/foxsports-config",
        "categories": "{foxApiRoot}/v2.0/categories",
        "categoryDetail": "{foxApiRoot}/v2.0/categories/{customId}",
        "deeplinkPlayback": "{foxApiRoot}/v2.0/video?uID={contentId}",
        "endSlateUpNextInfo": "{foxApiRoot}/v2.0/upnext/epglistings/v2/{epgListingId}",
        "find": "{foxApiRoot}/v2.0/screens/sports-find",
        "home": "{foxApiRoot}/v2.0/screens/main",
        "live": "{foxApiRoot}/v2.0/screens/foxsportsconnected-live",
        "liveAssetInfo": "{foxApiRoot}/tubi/v3.0/assetinfo/{assetId}",
        "liveUpNextInfo": "{foxApiRoot}/v2.0/upnext/epglistings/{epgListingId}",
        "liveEPGListingInfo": "{foxApiRoot}/v2.0/epglistings/{epgListingId}",
        "movieDetail": "{foxApiRoot}/v2.0/screens/movie-detail/{showCode}",
        "onboarding": "{foxApiRoot}/v2.0/screens/onboarding",
        "pbcHowToWatch": "{foxApiRoot}/v2.0/screens/pbc-howtowatch-33",
        "player": "{foxApiRoot}/v2.0/vodplayer/{videoId}",
        "ppvDetail": "{foxApiRoot}/v2.0/screens/ppv-detail/{contentId}",
        "search": "{foxApiRoot}/v2.0/search?q=",
        "seriesDetail": "{foxApiRoot}/v2.0/screens/series-detail/{showCode}",
        "settings": "http://config.foxdcg.com/foxsports/roku/3.51/settings-staging.json",
        "showsQuery": "{foxApiRoot}/v2.0/series",
        "simpsonsWorldRandom": "{foxApiRoot}/v2.0/screens/random-simpsons",
        "specialDetail": "{foxApiRoot}/v2.0/screens/special-detail/{showCode}",
        "watch": "{foxApiRoot}/v2.0/screens/watch"
      },
      "foxApiRoot": m.constants.urls.foxApiBaseUrl
      "key": "tubi_roku",
      "mvpds": "{foxApiRoot}/v2.0/mvpds",
      "watch": "{foxApiRoot}/tubi/v3.0/watchlive"
    },
    "analytics": {
      "appName": "Tubi",
      "conviva": {
        "customerKey": convivaCustomerKey,
        "disableConvivaLegacy": true,
        "touchstone": {
          "enabled": false,
          "url": "https://fox-test.testonly.conviva.com"
        }
      },
      "mux": {
        "enabled": true,
        "environmentKey": muxEnvironmentKey,
        "trackProgramChanges": false
      }
    },
    "appLogoStyle": "",
    "previewPass": {
      "daily": {
        "mvpdId": "TempPass_fbcfox_5min",
        "timeToLiveSeconds": 300
      },
      "expiryLogo": "https://config.foxdcg.com/foxnow/roku/img/fox.png",
      "isEnabled": true,
      "oneTime": {
        "mvpdId": "TempPass_fbcfox_60min",
        "reset": 1513251159,
        "timeToLiveSeconds": 3600
      },
      "signInOverlay": false
    },
    "auth": {
      "required": false,
      "subscriptions": [],
      "tveEnabled": false,
      "useServerAuthMessageMVPDs": [
        "Spectrum"
      ]
    },
    "autoPlayStillFallback": {
      "default": "http://config.foxdcg.com/foxnow/roku/img/autoplay-fallback_fox.jpg"
    },
    "backgroundImage": "https://config.foxdcg.com/foxnow/roku/img/new_foxnow_background.png",
    "beaconservice": {
      "enabled": true,
      "api": {
        "host": "https://prod.mcvbs.tubi.digitalvideoplatform.com",
        "path": "/mcvbs"
      },
      "concurrency": {
        "frequency": 10
      }
    },
    "bookmarks": {
      "intervalInSeconds": 60,
      "localStorageLimit": 50,
      "useLocalStorage": true
    },
    "capabilities": {
      "optionalAnimations": true,
      "playbackClearScene": false,
      "playbackLimitedAnalytics": false,
      "widgetAnimations": true
    },
    "concurrencyMonitoring": {
      "disabled": true,
      "applicationId": "4f93af93-2b75-47f5-8f80-5a2881a74b68",
      "errorMessage": {
        "text": "You have exceeded your account limits for this service:",
        "title": "Error!"
      },
      "uri": "http://streams.adobeprimetime.com/v2/"
    },
    "contentRefresh": {
      "panelMinValidForInMilliseconds": 60000
    },
    "contentRefreshRandomBuffer": 60,
    "countDownTimerInSeconds": 300,
    "disableOutOfMarketGate": true,
    "error": {
      "disablePlaybackRetry": false
    },
    "extendMvpdTTL": {
      "enabled": true
    },
    "failureRetry": {
      "enabled": false,
      "header": "error_failureRetryTitle",
      "message": "error_failureRetryMessage",
      "responseCodes": [
        500,
        501,
        502,
        503,
        504,
        429
      ]
    },
    "flags": {
      "disableProfile": true
    },
    "hideErrorCode": true,
    "homeScreenBackground": "",
    "imageSize": {
      "appLogo": {},
      "background": {},
      "homeScreenBackground": {},
      "list": {},
      "listLogo": {},
      "logo": {},
      "mvpdLogo": {},
      "networkBug": {}
    },
    "liveEntitlementMapping": {
      "BTN": "btn-btn2go",
      "BTN-DIGITAL": "btn-btn2go",
      "FBN": "FoxBusiness",
      "FNC": "FoxNews",
      "FOX-SOUL": "fox-soul",
      "FOXDEP": "foxdep",
      "FOXFOOD": "foxfood",
      "FOXWEATHER": "foxweather",
      "FS-DIGITAL": "foxsports",
      "FS1": "fs1",
      "FS1-DIGITAL": "fs1",
      "FS2": "fs2",
      "FS2-DIGITAL": "fs2",
      "FSP": "fspl",
      "default": "fbc-fox"
    },
    "logos": {
      "app": "",
      "playerCurtainRiser": "" ' Not using any longer
    }
    "playbackBrowse": {
      "autoDisplay": {
        "@note": "content type are video's collectionType, type, and releaseType. E.g. 'localClips', 'clips', 'fullEpisode', 'VOD', 'Live', etc.",
        "@reference": "DCGPDR-6905, RO-8647",
        "contentTypeEnabled": [
          "localClips"
        ],
        "disableAfterAutoplay": false,
        "displayDurationInSeconds": 3,
        "enabled": true
      },
      "disabled": false,
      "disabledForLive": false,
      "disabledForVOD": false,
      "liveChannelRefreshSeconds": 240,
      "liveRowDisabled": true
    },
    "playerDynamicNetworkBug": "",
    "playerDynamicRating": {
      "displayInSeconds_mid": 0,
      "displayInSeconds_start": 0,
      "fadeOutSeconds": 5
    },
    "ppv": {
      "iap": {
        "debug": false,
        "disableBrowse": true,
        "products": [
          {
            "disabled": true,
            "identifier": "foxnow-roku-ppv6",
            "sku": [
              "us.ppv-fs-pbc-192"
            ],
            "title": "iap_pbc_192_title",
            "currency": "$",
            "price": "74.99",
            "priceValue": 74.99,
            "description": "iap_pbc_192_description",
            "startDate": "2020-12-06T02:00:00.000Z",
            "profileHubBackground": "https://config.foxdcg.com/foxnow/roku/img/ppv-wbc-profile-hub-fn-12-05-2020.jpg",
            "profileFlowBackground": "https://config.foxdcg.com/foxnow/roku/img/ppv-wbc-profile-flow-fn-12-05-2020.jpg",
            "productId": "foxnow-roku-ppv6",
            "packageSKU": "PPN0192L",
            "productSKU": "ppv-fs-pbc-192-live",
            "profileFlowLogo": "https://config.foxdcg.com/foxnow/roku/img/foxnow.png",
            "purchaseFlow": {
              "eventConfirmationScreen": {
                "default": {
                  "displayBody": "ppv_thankYouDefault_body",
                  "displayCta": "ppv_thankYouDefault_cta",
                  "displayHeader": "ppv_thankYouDefault_header"
                },
                "list": [
                  {
                    "@note": "within 1080 min (18 hours) of event start time",
                    "countdownInMinutes": 1080,
                    "displayBody": "ppv_thankYou0days_body",
                    "displayCta": "ppv_thankYou0days_cta",
                    "displayHeader": "ppv_thankYou0days_header"
                  }
                ]
              }
            },
            "trackingData": {
              "page_plan_name": "Spence Jr vs Garcia"
            }
          }
        ]
      }
    },
    "profile": {
      "pollingInterval": 5,
      "upsell": {
        "disabled": true
      }
    },
    "stillWatching": {
      "liveLimitSeconds": 28800,
      "messageDurationSeconds": 120,
      "ppvLimitSeconds": 28800,
      "vodLimitSeconds": 28800
    },
    "theme": {
      "color": {
        "black": "#101010",
        "white": "#FFFFFF",
        "greyLight": "#b0b0b0",
        "transparent": "#00000000"
      },
    },
    "upNextDurationClips": 4,
    "upNextDurationDefault": 7,
    "upNextDurationMovie": 60,
    "upNextDurationSeries": 30,
    "video": {
      "capabilities": {
        "HDR": {
          "HDR10": true,
          "codecs": [
            {
              "codec": "hevc",
              "profile": "main 10",
              "level": "5.1"
            }
          ],
          "refresh": 60
        },
        "SDR": {
          "HDR10": false,
          "codecs": [
            {
              "codec": "hevc",
              "profile": "main",
              "level": "4.0"
            }
          ],
          "refresh": 60
        },
        "UHD": {
          "HDCP": "2.2",
          "refresh": 60,
          "resolution": "2160p"
        }
      },
      "streamTypes": {
        "default": {
          "colorSpace": "SDR",
          "maxRes": "720p",
          "value": "720p"
        },
        "disabled": false,
        "headers": {
          "X-Dcg-Capabilities": "maxRes={maxRes};maxColorSpace={colorSpace}"
        },
        "types": [
          {
            "id": "HDR",
            "requires": {
              "maxRes": "UHD",
              "colorSpace": "HDR"
            },
            "value": "UHD/HDR"
          },
          {
            "id": "SDR",
            "requires": {
              "maxRes": "UHD",
              "colorSpace": "SDR"
            },
            "value": "UHD/SDR"
          },
          {
            "id": "720p",
            "requires": {},
            "value": "720p"
          }
        ]
      },
      "playback": {
        "autoplayContent": {
          "@reference": "DCGPDR-4833",
          "goToFullScreenSeconds": 20
        },
        "displayEndCardOnClips": {
          "enabled": false
        },
        "live": {
          "immediateLiveExitEvent": true,
          "enableControls": true,
        },
        "loop": {
          "@note": "-1 means use autoplayStill (never load background video), 0 means infinite loop, 1 means play once, 2 means play twice etc.",
          "value": 1
        },
        "overrideUpNextCollectionType": true,
        "playback": {
          "4kDevices": [
            "4400X",
            "4620X",
            "4630X",
            "4640X",
            "3810X",
            "4660X",
            "3920X",
            "3921X",
            "4661X"
          ],
          "live": {
            "enableControls": true,
            "liveControlsDisplayDuration": 5,
            "startingBitRate": 2500
          },
          "playerRetryParams": {
            "delayBetweenRetries": 15,
            "enable": true,
            "enableRetryOnVod": true,
            "retriesLeft": 3,
            "timeoutDuration": 20
          },
          "requireHDR10ForUHD": true,
          "showHintSeconds": 3,
          "vod": {
            "startingBitRate": 2500
          }
        },
        "trickplay": {
          "enabled": true,
          "maxImageHeight": 144,
          "maxImageWidth": 256,
          "mergeThumbnailData": true,
          "refreshThrottle": 500,
          "thumbnailBorder": 3,
          "thumbnailHeight": 144,
          "thumbnailWidth": 256
        }
      }
    }
  }

  return config
End Function


Function onFoxVideoPlayerExitStreamChange(msg)
  exitStreamEventData = ""
  exitStreamValue = msg.getData()
  if exitStreamValue <> invalid then
    exitStreamEventData = FormatJSON(exitStreamValue)
  end if

  tubiId = ""
  if m.foxPlayerCurrentListing <> invalid then
    tubiId = m.foxPlayerCurrentListing.tubi_id
  end if

  payload = {
    "tubi_id": tubiId
    "event_data": exitStreamEventData
    "timestamp": createObject("roDateTime").toISOString()
  }
  logInfo(FormatJSON(payload), "videoInfo", "foxLiveExitStream", 0.001)

  m.foxPlayerEndSlateCloseDelayTimer = createObject("roSGNode", "Timer")
  m.foxPlayerEndSlateCloseDelayTimer.observeField("fire", "onFoxPlayerEndSlateCloseDelayTimerFired")
  ' We want to delay foxPlayerEndSlateCloseDelay seconds before we close the player
  m.foxPlayerEndSlateCloseDelayTimer.duration = m.foxPlayerEndSlateCloseDelay
  m.foxPlayerEndSlateCloseDelayTimer.control = "start"
End Function


Function onFoxPlayerEndSlateCloseDelayTimerFired()
  closeFoxVideoPlayer()
End Function


Function onFoxVideoPlayerError(msg)
  ' The Fox player should be showing the error message here. When they hit cancel we back out then. If we want to know the details of the error we can get it here though.
End Function


Function onFoxVideoPlayerPlayerPositionChange(msg)
  position = msg.getData()
  sendFoxVideoPlayerLivePlayProgressEvent(position)

  conditionallyUpdateHistoryForSidelined(position)
End Function


Function conditionallyUpdateHistoryForSidelined(position)
  if m.foxPlayerCurrentListing = invalid then
    tubiLog("conditionallyUpdateHistoryForSidelined m.foxPlayerCurrentListing is invalid")
  else if m.foxPlayerCurrentListing.enable_watch_history = true then
    if m.foxPlayerPositionSidelinedStarted < 0 then
      ' Go ahead and set the start position for the sidelined content if we haven't already
      m.foxPlayerPositionSidelinedStarted = position
    end if



    if position >= m.foxPlayerContinueWatchingNextSendPosition
      m.foxPlayerContinueWatchingNextSendPosition = position + getExternalConfigValueFromGlobal("special_event_continue_watching_post_interval", 180)

      sideLinedContentPosition = position - m.foxPlayerPositionSidelinedStarted

      content = createObject("roSGNode", "ContentNode")
      content.update({
        "type": m.constants.ui.contentTypes.video
        "id": m.foxPlayerCurrentListing.tubi_id
        "nowPos": sideLinedContentPosition ' Will crash later if not present
        "parentId": m.foxPlayerCurrentListing.parent_id
      }, true)
      updateHistoryAndHandleResponse(content, sideLinedContentPosition, true)
    end if
  end if
End Function


Function onFoxVideoPlayerAdStateChange(msg)
  adState = msg.getData()
  playerPosition = msg.getInfo().playerPosition

  if adState = "adBreakStarted" then
    yospaceAdContext = m.foxRpfInstance.yospaceAdContext

    if isNonEmptyArray(yospaceAdContext) = true
      m.currentFoxPlayerAdBreak = yospaceAdContext[0]
    end if
  else if adState = "adStarted" then
    sendFoxVideoPlayerLiveAdAnalyticEvent("start_ad", m.currentFoxPlayerAdBreak, playerPosition)
  else if adState = "adCompleted" then
    sendFoxVideoPlayerLiveAdAnalyticEvent("finish_ad", m.currentFoxPlayerAdBreak, playerPosition)
  else if adState = "adBreakCompleted" then
    sendFoxVideoPlayerLiveAdAnalyticEvent("finish_ad", m.currentFoxPlayerAdBreak, playerPosition)

    m.currentFoxPlayerAdBreak = invalid
  end if
End Function


Function findCurrentAdInBreak(currentFoxPlayerAdBreak, playerPosition)
  if currentFoxPlayerAdBreak = invalid OR isNonEmptyArray(currentFoxPlayerAdBreak.ads) = false then
    return invalid
  end if

  for each ad in currentFoxPlayerAdBreak.ads
    if isAA(ad) = true AND fix(ad.renderTime) <= playerPosition AND ad.renderTime + ad.duration >= playerPosition then
      return ad
    end if
  end for

  logWarn("onFoxVideoPlayerAdStateChange could not find current ad in break")

  return invalid
End Function


Function sendFoxVideoPlayerLiveAdAnalyticEvent(eventType, currentFoxPlayerAdBreak, playerPosition, additionalValues = {})
  if currentFoxPlayerAdBreak = invalid then
    logWarn("currentFoxPlayerAdBreak is invalid")
    return invalid
  end if

  currentAd = findCurrentAdInBreak(currentFoxPlayerAdBreak, playerPosition)

  ' First ad should always be the active one but we verify
  if currentAd = invalid then
    logWarn("onFoxVideoPlayerAdStateChange adStarted but currentAd is invalid")
    return invalid
  else if m.foxPlayerCurrentListing = invalid then
    tubiLog("sendFoxVideoPlayerLiveAdAnalyticEvent m.foxPlayerCurrentListing is invalid")
    return invalid
  end if

  creativeId = 0
  if isString(currentAd.creativeId) = true then
    creativeId = currentAd.creativeId.toInt()
  end if

  adValue = {
    "ad_id": currentAd.adId
    "creative_id": creativeId
    "reported_duration": currentAd.duration * 1000
    "parent_id": currentFoxPlayerAdBreak.breakId
    "index": currentAd.index
    "pod_size": currentFoxPlayerAdBreak.totalAds
  }

  values = {
    "video_id": m.foxPlayerCurrentListing.tubi_id
    "is_fullscreen": true
    "video_player": "DEFAULT"
    "is_proxy_event": false
  }

  values.append(additionalValues)

  if eventType = "start_ad" then
    values["ad_started"] = adValue
    values["start_position"] = 0
  else if eventType = "finish_ad" then
    if values.exit_type = invalid then
      values["exit_type"] = "AUTO"
    end if

    values["ad_finished"] = adValue
  end if

  event = {
    "type": eventType
    "values": values
  }

  fireUserTrackingEvent(event)

  return event
End Function


' Sends the live play progress event to TrackingLoggingTask
' @param position: The current position of the video player
' @param alwaysSend: If true, the event will be sent even if the view time is less than 10 seconds
Function sendFoxVideoPlayerLivePlayProgressEvent(position, alwaysSend = false)
  ' The first position we get is a unix timestamp which we don't want to use for our progress events so we ignore that value by making sure the position isn't high like a unix timestamp would be
  if isNumber(position) = false OR position > 999999999 then
    tubiLog("sendFoxVideoPlayerLivePlayProgressEvent position is not a valid number")
  else if m.foxPlayerCurrentListing = invalid then
    tubiLog("sendFoxVideoPlayerLivePlayProgressEvent m.foxPlayerCurrentListing is invalid")
  else
    if m.lastSentFoxPlayerProgressPosition = -1 then
      m.lastSentFoxPlayerProgressPosition = position
    else
      viewTime = position - m.lastSentFoxPlayerProgressPosition

      videoId = m.foxPlayerCurrentListing.tubi_id
      if videoId <> invalid AND (viewTime >= 10 OR (alwaysSend = true AND viewTime > 0)) then
        event = {
          type: "live_play_progress"
          values: {
            video_id: videoId
            has_subtitles: ""
            video_player: "DEFAULT"
            video_codec_type: ""
            video_resolution: ""
            is_fullscreen: true
            ' Convert to milliseconds
            view_time: viewTime * 1000
            pageOneof: m.Tracking.getAnalyticsPage("video_player_page", { video_id: videoId })
            eventOrigin: "foxPlayer"
          }
        }
        m.trackingLoggingTask.trackEvent = event
        m.lastSentFoxPlayerProgressPosition = position
      end if
    end if
  end if
End Function


Function onFoxVideoPlayerAlertDialogCancelledChange(msg)
  ' When we receive a cancel from the alert dialog, we close the fox player as this is the only action in this case
  closeFoxVideoPlayer()
End Function


Function closeFoxVideoPlayer()
  foxVideoPlayerWrapperScreen = getScreenFromStackById(m.constants.ui.screenIds.foxVideoPlayerWrapperScreen)
  if foxVideoPlayerWrapperScreen <> invalid then
    foxVideoPlayerWrapperScreen.closePlayer = true
  end if

  if m.foxPlayerEndSlateCloseDelayTimer <> invalid then
    ' Avoids case that that timer starts and you exit and then go back in and then get kicked out when timer fires
    m.foxPlayerEndSlateCloseDelayTimer.unobserveFieldScoped("fire")
    m.foxPlayerEndSlateCloseDelayTimer = invalid
  end if
End Function


Function onFoxVideoPlayerWillPlayerClose()
  showHideLogoBasedOnUiMode()

  if m.foxRpfInstance <> invalid AND m.foxRpfInstance.playerEvent <> invalid then
    playerPosition = m.foxRpfInstance.playerEvent.playerPosition

    if m.currentFoxPlayerAdBreak <> invalid then
      ' If we are closing the player while an ad break is active then we need to send the ad finished event
      sendFoxVideoPlayerLiveAdAnalyticEvent("ad_finished", m.currentFoxPlayerAdBreak, playerPosition, {
        "exit_type": "DELIBERATE"
      })
    end if

    sendFoxVideoPlayerLivePlayProgressEvent(playerPosition, true)
  end if

  ' We invalidate the foxPlayerEndSlateCloseDelayTimer to prevent it from triggering after the player is closed
  m.foxPlayerEndSlateCloseDelayTimer = invalid

  ' Reset current listing so we properly startup the next time we come back
  m.foxPlayerCurrentListing = invalid

  popScreen(true, false)
End Function


Function onFoxVideoPlayerLoadTimeChange(msg)
  screen = msg.getRoSGNode()

  loadTime = msg.getData()

  screenTrackingLoad(screen.trackingPageInfo, loadTime)
End Function


Function retrieveFoxListingResponse()
  m.makeRequest({
    url: m.constants.urls.foxListingEndpoint
    requestType: m.constants.reqNames.generic
    successCallback: retrieveFoxListingResponseSuccess
    errorCallback: retrieveFoxListingResponseError
    responseType: "array"
    retries: 0
    analyticsScreenId: m.constants.ui.screenIds.foxVideoPlayerWrapperScreen
  })
End Function


Function retrieveFoxListingResponseSuccess(response)
  if response <> invalid then
    ' Check if we an existing foxListingEndpointResponse. If not we are starting the playback and we need to set the contentId on the foxVideoPlayerWrapperScreen
    initialFoxListingRequest = (m.foxPlayerCurrentListing = invalid)

    m.foxListingEndpointResponse = response

    foxVideoPlayerWrapperScreen = getScreenFromStackById(m.constants.ui.screenIds.foxVideoPlayerWrapperScreen)
    tubiId = invalid
    if foxVideoPlayerWrapperScreen <> invalid then tubiId = foxVideoPlayerWrapperScreen.tubiId

    listing = findFoxLiveProgram(m.foxListingEndpointResponse, tubiId)
    m.foxPlayerCurrentListing = listing

    if initialFoxListingRequest = true AND foxVideoPlayerWrapperScreen <> invalid AND listing <> invalid then
      foxVideoPlayerWrapperScreen.tubiId = listing.tubi_id
      foxVideoPlayerWrapperScreen.contentId = listing.id

      event = {
        type: "start_live_video"
        values: {
          video_id: listing.tubi_id
          has_subtitles: ""
          video_player: "DEFAULT"
          video_codec_type: ""
          video_resolution: ""
          is_fullscreen: true
          input_device: "UNKNOWN_DEVICE"
          pageOneof: m.Tracking.getAnalyticsPage("video_player_page", { video_id: listing.tubi_id })
          eventOrigin: "foxPlayer"
        }
      }
      m.trackingLoggingTask.trackEvent = event
    else if listing = invalid AND foxVideoPlayerWrapperScreen <> invalid then
      closeFoxVideoPlayer()
    end if
    currentScreen = getCurrentScreen()
    if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.foxVideoPlayerWrapperScreen then
      showHideLogo(m.constants.logoType.hide)
    end if
  end if
End Function


Function retrieveFoxListingResponseError(response)
  sendFoxPlayerErrorBeforePlayEvent("Listing load error:" + formatJson(response))
  closeFoxVideoPlayer()
End Function


' Finds the best in-progress program from the fox listing response.
' @param listing: array of listing items from the fox listing endpoint
' @param tubiId: tubi_id of the content node to prefer when multiple items are in-progress
' @return: matched listing, first in-progress listing, or invalid
Function findFoxLiveProgram(listing, tubiId = invalid)
  if isNonEmptyArray(listing) = false then return invalid

  firstInProgress = invalid

  for each item in listing
    asset = item.asset
    if asset <> invalid AND asset.listing <> invalid AND asset.listing.tubi_id <> invalid AND asset.listing.startDate <> invalid AND asset.listing.endDate <> invalid then
      if isNowWithinTimePeriod(asset.listing.startDate, asset.listing.endDate) then
        if isNonEmptyString(tubiId) AND asset.listing.tubi_id = tubiId then
          return asset.listing
        end if
        if firstInProgress = invalid then firstInProgress = asset.listing
      end if
    end if
  end for

  return firstInProgress
End Function


Function sendFoxPlayerErrorBeforePlayEvent(message)
  event = {
    "increment": [{
      "metric": "web_ott.performance.metrics.seaTiger.errorBeforePlay",
      "value": 1
    }]

    "log": [{
      "message": "seatiger_playback: " + message
      "level": "error"
    }]

  }

  m.trackingLoggingTask.trackRealtimeEvent = event
End Function
