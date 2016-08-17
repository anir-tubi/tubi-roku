function AdriseSelectableAds (utils)
  return {
    getUserChoice: adriseSelectableAds_getUserChoice
	  showUserSelectedVideoAd: adriseSelectableAds_showUserSelectedVideoAd
	  handleAdClick: adriseSelectableAds_handleAdClick
	  utils: utils
  }
end function

' ******************************************************
'  adriseSelectableAds_showUserSelectedVideoAd(adUnit)
'   returns "CLOSED" or "COMPLETED"
' ******************************************************
function adriseSelectableAds_showUserSelectedVideoAd(adUnit As Object)
  p = CreateObject("roMessagePort")
  video = CreateObject("roVideoScreen")
  video.setMessagePort(p)
  video.SetContent(adUnit)
  video.SetPositionNotificationPeriod(1)
  video.show()
  lastSavedPos = 0
  positionPercentage = 0
  statusInterval = adUnit.Duration.toInt() / 4

  while true
      msg = wait(0, video.GetMessagePort())
      if (msg) = false
        if type(msg) = "roVideoScreenEvent"
          if msg.isScreenClosed()
            return "CLOSED"
          else if msg.isFullResult()
            if (positionPercentage >= 75)
              m.utils.trackEvent({adUnit: adUnit, trackType: "viewthru", adPercentage: 100})
            end if
          else if msg.isPlaybackPosition()
            nowpos = msg.GetIndex()
            if nowpos = 0
              m.utils.trackEvent({adUnit: adUnit, trackType: "viewthru", adPercentage: positionPercentage})
            else if nowpos > 0
              if abs(nowpos - lastSavedPos) > statusInterval
                lastSavedPos = nowpos
                positionPercentage = positionPercentage + 25
                if (positionPercentage < 100)
                  m.utils.trackEvent({adUnit: adUnit, trackType: "viewthru", adPercentage: positionPercentage})
                end if
              end if
            end if
          else if msg.isRequestFailed()
            print "=adRise=: play failed: "; msg.GetMessage()
          else
            ' print "=adRise=: Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
          end if
      end if
    end if
  end while
  return "COMPLETED"
end function

' ******************************************************
'  adriseSelectableAds_handleAdClick(adUnit)
'   either show the selected video, or, if the adUnit says so,
'   go to the app in the store
' ******************************************************
function adriseSelectableAds_handleAdClick(adUnit)
  m.utils.trackEvent({adUnit: adUnit, trackType: "click"})

  if adUnit.PluginID <> ""
    m.utils.channelStoreGoToApp(adUnit.PluginID)
  else if adUnit.StreamUrls <> "" and adUnit.adType <> "video"
    m.showUserSelectedVideoAd(adUnit)
  end if
end function

' ******************************************************
' getUserChoice(adOptions, duration)
' returns index of ad selected, or -1
' ******************************************************
function adriseSelectableAds_getUserChoice(adOptions, duration, definition)
  ' Create canvas to display images. Based on user selection
  ' return the id of the ad_option
  port = CreateObject("roMessagePort")
  canvas = CreateObject("roImageCanvas")
  canvas.SetMessagePort(port)
  canvas.SetLayer(0, {Color:"#000000", CompositionMode:"Source"})

  numberOfOptions = adOptions.count()
  images = []

  for i=0 to numberOfOptions-1 step +1
    hdOrSdImages = adOptions[i].ad_images.image
    which = 0
    if(hdOrSdImages[0]@type = definition)
      which = 1
    end if
    images[i] = hdOrSdImages[which].getText().trim()
  end for

  imageIndex = 0
  m.utils.showImageOnCanvas(images[imageIndex], canvas, {mode: "3"})
  canvas.show()

  while(true)
      msg = wait(duration,port)
      if type(msg) = "roImageCanvasEvent"
        if (msg.isRemoteKeyPressed())
          i = msg.GetIndex()
          if (i = 2)
            if (imageIndex > 0)
              imageIndex = imageIndex - 1
              m.utils.showImageOnCanvas(images[imageIndex], canvas, {mode: "4"})
            end if
          else if (i = 3)
            if (imageIndex < numberOfOptions-1)
              imageIndex = imageIndex+1
              m.utils.showImageOnCanvas(images[imageIndex], canvas, {mode: "5"})
            end if
          else if (i = 6)
            return imageIndex
          end if
        end if
      else
        return -1
      end if
  end while
end function
