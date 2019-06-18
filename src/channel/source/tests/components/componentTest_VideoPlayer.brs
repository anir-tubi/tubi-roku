' Useful for comparing behavior of ButtonGroup with
' the Menu component
Function componentTest_VideoPlayer(screen, runComponentTest)
  content = {
    "id": "301333"
    "description": "Set during the 1937 Japanese invasion of Nanking, an American taking refuge in a church attempts to save a group of women from marauding soldiers."
    "isTrailer": false
    "language": "English"
    "length": 8538
    "nowPos": 0
    "offset": 0
    "rating": "R"
    "releasedate": "2012"
    "streamformat": "hls"
    "title": "The Flowers of War"
    "type": "video"
' URL will be populated by the content refresh task
'    URL: "http://c13.adrise.tv/v2/sources/content-owners/lionsgate/301333/v201701280814-,494,809,1226,1469,1766,k.mp4.m3u8?MRmYZvfq9AVULAdM_ShbGWR9-ii0D2RxkjwXnfUWPVbbRrrF-R5i3Iip-1A1TXZLTLnjpddc9h4kRgkEJJn6Yk5eeLE"
  }
  playlist = CreateObject("roSGNode", "TubiContentNode")
  child = playlist.createChild("TubiContentNode")
  child.setFields(content)
  data = [
    {
      "analyticsMode":  "normal"
      "enableAds":      false
      "deeplinkSource": invalid
      "loopPlaylist": false
      "playlist": playlist
    }
    {
      "seekPlaylist": [0, 0]
    }
  ]
  events = [
    "historyPosition"
    "creditsPosition"
    "state"
    "backButtonPressed"
  ]
  
  globalNode = screen.getGlobalNode()
  globalNode.addField("constants", "assocarray", false)
  globalNode.constants = getConstants()

  globalNode.addField("trackingLoggingTask", "node", false)
  trackingLoggingTask = CreateObject("roSGNode", "Node")
  trackingLoggingTask.addField("trackEvent", "assocarray", false)
  globalNode.trackingLoggingTask = trackingLoggingTask

  return runComponentTest("VideoPlayer", data, events)
End Function