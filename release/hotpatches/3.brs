print "hot patch 3: (empty)"

g = GetGlobalAA()

deviceInfo = CreateObject( "roDeviceInfo")

version = deviceInfo.GetVersion()
major = Mid(version, 3, 1)
if major = "3"
  g.app.cp.setContentType("mp4")
  g.app.player.contentType = "mp4"
else
  g.app.cp.setContentType("hls")
  g.app.player.contentType = "hls"
end if
