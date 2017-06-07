print "hot patch 4"

deviceInfo = CreateObject( "roDeviceInfo")

version = deviceInfo.GetVersion()
major = Mid(version, 3, 1)
if major = "3"
  m.app.cp.setContentType("mp4")
  m.app.player.contentType = "mp4"
else
  m.app.cp.setContentType("hls")
  m.app.player.contentType = "hls"
end if

settings = m.app.utils.getSettings()

if m.app.settings.shortAppName = "tubitv"
  m.app.cp.urls = {
		  getPlaylists: "http://cms.adrise.com/v2/app.php?id=" + settings.shortAppName + "&platform=roku&format=xml&content-type=" + m.app.cp.contentType + "&video-fields=title&sdk=5.0"
		  getVideo: "http://cms.adrise.com/v2/video.php?app-id=" + settings.shortAppName + "&platform=roku&content-type=" + m.app.cp.contentType + "&format=xml&id="
		  getVideos: "http://cms.adrise.com/v2/videos.php?app-id=" + settings.shortAppName + "&platform=roku&content-type=" + m.app.cp.contentType + "&format=xml&id="
		}
end if

  settings.registerWithTubi = false
  m.app.utils.getUserData = function ()
    return {}
  end function
