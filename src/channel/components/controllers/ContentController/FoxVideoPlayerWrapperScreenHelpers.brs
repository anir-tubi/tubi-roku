' Call to play linear video with fox player
' @param content: The content we want to play as returned by homescreen and container endpoints
Function playLinearVideoWithFoxPlayer(content)
  if isNode(content) = false then
    tubiLog("playLinearVideoWithFoxPlayer content is not a node")
  else
    ' Used to route fox player watch call through Charles
    ' m.global.update({
    '   proxyParameters: {
    '     "isProxyEnabled": true
    '     "proxyIp": "192.168.10.117"
    '   }
    ' }, true)


    videoId = content.id.toInt()

    ' We immediately show the player screen so we can show the loading spinner but have to wait until we are ready to actually try playing video
    m.foxPlayerCurrentContentId = videoId

    m.lastSentFoxPlayerProgressPosition = 0

    event = {
      type: "start_live_video"
      values: {
        video_id: videoId
        has_subtitles: ""
        video_player: "DEFAULT"
        video_codec_type: ""
        video_resolution: ""
        is_fullscreen: true
        input_device: "UNKNOWN_DEVICE"
        pageOneof: m.Tracking.getAnalyticsPage("video_player_page", { video_id: videoId })
        eventOrigin: "foxPlayer"
      }
    }

    m.trackingLoggingTask.trackEvent = event

    showHideLogo(m.constants.logoType.hide)

    foxVideoPlayerWrapperScreen = createObject("roSGNode", "FoxVideoPlayerWrapperScreen")
    foxVideoPlayerWrapperScreen.id = m.constants.ui.screenIds.foxVideoPlayerWrapperScreen
    foxVideoPlayerWrapperScreen.observeFieldScoped("willPlayerClose", "onFoxVideoPlayerWillPlayerClose")
    foxVideoPlayerWrapperScreen.tubiContent = content

    pushScreen(foxVideoPlayerWrapperScreen, true, true)

    ' If we haven't retrieved the fox player yet then start loading it
    if m.isFoxPlayerLoadRequired = true
      loadFoxVideoPlayerComponentLibrary()
    else if m.foxRpfInstance <> invalid then
      assignProfileIdToFoxVideoPlayer(m.foxRpfInstance)

      ' If the fox player has finished loading then we can start playing the video. We check for this by looking if m.foxRpfInstance has been set which we set after load is completed. Else we will wait for the load to complete with the already set onFoxVideoPlayerComponentLibraryLoadStatus observer
      foxVideoPlayerWrapperScreen.isFoxVideoPlayerAvailable = true
    end if

    ' TODO update when we figure out what we are doing for UI
    ' getFoxListingItemsAndRefreshPurpleCarpetContainerData(setFoxContentId)
    foxVideoPlayerWrapperScreen.contentId = content.listingId
  end if
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
      ' Setting to true enables debug logs from player
      initializer.debug = (m.constants.settings.mode <> "production")

      ' Setting the config triggers the fox player to initialize
      initializer.config = getFoxVideoPlayerConfig()

      foxRpfInstance = initializer.foxRpfInstance

      if foxRpfInstance = invalid then
        didFoxPlayerLoadFail = true
      else
        m.foxRpfInstance = foxRpfInstance

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

          foxRpfInstance.playerEvent.observeFieldScoped("adState", "onFoxVideoPlayerAdStateChange")
        end if

        foxRpfInstance.observeFieldScoped("playerLoaded", "onFoxVideoPlayerLoaded")
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
          m.foxPlayerCurrentContentId = listing.tubi_id.toInt()
          exit for
        end if
      end if
    end for
  end if
End Function


