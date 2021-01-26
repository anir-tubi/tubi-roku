'@TestSuite [YoSpaceId3s] YoSpaceId3s.brs 

'@Setup
Function YoSpaceId3sSetup()
  m.startId3s = {
    "YMID": "525123456"
    "YTYP": "S"
    "YSEQ": "2:3"
    "YDUR": "0.3"
    "YCSP": "525123456"
  }
  m.midId3s = {
    "YMID": "525123456"
    "YTYP": "M"
    "YSEQ": "2:3"
    "YDUR": "3.3"
    "YCSP": "525123456"
  }
  m.endId3s = {
    "YMID": "525123456"
    "YTYP": "E"
    "YSEQ": "2:3"
    "YDUR": "6.5"
    "YCSP": "525123456"
  }
  m.setAllTags = Function(tags)
    for each tag in tags
      m.id3s.setTag(tag, tags[tag])
    end for
  End Function
End function


'@BeforeEach
Function YoSpaceId3s_beforeEach()
  m.id3s = yoSpaceId3s()
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in YoSpaceId3s.js
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test setTag start id3 unit tests
Function yoSpaceIds_setTag_start_test()
  ' add a first tag
  m.id3s.setTag("YMID", "525123456")
  m.assertNotInvalid(m.id3s.tags)
  m.assertNotInvalid(m.id3s.tags["YMID"])
  m.assertEqual(m.id3s.tags["YMID"], "525123456")

  ' overwrite an existing tag
  m.id3s.setTag("YMID", "456")
  m.assertNotInvalid(m.id3s.tags["YMID"])
  m.assertEqual(m.id3s.tags["YMID"], "456")

  ' add a second tag
  m.id3s.setTag("YTYP", "S")
  m.assertNotInvalid(m.id3s.tags)
  m.assertNotInvalid(m.id3s.tags["YTYP"])
  m.assertEqual(m.id3s.tags["YTYP"], "S")
  m.assertNotInvalid(m.id3s.tags["YMID"])

  ' test YTYP functionality
  m.id3s.setTag("YTYP", "S")
  m.assertEqual(m.id3s.type, "start")
  m.id3s.setTag("YTYP", "M")
  m.assertEqual(m.id3s.type, "middle")
  m.id3s.setTag("YTYP", "E")
  m.assertEqual(m.id3s.type, "end")

  ' test YSEQ functionality
  m.id3s.setTag("YSEQ", "2:3")
  m.assertEqual(m.id3s.segment, 2)
  m.assertEqual(m.id3s.totalSegmentAmt, 3)

  ' test YDUR functionality
  m.id3s.setTag("YDUR", "0.3")
  m.assertEqual(m.id3s.position, 0.3)
End Function


'@Test setTag mid id3 unit tests
Function yoSpaceIds_setTag_mid_test()
  m.setAllTags(m.midId3s)
  m.assertNotInvalid(m.id3s.tags)
  m.assertEqual(m.id3s.tags, m.midId3s)

  m.assertEqual(m.id3s.segment, 2)
  m.assertEqual(m.id3s.totalSegmentAmt, 3)

  m.assertEqual(m.id3s.type, "middle")
  m.assertEqual(m.id3s.position, 3.3)
End Function


'@Test setTag end id3 unit tests
Function yoSpaceIds_setTag_end_test()
  m.setAllTags(m.endId3s)
  m.assertNotInvalid(m.id3s.tags)
  m.assertEqual(m.id3s.tags, m.endId3s)

  m.assertEqual(m.id3s.segment, 2)
  m.assertEqual(m.id3s.totalSegmentAmt, 3)

  m.assertEqual(m.id3s.type, "end")
  m.assertEqual(m.id3s.position, 6.5)
End Function


'@Test getTag unit tests
Function yoSpaceIds_getTag_test()
  m.setAllTags(m.startId3s)
  ymid = m.id3s.getTag("YMID")
  ytyp = m.id3s.getTag("YTYP")
  yseq = m.id3s.getTag("YSEQ")
  ydur = m.id3s.getTag("YDUR")
  ycsp = m.id3s.getTag("YCSP")
  m.assertEqual(ymid, "525123456")
  m.assertEqual(ytyp, "S")
  m.assertEqual(yseq, "2:3")
  m.assertEqual(ydur, "0.3")
  m.assertEqual(ycsp, "525123456")
End Function


'@Test getAllTags unit tests
Function yoSpaceIds_getAllTags_test()
  m.setAllTags(m.midId3s)
  allId3s = m.id3s.getAllTags()
  m.assertEqual(m.midId3s, allId3s)
End Function


'@Test getId unit tests
Function yoSpaceIds_getId_test()
  m.setAllTags(m.endId3s)
  yoSpaceMediaId = m.id3s.getId()
  m.assertEqual(yoSpaceMediaId, "525123456")
End Function


'@Test getType unit tests
Function yoSpaceIds_getType_test()
  m.setAllTags(m.startId3s)
  id3Type = m.id3s.getType()
  m.assertEqual(id3Type, "start")

  m.setAllTags(m.midId3s)
  id3Type = m.id3s.getType()
  m.assertEqual(id3Type, "middle")

  m.setAllTags(m.endId3s)
  id3Type = m.id3s.getType()
  m.assertEqual(id3Type, "end")
End Function


'@Test getPosition unit tests
Function yoSpaceIds_getPosition_test()
  m.setAllTags(m.endId3s)
  position = m.id3s.getPosition()
  m.assertEqual(position, 6.5)
End Function


'@Test currentSegment unit tests
Function yoSpaceIds_currentSegment_test()
  m.setAllTags(m.startId3s)
  curSegment = m.id3s.currentSegment()
  m.assertEqual(curSegment, 2)
End Function


'@Test totalSegments unit tests
Function yoSpaceIds_totalSegments_test()
  m.setAllTags(m.startId3s)
  totalSegments = m.id3s.totalSegments()
  m.assertEqual(totalSegments, 3)
End Function


'@Test clearTags unit tests
Function yoSpaceIds_clearTags_test()
  m.setAllTags(m.endId3s)
  m.id3s.clearTags()
  m.assertEqual(m.id3s.tags, {})
  m.assertEqual(m.id3s.segment, 0)
  m.assertEqual(m.id3s.totalSegmentAmt, 0)
  m.assertEqual(m.id3s.type, "")
  m.assertEqual(m.id3s.position, 0)
End Function