' A helper library to work with YoSpace id3 tags that are sent during ad playback
' of server side ad inserted (SSAI) ads.

' YoSpace id3s have 5 keys, per YoSpace, and they are as follows:
' YMID - The Yospace Media ID (each transcoded ad asset has a unique ID) - eg "525123456".
' YTYP - The "type" of ID3 packet - Values will be a single-character string "S", "M" or "E"
'        (for "Start", "Middle" and "End" respectively).
' YSEQ - The sequence number of the segment within a single ad - This will be a string in the form
'        "X:Y" where X is the segment number, and Y the total number of segments which comprise the ad
'        (eg "1:3" indicates segment 1 of 3).
' YDUR - The approximate offset of the tag within its segment (in seconds) - eg "04.5" indicates a tag
'        4.5 seconds from the start of the segment.
' YCSP - This frame is reserved for "Customer Specific Parameters", but when not in use, will contain a
'        copy of the Yospace Media ID. It's not required by our SDK.
Function yoSpaceId3s()
  return {
    setTag: yoSpaceId3s_setTag
    getTag: yoSpaceId3s_getTag
    getAllTags: yoSpaceId3s_getAllTags
    getId: yoSpaceId3s_getId
    getType: yoSpaceId3s_getType
    getPosition: yoSpaceId3s_getPosition
    currentSegment: yoSpaceId3s_currentSegment
    totalSegments: yoSpaceId3s_totalSegments
    clearTags: yoSpaceId3s_clearTags

    ' access these values via the functions above rather than directly
    tags: {}
    id: ""
    segment: 0
    totalSegmentAmt: 0
    type: ""
    position: 0
  }
End Function


Function yoSpaceId3s_setTag(tag, value)
  m.tags[tag] = value

  if tag = "YTYP"
    if value = "S" then m.type = "start"
    if value = "M" then m.type = "middle"
    if value = "E" then m.type = "end"
  else if tag = "YSEQ" AND (type(value) = "String" or type(value) = "roString")
    segs = value.split(":")
    m.segment = segs[0].toInt()
    m.totalSegmentAmt = segs[1].toInt()
  else if tag = "YDUR"
    m.position = value.toFloat()
  else if tag = "YMID"
    m.id = value
  end if
End Function


' @tag: string, one of the tags as defined in the comments at the top of this file (ex. "YMID")
Function yoSpaceId3s_getTag(tag)
  return m.tags[tag]
End Function


Function yoSpaceId3s_getAllTags()
  return m.tags
End Function


Function yoSpaceId3s_getId()
  return m.id
End Function


Function yoSpaceId3s_getType()
  return m.type
End Function


Function yoSpaceId3s_getPosition()
  return m.position
End Function


Function yoSpaceId3s_currentSegment()
  return m.segment
End Function


Function yoSpaceId3s_totalSegments()
  return m.totalSegmentAmt
End Function


Function yoSpaceId3s_clearTags()
  m.tags = {}
  m.segment = 0
  m.totalSegmentAmt = 0
  m.type = ""
  m.position = 0
End Function
