'###
' Testing a set of helper functions that work with formatting video playback error messages
'###

'The initializing test suite Function name must begin with the string "TestSuite_"
Function TestSuite_VideoPlayer_VideoErrorHelpers() as Object
  ' Inherit your test suite from BaseTestSuite
  this = BaseTestSuite()
  
  ' Test suite name for log statistics
  this.Name = "TestSuite_VideoPlayer_VideoErrorHelpers"
  
  ' Add tests to suite's tests collection
  ' Test cases should return the assert value
  this.addTest("TestCase_getPlaybackErrorInfo", TestCase_getPlaybackErrorInfo)
  this.addTest("TestCase_getPlaybackErrorInfo_Position0", TestCase_getPlaybackErrorInfo_Position0)
  this.addTest("TestCase_getPlaybackErrorInfo_Error3", TestCase_getPlaybackErrorInfo_Error3)
  this.addTest("TestCase_getPlaybackErrorInfo_Error3_Position0", TestCase_getPlaybackErrorInfo_Error3_Position0)
  
  this.addTest("TestCase_removeExcessUrl", TestCase_removeExcessUrl)
  
  return this
End Function


' Setup doesn't work as explained in the docs (as of 5/28/18) (for SG tests at least).
' The context is not the same as when the test cases run.
' So, using m. to set up values is not possible.
'
' Also, set up functions not instantiated in the inital test suite set up can not be named
' "TestSuite_xxxx" unless they return an empty string.
Function VideoErrorHelpers_SetUp()
  mockedInfo = {}
  'mock a video node's stream info
  mockedInfo.streamInfo = {
    isResume: true
    isUnderrun: false
    measuredBitrate: 17239040
    streamBitrate: 128000
    streamUrl: "http://titan.adrise.tv/magnolia/5141ca3b-b591-4899-9946-b68e5df8cf56/,lw6t7idowv,2iap5chhoy,vecpnawzs7,i2npap9ern,.mp4.m3u8?wOqZZNUjw9i3-SAYQGK1OxMZgcJfq85yOKr96I7KEH0z7cjBYck8oAMvzpAnnMIPghxSO8nV4E-mli3baWUbvNEKP_8"
  }

  'mock a video node's downloaded segment
  mockedInfo.downloadedSegment = {
    bitrateBps: 2564398
    bufferLevel: 0
    bufferSize: 0
    downloadDuration: 1361
    ipAddress: ""
    segSequence: 8
    segSize: 3568052
    segStreamBandwidth: 2564
    segType: 0
    segUrl: "http://titan.adrise.tv/magnolia/5141ca3b-b591-4899-9946-b68e5df8cf56/i2npap9ern.mp4+70028.ts?wOqZZNUjw9i3-SAYQGK1OxMZgcJfq85yOKr96I7KEH0z7cjBYck8oAMvzpAnnMIPghxSO8nV4E-mli3baWUbvNEKP_8"
    status: 0
  }

  'mock a video node's streaming segment
  mockedInfo.streamingSegment = {
    segBitrateBps: 1962000
    segSequence: 2
    segStartTime: 20.011
    segUrl: "http://titan.adrise.tv/magnolia/5141ca3b-b591-4899-9946-b68e5df8cf56/vecpnawzs7.mp4+10010.ts?wOqZZNUjw9i3-SAYQGK1OxMZgcJfq85yOKr96I7KEH0z7cjBYck8oAMvzpAnnMIPghxSO8nV4E-mli3baWUbvNEKP_8"
  }

  'mock a video node's error code and message for error -3
  mockedInfo.errorCode3 = -3
  mockedInfo.errorMsg3 = "An unexpected problem (but not server timeout or HTTP error) has been detected."
  mockedInfo.alteredErrorMsg3 = "Server did not respond with hls segment. Potential 504 or 404. Following segment likely has issue."

  'mock a video node's error code and message for error -5
  mockedInfo.errorCode5 = -5
  mockedInfo.errorMsg5 = "malformed data"

  'mock a content node
  mockedInfo.content = CreateObject("roSGNode", "ContentNode")
  mockedInfo.content.id = "438040"
  mockedInfo.content.url = "http://titan.adrise.tv/magnolia/5141ca3b-b591-4899-9946-b68e5df8cf56/,lw6t7idowv,2iap5chhoy,vecpnawzs7,i2npap9ern,.mp4.m3u8?wOqZZNUjw9i3-SAYQGK1OxMZgcJfq85yOKr96I7KEH0z7cjBYck8oAMvzpAnnMIPghxSO8nV4E-mli3baWUbvNEKP_8"

  'mock a buffer totalMilliseconds() time
  mockedInfo.bufferMs = 2957

  return mockedInfo
