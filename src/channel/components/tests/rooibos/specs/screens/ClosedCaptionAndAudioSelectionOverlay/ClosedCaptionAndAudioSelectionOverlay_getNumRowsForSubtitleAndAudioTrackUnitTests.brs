'@SGNode Test_ClosedCaptionAndAudioSelectionOverlay
'@TestSuite [ClosedCaptionAndAudioSelectionOverlay] ClosedCaptionAndAudioSelectionOverlay in ClosedCaptionAndAudioSelectionOverlay.brs


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests getNumRowsForSubtitleAndAudioTrack in ClosedCaptionAndAudioSelectionOverlay.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test getNumRowsForSubtitleAndAudioTrack unit tests
Function number_getNumRowsForSubtitleAndAudioTrack_test()
  numRows = getNumRowsForSubtitleAndAudioTrack(3, 3)
  subtitle = numRows.subtitle
  audioTrack = numRows.audioTrack
  m.assertEqual(subtitle, 3)
  m.assertEqual(audioTrack, 3)

  numRows = getNumRowsForSubtitleAndAudioTrack(4, 4)
  subtitle = numRows.subtitle
  audioTrack = numRows.audioTrack
  m.assertEqual(subtitle, 3)
  m.assertEqual(audioTrack, 3)

  numRows = getNumRowsForSubtitleAndAudioTrack(5, 2)
  subtitle = numRows.subtitle
  audioTrack = numRows.audioTrack
  m.assertEqual(subtitle, 4)
  m.assertEqual(audioTrack, 2)

  numRows = getNumRowsForSubtitleAndAudioTrack(2, 7)
  subtitle = numRows.subtitle
  audioTrack = numRows.audioTrack
  m.assertEqual(subtitle, 2)
  m.assertEqual(audioTrack, 4)

  numRows = getNumRowsForSubtitleAndAudioTrack(2, 2)
  subtitle = numRows.subtitle
  audioTrack = numRows.audioTrack
  m.assertEqual(subtitle, 2)
  m.assertEqual(audioTrack, 2)

  numRows = getNumRowsForSubtitleAndAudioTrack(3, 0)
  subtitle = numRows.subtitle
  audioTrack = numRows.audioTrack
  m.assertEqual(subtitle, 3)
  m.assertEqual(audioTrack, 0)

  numRows = getNumRowsForSubtitleAndAudioTrack(0, 4)
  subtitle = numRows.subtitle
  audioTrack = numRows.audioTrack
  m.assertEqual(subtitle, 0)
  m.assertEqual(audioTrack, 4)

  numRows = getNumRowsForSubtitleAndAudioTrack(6, 0)
  subtitle = numRows.subtitle
  audioTrack = numRows.audioTrack
  m.assertEqual(subtitle, 6)
  m.assertEqual(audioTrack, 0)

  numRows = getNumRowsForSubtitleAndAudioTrack(0, 7)
  subtitle = numRows.subtitle
  audioTrack = numRows.audioTrack
  m.assertEqual(subtitle, 0)
  m.assertEqual(audioTrack, 6)
End Function
