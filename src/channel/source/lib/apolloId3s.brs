' A helper library to work with Apollo id3 tags that are sent during ad playback
' of server side ad inserted (SSAI) ads.

' Apollo id3s have 5 keys, per Apollo, and they are as follows:
' TMID - an ID of the Ad video(actually it’s the MD5 value of the video).
' TPOS - the percentage of the video has played, values are 0, 25, 50, 75, 100, which respectively indicate 0%, 25%, 50%, 75%, 100%.
' TSEQ - the sequence number of the segment. This will be a string in the form X:Y where X is the segment number, and Y the total number of segments (e.g. 1:3 indicates segment 1 of 3)
' TDUR - The approximate offset of the tag within its segment (in seconds) - e.g. 3.603600 indicates a tag with an offset of 3.603600 seconds from the start of the segment.
' TSTS - the start time of segment with respect to total duration of the video in seconds. This is presented in a string form X:Y where X is the start time of the TS segment, and Y the total duration of the video (e.g. 20.086733:30.030000).
' TVER - the version of the current timed metadata structure.
' TTYP - Indicates whether ad or filler is playing. f= filler, a = ad. If TTYP tag itself is missing that would mean, its an ad, so initializing it to "a"
Function apolloId3s()
  return {
    setTag: apolloId3s_setTag
    getTag: apolloId3s_getTag
    getAllTags: apolloId3s_getAllTags
    getId: apolloId3s_getId
    getAdPercent: apolloId3s_getAdPercent
    getAdDuration: apolloId3s_getAdDuration
    currentSegment: apolloId3s_currentSegment
    totalSegments: apolloId3s_totalSegments
    clearTags: apolloId3s_clearTags
    getTotalAdDuration: apolloId3s_getTotalAdDuration
    getSegStartTs: apolloId3s_getSegStartTs
    getAdType: apolloId3s_getAdType

    ' access these values via the functions above rather than directly
    tags: {}
    id: ""
    timedMetaVersion: ""
    segment: 0
    totalSegmentAmt: 0
    type: -1
    adDuration: 0
    segStartTs: 0
    adTotalDur: 0
    adType: "a"
  }
End Function


Function apolloId3s_setTag(tag, value)
  m.tags[tag] = value

  if tag = "TPOS" OR tag = "tpos"
    m.type = value.toInt()
  else if (tag = "TSEQ" OR tag = "tseq") AND isString(value) = true
    segs = value.split(":")
    if segs.count() > 1
      m.segment = segs[0].toInt()
      m.totalSegmentAmt = segs[1].toInt()
    end if
  else if tag = "TDUR" OR tag = "tdur"
    m.adDuration = value.toFloat()
  else if tag = "TMID" OR tag = "tmid"
    m.id = value
  else if tag = "TVER" OR tag = "tver"
    m.timedMetaVersion = value
  else if (tag = "TSTS" OR tag = "tsts") AND isString(value) = true
    ts = value.split(":")

    if ts.count() > 1
      m.segStartTs = ts[0].toInt()
      m.adTotalDur = ts[1].toInt()
    end if
  else if tag = "TTYP" OR tag = "ttyp"
    m.adType = value
  end if
End Function


' @tag: string, one of the tags as defined in the comments at the top of this file (ex. "YMID")
Function apolloId3s_getTag(tag)
  return m.tags[tag]
End Function


Function apolloId3s_getAllTags()
  return m.tags
End Function


Function apolloId3s_getId()
  return m.id
End Function


Function apolloId3s_getAdPercent()
  return m.type
End Function


Function apolloId3s_getAdDuration()
  return m.adDuration
End Function


Function apolloId3s_currentSegment()
  return m.segment
End Function


Function apolloId3s_totalSegments()
  return m.totalSegmentAmt
End Function


Function apolloId3s_getTotalAdDuration()
  return m.adTotalDur
End Function


Function apolloId3s_getSegStartTs()
  return m.segStartTs
End Function


Function apolloId3s_getAdType()
  return m.adType
End Function


Function apolloId3s_clearTags()
  m.tags = {}
  m.segment = 0
  m.totalSegmentAmt = 0
  m.type = -1
  m.adDuration = 0
  m.segStartTs = 0
  m.adTotalDur = 0
  m.adType = "a"
End Function