End Function


Function TestCase_getPlaybackErrorInfo()
  mi = VideoErrorHelpers_SetUp()
  correctErrorInfo = {
    video_id: mi.content.id
    video_url: removeExcessUrl(mi.streamInfo.streamUrl)
    segment_url: removeExcessUrl(mi.streamingSegment.segUrl)
    segment_start_time: mi.streamingSegment.segStartTime
    segment_sequence: mi.streamingSegment.segSequence
    segment_bitrate: mi.streamingSegment.segBitrateBps
    error_code: mi.errorCode5
    error_message: mi.errorMsg5
  }
  errorInfo = getPlaybackErrorInfo(437, mi.downloadedSegment, mi.streamingSegment, mi.streamInfo, mi.errorCode5, mi.errorMsg5, mi.content)
  return m.assertEqual(errorInfo, correctErrorInfo)
End Function


Function TestCase_getPlaybackErrorInfo_Position0()
  mi = VideoErrorHelpers_SetUp()
  correctErrorInfo = {
    video_id: mi.content.id
    video_url: removeExcessUrl(mi.content.url)
    error_code: mi.errorCode5
    error_message: mi.errorMsg5
  }
  errorInfo = getPlaybackErrorInfo(0, mi.downloadedSegment, mi.streamingSegment, mi.streamInfo, mi.errorCode5, mi.errorMsg5, mi.content)
  return m.assertEqual(errorInfo, correctErrorInfo)
End Function


Function TestCase_getPlaybackErrorInfo_Error3()
  mi = VideoErrorHelpers_SetUp()
  correctErrorInfo = {
    video_id: mi.content.id
    video_url: removeExcessUrl(mi.streamInfo.streamUrl)
    segment_url: removeExcessUrl(mi.downloadedSegment.segUrl)
    segment_sequence: mi.downloadedSegment.segSequence
    segment_bitrate: mi.downloadedSegment.bitrateBps
    error_code: mi.errorCode3
    error_message: mi.alteredErrorMsg3
  }
  errorInfo = getPlaybackErrorInfo(437, mi.downloadedSegment, mi.streamingSegment, mi.streamInfo, mi.errorCode3, mi.errorMsg3, mi.content)
  return m.assertEqual(errorInfo, correctErrorInfo)
End Function


Function TestCase_getPlaybackErrorInfo_Error3_Position0()
  mi = VideoErrorHelpers_SetUp()
  correctErrorInfo = {
    video_id: mi.content.id
    video_url: removeExcessUrl(mi.content.url)
    error_code: mi.errorCode3
    error_message: mi.alteredErrorMsg3
  }
  errorInfo = getPlaybackErrorInfo(0, mi.downloadedSegment, mi.streamingSegment, mi.streamInfo, mi.errorCode3, mi.errorMsg3, mi.content)
  return m.assertEqual(errorInfo, correctErrorInfo)
End Function


Function TestCase_removeExcessUrl()
  url = "http://c13.adrise.tv/v2/sources/content-owners/mgm/389496/v20179270205-,577,877,1189,1581,2176,k.mp4.m3u8?WkuQ8Q_G9-5DOf4_xiCDbIE4b7yEuIg5P1ieENFOvRmVjNGf07mQjEhIYQaFHSURKMZaMTmIPzLyoVywCEQFjn7sc4s"
  shortUrl = "http://c13.adrise.tv/v2/sources/content-owners/mgm/389496/v20179270205-,577,877,1189,1581,2176,k.mp4.m3u8"
  return m.assertEqual(removeExcessUrl(url), shortUrl)
End Function