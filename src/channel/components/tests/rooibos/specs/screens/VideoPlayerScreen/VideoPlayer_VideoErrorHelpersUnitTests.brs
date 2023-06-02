'@SGNode Test_VideoPlayer
'@TestSuite [VideoErrorHelpers] VideoErrorHelpers in VideoPlayer.brs

'@Setup
Function VideoErrorsSetup()
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
  mockedInfo.errorStr3 = "An unexpected problem (but not server timeout or HTTP error) has been detected."
  mockedInfo.alteredErrorStr3 = "Server did not respond with hls segment. Potential 504 or 404. Following segment likely has issue."

  'mock a video node's error code and message for error -5
  mockedInfo.errorCode5 = -5
  mockedInfo.errorStr5 = "malformed data"

  'mock a content node
  mockedInfo.content = CreateObject("roSGNode", "ContentNode")
  mockedInfo.content.id = "438040"
  mockedInfo.content.url = "http://titan.adrise.tv/magnolia/5141ca3b-b591-4899-9946-b68e5df8cf56/,lw6t7idowv,2iap5chhoy,vecpnawzs7,i2npap9ern,.mp4.m3u8?wOqZZNUjw9i3-SAYQGK1OxMZgcJfq85yOKr96I7KEH0z7cjBYck8oAMvzpAnnMIPghxSO8nV4E-mli3baWUbvNEKP_8"

  'mock a buffer totalMilliseconds() time
  mockedInfo.bufferMs = 2957

  m.mockedInfo = mockedInfo
End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests video error helpers in VideoPlayer.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test getPlaybackErrorInfo unit test
Function videoHelpers_getPlaybackErrorInfo_test()
  mi = m.mockedInfo
  correctErrorInfo = {
    video_id: mi.content.id
    video_url: removeExcessUrl(mi.streamInfo.streamUrl)
    segment_url: removeExcessUrl(mi.streamingSegment.segUrl)
    segment_start_time: mi.streamingSegment.segStartTime
    segment_sequence: mi.streamingSegment.segSequence
    segment_bitrate: mi.streamingSegment.segBitrateBps
    error_code: mi.errorCode5
    error_message: mi.errorStr5
  }
  errorInfo = getPlaybackErrorInfo(437, mi.downloadedSegment, mi.streamingSegment, mi.streamInfo, mi.errorCode5, mi.errorStr5, mi.content)
  m.AssertEqual(errorInfo, correctErrorInfo)
End Function


'@Test getPlaybackErrorInfo Position 0 unit test
Function videoHelpers_getPlaybackErrorInfo_Position0()
  mi = m.mockedInfo
  correctErrorInfo = {
    video_id: mi.content.id
    video_url: removeExcessUrl(mi.content.url)
    error_code: mi.errorCode5
    error_message: mi.errorStr5
  }
  errorInfo = getPlaybackErrorInfo(0, mi.downloadedSegment, mi.streamingSegment, mi.streamInfo, mi.errorCode5, mi.errorStr5, mi.content)
  m.AssertEqual(errorInfo, correctErrorInfo)
End Function


'@Test getPlaybackErrorInfo Error3 unit test
Function videoHelpers_getPlaybackErrorInfo_Error3()
  mi = m.mockedInfo
  correctErrorInfo = {
    video_id: mi.content.id
    video_url: removeExcessUrl(mi.streamInfo.streamUrl)
    segment_url: removeExcessUrl(mi.downloadedSegment.segUrl)
    segment_sequence: mi.downloadedSegment.segSequence
    segment_bitrate: mi.downloadedSegment.bitrateBps
    error_code: mi.errorCode3
    error_message: mi.alteredErrorStr3
  }
  errorInfo = getPlaybackErrorInfo(437, mi.downloadedSegment, mi.streamingSegment, mi.streamInfo, mi.errorCode3, mi.errorStr3, mi.content)
  m.AssertEqual(errorInfo, correctErrorInfo)
End Function


'@Test getPlaybackErrorInfo Error3 Position0 unit test
Function videoHelpers_getPlaybackErrorInfo_Error3_Position0()
  mi = m.mockedInfo
  correctErrorInfo = {
    video_id: mi.content.id
    video_url: removeExcessUrl(mi.content.url)
    error_code: mi.errorCode3
    error_message: mi.alteredErrorStr3
  }
  errorInfo = getPlaybackErrorInfo(0, mi.downloadedSegment, mi.streamingSegment, mi.streamInfo, mi.errorCode3, mi.errorStr3, mi.content)
  m.AssertEqual(errorInfo, correctErrorInfo)
End Function


'@Test removeExcessUrl unit test
Function videoHelpers_removeExcessUrl()
  url = "http://c13.adrise.tv/v2/sources/content-owners/mgm/389496/v20179270205-,577,877,1189,1581,2176,k.mp4.m3u8?WkuQ8Q_G9-5DOf4_xiCDbIE4b7yEuIg5P1ieENFOvRmVjNGf07mQjEhIYQaFHSURKMZaMTmIPzLyoVywCEQFjn7sc4s"
  shortUrl = "http://c13.adrise.tv/v2/sources/content-owners/mgm/389496/v20179270205-,577,877,1189,1581,2176,k.mp4.m3u8"
  m.AssertEqual(removeExcessUrl(url), shortUrl)
End Function
