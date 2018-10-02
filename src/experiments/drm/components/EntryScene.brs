'*********************************************************************
'** (c) 2016-2017 Roku, Inc.  All content herein is protected by U.S.
'** copyright and other applicable intellectual property laws and may
'** not be copied without the express permission of Roku, Inc., which
'** reserves all rights.  Reuse of any of this content for any purpose
'** without the permission of Roku, Inc. is strictly prohibited.
'*********************************************************************

sub init()
    'we use a simple LabelList for a menu
    m.list = m.top.FindNode("list")
    m.list.observeField("itemSelected", "onItemSelected")
    m.list.SetFocus(true)


    m.videoContent = {
      children: [
        ' All PlayReady content from http://test.playready.microsoft.com/
        {
          title: "PlayReady 2.0+"
          children: [
            ' AZURE MEDIA SERVICES ON DEMAND H264 AAC 4K CENC PLAYREADY 2.0
            {
              id: "1"
              title: "1) DASH - AZURE MEDIA SERVICES ON DEMAND H264 AAC 4K CENC PLAYREADY 2.0"
              'streamFormat: "dash"
              description: "dash"
              url: "http://profficialsite.origin.mediaservices.windows.net/c51358ea-9a5e-4322-8951-897d640fdfd7/tearsofsteel_4k.ism/manifest(format=mpd-time-csf)"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }
            {
              id: "2"
              title: "2) SMOOTH - AZURE MEDIA SERVICES ON DEMAND H264 AAC 4K CENC PLAYREADY 2.0" 
              'streamFormat: "ism"
              description: "ism"
              url: "http://profficialsite.origin.mediaservices.windows.net/c51358ea-9a5e-4322-8951-897d640fdfd7/tearsofsteel_4k.ism/manifest"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }
            {
              id: "3"
              title: "3) HLS - AZURE MEDIA SERVICES ON DEMAND H264 AAC 4K CENC PLAYREADY 2.0" 
              'streamFormat: "hls"
              description: "hls"
              url: "http://profficialsite.origin.mediaservices.windows.net/c51358ea-9a5e-4322-8951-897d640fdfd7/tearsofsteel_4k.ism/manifest(format=m3u8-aapl)"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }

            ' AZURE MEDIA SERVICES ON DEMAND H264 AAC 1080p Clear
            {
              id: "4"
              title: "4) DASH - AZURE MEDIA SERVICES ON DEMAND H264 AAC 1080p Clear"
              'streamFormat: "dash"
              description: "dash"
              url: "http://amssamples.streaming.mediaservices.windows.net/683f7e47-bd83-4427-b0a3-26a6c4547782/BigBuckBunny.ism/manifest(format=mpd-time-csf)"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }
            {
              id: "5"
              title: "5) SMOOTH - AZURE MEDIA SERVICES ON DEMAND H264 AAC 1080p Clear"
              'streamFormat: "ism"
              description: "ism"
              url: "http://amssamples.streaming.mediaservices.windows.net/683f7e47-bd83-4427-b0a3-26a6c4547782/BigBuckBunny.ism/manifest"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }

            ' AZURE MEDIA SERVICES LIVE PLAYREADY 2.0
            {
              id: "6"
              title: "6) DASH - AZURE MEDIA SERVICES LIVE PLAYREADY 2.0"
              'streamFormat: "dash"
              description: "dash"
              url: "http://profficialsite.origin.mediaservices.windows.net/9cc5e871-68ec-42c2-9fc7-fda95521f17d/dayoneplayready.ism/manifest(format=mpd-time-csf)"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }
            {
              id: "7"
              title: "7) SMOOTH - AZURE MEDIA SERVICES LIVE PLAYREADY 2.0"
              'streamFormat: "ism"
              description: "ism"
              url: "http://profficialsite.origin.mediaservices.windows.net/9cc5e871-68ec-42c2-9fc7-fda95521f17d/dayoneplayready.ism/manifest"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }
            {
              id: "8"
              title: "8) HLS - AZURE MEDIA SERVICES LIVE PLAYREADY 2.0"
              'streamFormat: "hls"
              description: "hls"
              url: "http://profficialsite.origin.mediaservices.windows.net/9cc5e871-68ec-42c2-9fc7-fda95521f17d/dayoneplayready.ism/manifest(format=m3u8-aapl)"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }

            ' IIS PLAYREADY2.0 VOD (720p, H264 AAC, encrypted)
            {
              id: "9"
              title: "9) SMOOTH - IIS PLAYREADY2.0 VOD (720p, H264 AAC, encrypted)"
              'streamFormat: "ism"
              description: "ism"
              url: "http://test.playready.microsoft.com/smoothstreaming/SSWSS720H264PR/SuperSpeedway_720.ism/Manifest"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }

            ' IIS PLAYREADY2.0 VOD (720p, H264 AAC, clear)
            {
              id: "10"
              title: "10) SMOOTH - IIS PLAYREADY2.0 VOD (720p, H264 AAC, clear)"
              'streamFormat: "ism"
              description: "ism"
              url: "http://test.playready.microsoft.com/smoothstreaming/SSWSS720H264/SuperSpeedway_720.ism/Manifest"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }

            ' IIS PLAYREADY2.0 LIVE - H264 AAC CENC Live with Key Rotation
            {
              id: "11"
              title: "11) SMOOTH - IIS PLAYREADY2.0 LIVE - H264 AAC CENC Live with Key Rotation"
              'streamFormat: "ism"
              description: "ism"
              url: "http://playready.directtaps.net/media/live/channel01.isml/Manifest"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "https://playready.directtaps.net/svc/live/root/rightsmanager.asmx"
            }
          ]
        }
        {
          title: "PlayReady 3.0+"
          children: [
            ' H.264 1920x1080 @6Mbps content
            {
              id: "12"
              title: "12) MP4 - ENCRYPTED - H.264 1920x1080 @6Mbps content"
              'streamFormat: "mp4"
              description: "mp4"
              url: "http://profficialsite.origin.mediaservices.windows.net/228e2071-c79b-4bb7-b999-0f74801c924a/tearsofsteel_1080p_60s_24fps.6000kbps.1920x1080.h264-8b.2ch.128kbps.aac.avsep.cenc.mp4"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }
            {
              id: "13"
              title: "13) MP4 - CLEAR - H.264 1920x1080 @6Mbps content"
              'streamFormat: "mp4"
              description: "mp4"
              url: "http://profficialsite.origin.mediaservices.windows.net/aac2a25c-0dbc-46bd-be5f-68f3df1fc1f6/tearsofsteel_1080p_60s_24fps.6000kbps.1920x1080.h264-8b.2ch.128kbps.aac.mp4"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }

            ' H.264 3840x2160 @12Mbps audio clear
            {
              id: "14"
              title: "14) MP4 - ENCRYPTED - H.264 3840x2160 @12Mbps audio clear"
              'streamFormat: "mp4"
              description: "mp4"
              url: "http://profficialsite.origin.mediaservices.windows.net/e220a11e-aa2c-4396-9d6c-daee6b1593be/tearsofsteel_4k_60s_24fps.12000kbps.3840x2160.h264-8b.2ch.128kbps.aac.audioclear.cenc.mp4"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }
            {
              id: "15"
              title: "15) MP4 - CLEAR - H.264 3840x2160 @12Mbps audio clear"
              'streamFormat: "mp4"
              description: "mp4"
              url: "http://profficialsite.origin.mediaservices.windows.net/e220a11e-aa2c-4396-9d6c-daee6b1593be/tearsofsteel_4k_60s_24fps.12000kbps.3840x2160.h264-8b.2ch.128kbps.aac.audioclear.cenc.mp4"
              encodingType: "PlayReadyLicenseAcquisitionUrl"
              encodingKey: "http://test.playready.microsoft.com/service/rightsmanager.asmx?cfg=(persist:false,sl:150)"
            }
          
          ]
        }

        ' Widevine test content from
        {
          title: "Widevine"
          children: [
            {
              id: "16"
              title: "16) DASH - Widevine"
              'streamFormat: "dash"
              description: "dash"
              url: "https://demo.unified-streaming.com/video/tears-of-steel/tears-of-steel-dash-widevine.ism/.mpd"
              ' these will be set explicitly later on
              'drmParams: {
              '  keySystem: "Widevine"
              '  licenseServerURL: "https://cwip-shaka-proxy.appspot.com/no_auth"
              '}
            }
          ]
        }
      ]
    }

    listContent = CreateObject("roSGNode", "ContentNode")
    listContent.update(m.videoContent)
    ' update doesn't set contenttype correctly
    for i=0 to listContent.getChildCount()-1
      section = listContent.getChild(i)
      section.contenttype = "SECTION"
      for j=0 to section.getChildCount()-1
        item = section.getChild(j)
        item.streamFormat = item.description ' streamformat invokes a setter and must be done this way to be applied correctly
        if item.id = "16"
          item.drmParams = {
            keySystem: "Widevine"
            licenseServerURL: "https://cwip-shaka-proxy.appspot.com/no_auth"
          }
        end if
      end for
    end for
    m.list.content = listContent

    di = CreateObject("roDeviceInfo")
    m.drmInfo = di.GetDrmInfo()
  print "drmInfo = "; m.drmInfo
    m.drmInfoEx = di.GetDrmInfoEx()
  print "drmInfoEx = {"
    for each key in m.drmInfoEx
      print "drmInfoEx["; key; "] = "; m.drmInfoEx[key]
    end for

end sub

sub onItemSelected()
    m.list.SetFocus(false) ' un-set focus to avoid creating multiple players on user tapping twice
    index = m.list.itemSelected
    for i=0 to m.list.content.getChildCount()-1
      section = m.list.content.getChild(i)
      if index >= section.getChildCount()
        index -= section.getChildCount()
      else
        content = section.getChild(index)
        exit for
      end if
    end for

    if m.Player = invalid:
        m.Player = m.top.CreateChild("Player")
        m.Player.observeField("state", "PlayerStateChanged")
    end if

    'start the player
    m.Player.content = content
    m.Player.visible = true
    m.Player.control = "play"
end sub

sub PlayerStateChanged()
    print "EntryScene: PlayerStateChanged(), state = "; m.Player.state
    if m.Player.state = "done" or m.Player.state = "stop"
        m.Player.visible = false
        m.list.setFocus(true) 'NB. the player took the focus away, so get it back
    end if
end sub
