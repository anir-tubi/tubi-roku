'@TestSuite [ApolloId3s] ApolloId3s.brs

'@Setup
Function ApolloId3sSetup()
  m.segmentId3s = {
    _decodeInfo_pts: 3185.221
    TMID: "525123456"
    TSEQ: "2:3"
    TSTS: "0.066733:30.096733"
    TVER: "1"
}
  m.startId3s = {
    _decodeInfo_pts: 3185.221
    TDUR: "0.000000"
    TMID: "525123456"
    TPOS: "0"
    TVER: "1"
}
  m.midId3s = {
    _decodeInfo_pts: 3200.202
    TDUR: "2.969633"
    TMID: "525123456"
    TPOS: "50"
    TVER: "1"
}
  m.endId3s = {
    _decodeInfo_pts: 3215.251
    TDUR: "2.002000"
    TMID: "525123456"
    TPOS: "100"
    TVER: "1"
}
  m.setAllTags = Function(tags)
    for each tag in tags
      m.id3s.setTag(tag, tags[tag])
    end for
  End Function
End function


'@BeforeEach
Function ApolloId3s_beforeEach()
  m.id3s = apolloId3s()
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in ApolloId3s.js
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test setTag start id3 unit tests
Function apolloIds_setTag_start_test()
  ' add a first tag
  m.id3s.setTag("TMID", "525123456")
  m.assertNotInvalid(m.id3s.tags)
  m.assertNotInvalid(m.id3s.tags["TMID"])
  m.assertEqual(m.id3s.tags["TMID"], "525123456")

  ' overwrite an existing tag
  m.id3s.setTag("TMID", "456")
  m.assertNotInvalid(m.id3s.tags["TMID"])
  m.assertEqual(m.id3s.tags["TMID"], "456")

  ' add a second tag
  m.id3s.setTag("TPOS", "0")
  m.assertNotInvalid(m.id3s.tags)
  m.assertNotInvalid(m.id3s.tags["TPOS"])
  m.assertEqual(m.id3s.tags["TPOS"], "0")
  m.assertNotInvalid(m.id3s.tags["TMID"])

  ' test TPOS functionality
  m.id3s.setTag("TPOS", "0")
  m.assertEqual(m.id3s.type, 0)
  m.id3s.setTag("TPOS", "25")
  m.assertEqual(m.id3s.type, 25)
  m.id3s.setTag("TPOS", "50")
  m.assertEqual(m.id3s.type, 50)
  m.id3s.setTag("TPOS", "75")
  m.assertEqual(m.id3s.type, 75)
  m.id3s.setTag("TPOS", "100")
  m.assertEqual(m.id3s.type, 100)
End Function


'@Test setTag segment Id3 unit tests
Function apolloIds_setTag_segment_test()

  m.id3s.setTag("TMID", "525123456")
  m.assertNotInvalid(m.id3s.tags)
  m.assertNotInvalid(m.id3s.tags["TMID"])
  m.assertEqual(m.id3s.tags["TMID"], "525123456")

  ' test TSEQ functionality
  m.id3s.setTag("TSEQ", "2:3")
  m.assertEqual(m.id3s.segment, 2)
  m.assertEqual(m.id3s.totalSegmentAmt, 3)

  ' test TDUR functionality
  m.id3s.setTag("TDUR", "0.3")
  m.assertEqual(m.id3s.adDuration, 0.3)

End Function


'@Test setTag mid id3 unit tests
Function apolloIds_setTag_mid_test()
  m.setAllTags(m.midId3s)
  m.assertNotInvalid(m.id3s.tags)
  m.assertEqual(m.id3s.tags, m.midId3s)

  m.assertEqual(m.id3s.type, 50)
End Function


'@Test setTag end id3 unit tests
Function apolloIds_setTag_end_test()
  m.setAllTags(m.endId3s)
  m.assertNotInvalid(m.id3s.tags)
  m.assertEqual(m.id3s.tags, m.endId3s)

  m.assertEqual(m.id3s.type, 100)
End Function


'@Test getTag unit tests
Function apolloIds_getTag_test()
  m.setAllTags(m.startId3s)
  tmid = m.id3s.getTag("TMID")
  tpos = m.id3s.getTag("TPOS")
  tver = m.id3s.getTag("TVER")
  m.assertEqual(tmid, "525123456")
  m.assertEqual(tpos, "0")
  m.assertEqual(tver, "1")
End Function


'@Test getAllTags unit tests
Function apolloIds_getAllTags_test()
  m.setAllTags(m.midId3s)
  allId3s = m.id3s.getAllTags()
  m.assertEqual(m.midId3s, allId3s)
End Function


'@Test getId unit tests
Function apolloIds_getId_test()
  m.setAllTags(m.endId3s)
  apolloMediaId = m.id3s.getId()
  m.assertEqual(apolloMediaId, "525123456")
End Function


'@Test getAdPercent unit tests
Function apolloIds_getAdPercent_test()
  m.setAllTags(m.startId3s)
  id3Type = m.id3s.getAdPercent()
  m.assertEqual(id3Type, 0)

  m.setAllTags(m.midId3s)
  id3Type = m.id3s.getAdPercent()
  m.assertEqual(id3Type, 50)

  m.setAllTags(m.endId3s)
  id3Type = m.id3s.getAdPercent()
  m.assertEqual(id3Type, 100)
End Function


'@Test currentSegment unit tests
Function apolloIds_currentSegment_test()
  m.setAllTags(m.segmentId3s)
  curSegment = m.id3s.currentSegment()
  m.assertEqual(curSegment, 2)
End Function


'@Test totalSegments unit tests
Function apolloIds_totalSegments_test()
  m.setAllTags(m.segmentId3s)
  totalSegments = m.id3s.totalSegments()

  m.assertEqual(totalSegments, 3)
End Function


'@Test clearTags unit tests
Function apolloIds_clearTags_test()
  m.setAllTags(m.endId3s)
  m.id3s.clearTags()
  m.assertEqual(m.id3s.tags, {})
  m.assertEqual(m.id3s.segment, 0)
  m.assertEqual(m.id3s.totalSegmentAmt, 0)
  m.assertEqual(m.id3s.type, -1)
  m.assertEqual(m.id3s.adDuration, 0)
End Function