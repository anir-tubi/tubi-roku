'@SGNode Test_AdsSSAITask
'@TestSuite [AdsSSAITask] AdsSSAITask.brs

'@BeforeEach
Function AdsSSAITaskTest_BeforeEach()
  m.mockYospaceAdId = "abcdedfg"
  m.mockPixelRecordForAd = {}
  m.mockPixelRecordForAd[m.mockYospaceAdId] = {}
  m.mockPixelRecordForAd[m.mockYospaceAdId]["0percent"] = false
  m.mockPixelRecordForAd[m.mockYospaceAdId]["25percent"] = false
  m.mockPixelRecordForAd[m.mockYospaceAdId]["50percent"] = false
  m.mockPixelRecordForAd[m.mockYospaceAdId]["75percent"] = false
  m.mockPixelRecordForAd[m.mockYospaceAdId]["100percent"] = false

  ' ad pod with 3 ads
  m.mockedAdBreak = buildMockedAdBreak()
  m.adPod = m.mockedAdBreak[0]
End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests helper functions in AdsSSAITask.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test formatPixelRecordForAd unit test
Function adsSSAITask_formatPixelRecordForAd_test()
  pixelRecord = m.mockPixelRecordForAd[m.mockYospaceAdId]
  pixelRecordForAd = formatPixelRecordForAd(m.mockYospaceAdId, pixelRecord)

  m.assertNotInvalid(pixelRecordForAd)
  m.assertNotInvalid(pixelRecordForAd[m.mockYospaceAdId])
  m.assertEqual(pixelRecordForAd[m.mockYospaceAdId]["0percent"], false)
  m.assertEqual(pixelRecordForAd[m.mockYospaceAdId]["25percent"], false)
  m.assertEqual(pixelRecordForAd[m.mockYospaceAdId]["50percent"], false)
  m.assertEqual(pixelRecordForAd[m.mockYospaceAdId]["75percent"], false)
  m.assertEqual(pixelRecordForAd[m.mockYospaceAdId]["100percent"], false)
End Function


'@Test checkPixelRecord unit test
Function adsSSAITask_checkPixelRecord_test()
  m.mockPixelRecordForAd[m.mockYospaceAdId]["50percent"] = true
  m.mockPixelRecordForAd[m.mockYospaceAdId]["100percent"] = true
  pixelRecord = m.mockPixelRecordForAd[m.mockYospaceAdId]

  check0 = checkPixelRecord(pixelRecord, 0)
  m.assertFalse(check0)
  check25 = checkPixelRecord(pixelRecord, 0.25)
  m.assertFalse(check25)
  check50 = checkPixelRecord(pixelRecord, 0.5)
  m.assertTrue(check50)
  check75 = checkPixelRecord(pixelRecord, 0.75)
  m.assertFalse(check75)
  check100 = checkPixelRecord(pixelRecord, 1.0)
  m.assertTrue(check100)
End Function


'@Test getNewPixelRecord unit test
Function adsSSAITask_getNewPixelRecord_test()
  pixelRecord = getNewPixelRecord()

  m.assertEqual(pixelRecord["0percent"], false)
  m.assertEqual(pixelRecord["25percent"], false)
  m.assertEqual(pixelRecord["50percent"], false)
  m.assertEqual(pixelRecord["75percent"], false)
  m.assertEqual(pixelRecord["100percent"], false)
End Function


'@Test markPixelsAsSent unit test
Function adsSSAITask_markPixelsAsSent_test()
  mockPixelRecord = m.mockPixelRecordForAd[m.mockYospaceAdId]
  markedPixelRecord = markPixelsAsSent(mockPixelRecord, 0.75)

  m.assertEqual(markedPixelRecord["0percent"], false)
  m.assertEqual(markedPixelRecord["25percent"], false)
  m.assertEqual(markedPixelRecord["50percent"], false)
  m.assertEqual(markedPixelRecord["75percent"], true)
  m.assertEqual(markedPixelRecord["100percent"], false)
End Function


'@Test haveStoredAd unit test
Function adsSSAITask_haveStoredAds_test()
  adsExist = haveStoredAds(m.adPod)
  m.assertTrue(adsExist)

  m.mockedAdBreak[0].ads = []
  adsExist = haveStoredAds(m.adPod)
  m.assertFalse(adsExist)

  m.mockedAdBreak = buildMockedAdBreak()
  m.mockedAdBreak[0].delete("ads")
  adsExist = haveStoredAds(m.adPod)
  m.assertFalse(adsExist)

  m.mockedAdBreak = []
  adsExist = haveStoredAds(m.adPod)
  m.assertFalse(adsExist)
End Function


'@Test isLastAdInPod unit test
Function adsSSAITask_isLastAdInPod_test()
  adPod = m.mockedAdBreak[0]

  isLast = isLastAdInPod("a12345", adPod)
  m.assertFalse = (isLast)

  isLast = isLastAdInPod("a23452", adPod)
  m.assertFalse = (isLast)

  isLast = isLastAdInPod("a89564", adPod)
  m.assertTrue = (isLast)
End Function


'@Test getAdFromYospaceAdId unit test
Function adsSSAITask_getAdFromYospaceAdId_test()
  adPod = m.mockedAdBreak[0]

  ad = getAdFromYospaceAdId("a12345", adPod)
  m.assertNotInvalid(ad)
  m.assertEqual(ad.adId, "12345")

  ad = getAdFromYospaceAdId("a23452", adPod)
  m.assertNotInvalid(ad)
  m.assertEqual(ad.adId, "23452")

  ad = getAdFromYospaceAdId("a89564", adPod)
  m.assertNotInvalid(ad)
  m.assertEqual(ad.adId, "89564")

  ad = getAdFromYospaceAdId("xxxxx", adPod)
  m.assertInvalid(ad)
End Function


Function buildMockedAdBreak()
  return [
    {
      ads: [
        {
          adId: "12345"
          yospaceId: "a12345"
          duration: 30
          tracking: []
        }
        {
          adId: "23452"
          yospaceId: "a23452"
          duration: 15
          tracking: []
        }
        {
          adId: "89564"
          yospaceId: "a89564"
          duration: 20
          tracking: []
        }
      ]
    }
  ]
End Function