Function getFoxVideoPlayerConfig()
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
      "raf": {
        "disableAdMeasurements": false
      }
      "yospace": {
        "devices": [
          "3810X",
          "*"
        ],
        "playheadManipulation": {
          "disabled": true,
          "dvrWindowSize": 3600,
          "dvrSeekTime": 15,
          "DVRControls": {
            "disabled": true
          }
        },
        "sdkDisabled": false
      }
    },
    "api": {
      "content": {
        "categories": "{foxApiRoot}/v2.0/categories",
        "categoryDetail": "{foxApiRoot}/v2.0/categories/{customId}",
        "deeplinkPlayback": "{foxApiRoot}/v2.0/video?uID={contentId}",
        "endSlateUpNextInfo": "{foxApiRoot}/v2.0/upnext/epglistings/v2/{epgListingId}",
        "find": "{foxApiRoot}/v2.0/screens/sports-find",
        "home": "{foxApiRoot}/v2.0/screens/main",
        "live": "{foxApiRoot}/v2.0/screens/foxsportsconnected-live",
        "liveAssetInfo": "{foxApiRoot}/v3.0/assetinfo/{assetId}",
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
      "watch": "{foxApiRoot}/v3.0/watchlive"
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
        "host": "https://prod.mcvbs.sb.digitalvideoplatform.com",
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


Function onFoxVideoPlayerExitStreamChange()
  m.foxPlayerEndSlateCloseDelayTimer = createObject("roSGNode", "Timer")
  m.foxPlayerEndSlateCloseDelayTimer.observeField("fire", "onFoxPlayerEndSlateCloseDelayTimerFired")
  ' We want to delay 60 seconds before we close the player
  m.foxPlayerEndSlateCloseDelayTimer.duration = 60
  m.foxPlayerEndSlateCloseDelayTimer.control = "start"
End Function


Function onFoxPlayerEndSlateCloseDelayTimerFired()
  closeFoxVideoPlayer()
End Function


Function onFoxVideoPlayerLoaded(msg)
  ' print "onFoxVideoPlayerLoaded " msg.getData()
End Function


Function onFoxVideoPlayerError(msg)
  ' print "onFoxVideoPlayerError " msg.getData()
End Function


Function onFoxVideoPlayerPlayerPositionChange(msg)
  position = msg.getData()
  sendFoxVideoPlayerLivePlayProgressEvent(position)
End Function


Function onFoxVideoPlayerAdStateChange(msg)
  ' TODO add In
  print "onFoxVideoPlayerAdStateChange " msg.getData()
End Function


' Sends the live play progress event to TrackingLoggingTask
' @param position: The current position of the video player
' @param alwaysSend: If true, the event will be sent even if the view time is less than 10 seconds
Function sendFoxVideoPlayerLivePlayProgressEvent(position, alwaysSend = false)
  ' The first position we get is a unix timestamp which we don't want to use for our progress events so we ignore that value by making sure the position isn't high like a unix timestamp would be
  if isNumber(position) = false OR position > 999999999 then
    tubiLog("sendFoxVideoPlayerLivePlayProgressEvent position is not a valid number")
  else
    if m.lastSentFoxPlayerProgressPosition = -1 then
      m.lastSentFoxPlayerProgressPosition = position
    else
      viewTime = position - m.lastSentFoxPlayerProgressPosition

      videoId = m.foxPlayerCurrentContentId
      if videoId <> invalid AND (viewTime >= 60 OR (alwaysSend = true AND viewTime > 0)) then
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
  ' We invalidate the foxPlayerEndSlateCloseDelayTimer to prevent it from triggering after the player is closed
  m.foxPlayerEndSlateCloseDelayTimer = invalid

  foxVideoPlayerWrapperScreen = getScreenFromStackById(m.constants.ui.screenIds.foxVideoPlayerWrapperScreen)
  if foxVideoPlayerWrapperScreen <> invalid then
    foxVideoPlayerWrapperScreen.closePlayer = true
  end if
End Function


Function onFoxVideoPlayerWillPlayerClose()
  showHideLogoBasedOnUiMode()

  if m.foxRpfInstance <> invalid AND m.foxRpfInstance.playerEvent <> invalid then
    sendFoxVideoPlayerLivePlayProgressEvent(m.foxRpfInstance.playerEvent.playerPosition, true)
  end if

  m.foxPlayerCurrentContentId = invalid

  if isMajorEventDay() = true AND getExternalConfigValueFromGlobal("disaster_mode_enabled", false) = true
    popScreen(true, false)
  else
    ' We want to remove all screens from the stack until we get to the homescreen. If we do not find the homescreen in the stack then we empty the stack and startChannel() will be called
    for i = 0 to getScreenStackSize() - 1
      screen = getCurrentScreen()
      if screen <> invalid AND screen.id = m.constants.ui.screenIds.homeScreen
        exit for
      end if

      popScreen(true, false)
    end for

    ' Given that the playback can be initiated from the trending searches container on the search screen, we need to ensure that when all screens are closed and the home screen is displayed, the focus is reset to the 'Home' option in the side navigation.
    focusSideNavOption(m.constants.ui.sideNavIds.home)
  end if
End Function


Function setFoxContentId(purpleCarpetContainer, _screenId)
  ' This happens during sign in process from purple carpet during which we are trying to start playback and also refreshing home screen.
  ' This does not happen if we are not fast enough in sign in. Below logic provides additional safety to make sure preview is always stopped.
  stopVideoPreview()
  if purpleCarpetContainer <> invalid then
    currentScreen = getCurrentScreen()
    if currentScreen.id = m.constants.ui.screenIds.foxVideoPlayerWrapperScreen then
      contentIdToPlay = ""

      tubiContent = currentScreen.tubiContent

      if tubiContent <> invalid
        contentNode = m.nodeHelpers.getChildById(purpleCarpetContainer, tubiContent.id)

        if contentNode <> invalid AND contentNode.foxContentId <> invalid then
          ' We need to find the matching content from the Fox listing endpoint response so we can check its network
          if isArray(m.foxListingEndpointResponse) = true then
            for each item in m.foxListingEndpointResponse
              if item.asset <> invalid AND item.asset.listing <> invalid AND item.asset.listing.id = contentNode.foxContentId then
                ' Now that we have lined up the Tubi content and Fox content check if the network is foxdep to know whether to treat it differently. foxdep contains a spanish version of the stream that doesn't have different program ids within it.
                if item.asset.listing.network = "foxdep" then
                  ' In this case we just want to play the selected content
                  contentIdToPlay = contentNode.foxContentId
                end if
                exit for
              end if
            end for
          end if

        end if


        ' If we don't have a valid contentIdToPlay yet then we need to search through the Fox listing items to find what is currently playing
        if isNonEmptyString(contentIdToPlay) = false then
          for each item in m.foxListingEndpointResponse
            if item.asset <> invalid AND item.asset.listing <> invalid then
              listing = item.asset.listing

              ' Check to see if this item is currently live
              if listing.network <> "foxdep" AND isNowWithinTimePeriod(listing.startDate, listing.endDate) = true then
                contentIdToPlay = listing.id
                exit for
              end if
            end if
          end for
        end if
      end if

      if isNonEmptyString(contentIdToPlay) = true then
        currentScreen.contentId = contentIdToPlay
      else
        tubiLog("setFoxContentId contentIdToPlay is invalid. Closing player.")
        closeFoxVideoPlayer()
      end if
    end if
  end if
End Function
