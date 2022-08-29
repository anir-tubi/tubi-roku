'@TestSuite [TubiMetadataTranslate] TubiMetadataTranslate.brs

'@Setup
Function TubiMetadataTranslateSetup()
  m.constants = getConstants()
  experiments = TubiExperiments(m.constants)
  m.translate = TubiMetadataTranslate(m.constants, experiments)
End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiMetadataTranslate.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test translateRecursive testTranslateTypes unit tests
Function tubiMetadataTranslate_translateRecursive_testTranslateTypes_test()
  serverContentTypes = {
    "c": m.constants.ui.contentTypes.category
    "clip": m.constants.ui.contentTypes.video
    "v": m.constants.ui.contentTypes.video
    "s": m.constants.ui.contentTypes.series
    "a": m.constants.ui.contentTypes.season
    "channel": m.constants.ui.contentTypes.channel
  }

  source = {
    id: "12345"
    type: ""
  }

  for each contentType in serverContentTypes
    dest = CreateObject("roSGNode", "TubiContentNode")
    source.type = contentType
    m.translate.translateRecursive(source, dest)
    if contentType = "s" or contentType = "a"
      m.assertEqual("0" + source.id, dest.id)
    else
      m.assertEqual(source.id, dest.id)
    end if
    m.assertEqual(dest.type, serverContentTypes[contentType])
  end for
  ' check invalid types too
  source.type = ""
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  m.assertEqual(dest.type, "")
End Function


'@Test translateRecursive testParentTypes unit tests
Function tubiMetadataTranslate_translateRecursive_testParentTypes_test()
  parentContentTypes = [
    ' valid parent types
    m.constants.ui.contentTypes.series
    m.constants.ui.contentTypes.season
    ' missing or unrecognized parent types
    invalid
    ""
    "SomeInvalidType"
  ]

  source = {
    id: "12345"
    type: "v"
  }

  for each contentType in parentContentTypes
    parent = CreateObject("roSGNode", "TubiContentNode")
    parent.id = "parent"
    parent.type = contentType
    child = parent.createChild("TubiContentNode")
    m.translate.translateRecursive(source, child)
    if contentType = m.constants.ui.contentTypes.series or contentType = m.constants.ui.contentTypes.season
      m.assertEqual(child.parentId, parent.id)
    else
      m.assertEqual(child.parentId, "")
    end if
  end for
End Function


'@Test translateRecursive testCreditsCuepoints unit tests
Function tubiMetadataTranslate_translateRecursive_testCreditsCuepoints_test()
  ' normal cuepoint
  source = {
    id: "12345"
    type: "v"
    duration: 600
    credit_cuepoints: {
      prologue: 0
      postlude: 550
    }
  }

  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  m.assertTrue(dest.length = 600)
  m.assertTrue(dest.creditsCuePoints.postlude = 550)

  ' default cuepoint
  source = {
    id: "12345"
    type: "v"
    duration: 600
    credit_cuepoints: {
      prologue: 0
      postlude: 0
    }
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  m.assertTrue(dest.length = 600)
  m.assertTrue(dest.creditsCuePoints.postlude = 595) 'defined by constants.player.creditsDuration

  ' missing cuepoints
  source = {
    id: "12345"
    type: "v"
    duration: 600
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  m.assertTrue(dest.length = 600)
  m.assertTrue(dest.creditsCuePoints.postlude = 595) 'defined by constants.player.creditsDuration

  ' cuepoint too close to the end
  source = {
    id: "12345"
    type: "v"
    duration: 600
    credit_cuepoints: {
      prologue: 0
      postlude: 598
    }
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  m.assertTrue(dest.length = 600)
  m.assertTrue(dest.creditsCuePoints.postlude = 595)

  ' no cuepoint or length given
  source = {
    id: "12345"
    type: "v"
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  m.assertTrue(dest.length = 0)
  m.assertTrue(dest.creditsCuePoints.postlude = 0)

  ' title isn't long enough for default cuepoint placement (no cuepoints)
  source = {
    id: "12345"
    type: "v"
    duration: 3
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  m.assertTrue(dest.length = 3)
  m.assertTrue(dest.creditsCuePoints.postlude = 0)
End Function


'@Test translateRecursive channel unit tests
Function tubiMetadataTranslate_translateRecursive_channel_test()
  source = {
    id: "12345"
    type: "v"
    channel_id: "cbs"
    channel_logo: "http://image-server.staging-public.tubi.io/Hg40oOjtkAeV9bFYIFsoEa1qTI8=/180x60/img.adrise.tv/48152e63-af98-477d-a3c2-da391f45facc.png"
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  m.assertNotInvalid(dest.inlineLogoUri)
  m.assertTrue(dest.channelId = "cbs")
End Function


'@Test translateRecursive series unit tests
Function tubiMetadataTranslate_translateRecursive_series_test()
  seriesJson = ReadAsciiFile("pkg:/source/tests/rooibos/units/series.json")
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(ParseJson(seriesJson), dest)
  m.assertNotInvalid(dest)
  m.assertTrue(dest.getChildCount() = 2)
  season = dest.getChild(0)
  m.assertTrue(season.getChildCount() = 52)
End Function


'@Test translateRecursive videoResources unit tests
Function tubiMetadataTranslate_translateRecursive_videoResources_test()
  content = ReadAsciiFile("pkg:/source/tests/rooibos/units/video_resources.json")
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(ParseJson(content), dest)
  ' TODO: test the whole functionality of translate.translateRecursive()
End Function


'@Test translateContainer category unit tests
Function tubiMetadataTranslate_translateContainer_category_test()
  categoryJson = ReadAsciiFile("pkg:/source/tests/rooibos/units/category.json")
  fetchTime = CreateObject("roDateTime").AsSeconds()
  translated = m.translate.translateContainer(ParseJson(categoryJson), categoryJson)
  m.assertNotInvalid(translated)
  m.assertEqual(translated.id, "featured")
  m.assertTrue(translated.totalCount = 8)
  m.assertTrue(translated.getChildCount() = 8)
End Function


'@Test translateContainer channel unit tests
Function tubiMetadataTranslate_translateContainer_channel_test()
  channelJson = ReadAsciiFile("pkg:/source/tests/rooibos/units/channel.json")
  fetchTime = CreateObject("roDateTime").AsSeconds()
  translated = m.translate.translateContainer(ParseJson(channelJson), channelJson)
  m.assertNotInvalid(translated)
  m.assertEqual(translated.id, "cbs")
  m.assertTrue(translated.totalCount = 96)
  m.assertTrue(translated.getChildCount() = 96)
  m.assertEqual(translated.getChild(0).id, "cbs")
  m.assertNotInvalid(translated.json)
  ' make sure the embedded JSON is also correct
  fullChannelJson = ParseJson(translated.json)
  m.assertNotInvalid(type(fullChannelJson) = "roAssociativeArray")
  m.assertNotInvalid(fullChannelJson["cbs"])
  m.assertTrue(fullChannelJson.count() = 96)
End Function


'@Test translateHomescreen unit tests
Function tubiMetadataTranslate_translateHomescreen_test()
  homeJson = ReadAsciiFile("pkg:/source/tests/rooibos/units/homescreen.json")
  fetchTime = CreateObject("roDateTime").AsSeconds()
  translated = m.translate.translateHomescreen(ParseJson(homeJson))
  m.assertNotInvalid(translated)
  m.assertEqual(translated.getChildCount(), 10)
  m.assertEqual(translated.getChild(0).id, "featured")
  m.assertEqual(translated.getChild(0).getChildCount(), 8)
End Function


'@Test translate unit tests
Function tubiMetadataTranslate_translate_test()
  matches = ReadAsciiFile("pkg:/source/tests/rooibos/units/search.json")
  fetchTime = CreateObject("roDateTime").AsSeconds()
  translated = m.translate.translate(ParseJson(matches))
  m.assertNotInvalid(translated)
End Function


'@Test translateLinearChannelGuide unit tests
Function tubiMetadataTranslate_translateLinearChannelGuide_test()
  linearHomescreenJson = ReadAsciiFile("pkg:/source/tests/rooibos/units/linearHomescreen.json")
  parsedLinearHomescreen = ParseJson(linearHomescreenJson)
  translatedChannelGuide = m.translate.translateLinearChannelGuide(parsedLinearHomescreen)

  ' testing the mocked json first, as a foundation for the functional tests
  m.assertNotInvalid(parsedLinearHomescreen)
  m.assertNotInvalid(parsedLinearHomescreen.containers)
  m.assertNotInvalid(parsedLinearHomescreen.contents)
  m.assertTrue(parsedLinearHomescreen.containers.count() > 1)
  m.assertTrue(parsedLinearHomescreen.contents.count() > 1)

  ' functional tests
  m.assertNotInvalid(translatedChannelGuide)
  m.assertTrue(type(translatedChannelGuide) = "roSGNode")

  concatenatedContainerContentCount = 0
  for each container in parsedLinearHomescreen.containers
    if container.children <> invalid
      concatenatedContainerContentCount += container.children.count()
    end if
  end for

  m.assertTrue(translatedChannelGuide.getChildCount() = concatenatedContainerContentCount)
End Function


'@Test getContentFromCategoryJson unit tests
Function tubiMetadataTranslate_getContentFromCategoryJson_test()
  categoryJson = ReadAsciiFile("pkg:/source/tests/rooibos/units/category.json")
  fetchTime = CreateObject("roDateTime").AsSeconds()
  translated = m.translate.translateContainer(ParseJson(categoryJson), categoryJson)
  m.assertNotInvalid(translated)
  child = m.translate.getContentFromCategoryJson(translated, translated.getChild(0).id)
  m.assertNotInvalid(child)
End Function


'@Test generateChannelPosterUrl unit tests
Function tubiMetadataTranslate_generateChannelPosterUrl_test()
  channel = ParseJson(ReadAsciiFile("pkg:/source/tests/rooibos/units/channel.json"))
  posterUrl = m.translate.generateChannelPosterUrl(channel.container.id)
  m.assertEqual(posterUrl, "https://cdn.adrise.tv/image/roku_support_images/channel-poster-cbs.png")
End Function


'@Test generateChannelPosterUrl unbranded unit tests
Function tubiMetadataTranslate_generateChannelPosterUrl_unbranded_test()
  posterUrl = m.translate.generateChannelPosterUrl("")
  m.assertEqual(posterUrl, m.constants.urls.channelPosterUnbranded)
  posterUrl = m.translate.generateChannelPosterUrl(invalid)
  m.assertEqual(posterUrl, m.constants.urls.channelPosterUnbranded)
End Function


'@Test composeVideoResources unit tests
Function tubiMetadataTranslate_composeVideoResources_test()
  content = ParseJson(ReadAsciiFile("pkg:/source/tests/rooibos/units/video_resources.json"))
  m.assertNotInvalid(content)

  videoResources = m.translate.composeVideoResources(content)
  m.assertNotInvalid(videoResources)

  ' check the number of resources is accurate
  m.assertEqual(videoResources.count(), content.video_resources.count())

  for i=0 to 1
    m.assertNotInvalid(videoResources[i].url)
    m.assertNotInvalid(videoResources[i].drmHeaders)
    m.assertNotInvalid(videoResources[i].length)
    m.assertEqual(videoResources[i].streamformat, "dash")
  end for

  'Widevine has drmParams
  m.assertEqual(videoResources[0].type, "dash_widevine_psshv0")
  m.assertNotInvalid(videoResources[0].drmParams)
  m.assertNotInvalid(videoResources[0].drmParams.licenseServerUrl)
  m.assertEqual(videoResources[0].drmParams.keySystem, "Widevine")
  m.assertNotInvalid(videoResources[0].drmHeaders)

  'Playready doesn't have drmParams
  m.assertEqual(videoResources[1].type, "dash_playready_psshv0")
  m.assertInvalid(videoResources[1].drmParams)
  m.assertNotInvalid(videoResources[1].encodingType)
  m.assertNotInvalid(videoResources[1].encodingKey)
  m.assertNotInvalid(videoResources[1].drmHeaders)

  'HLS shouldn't have any drm fields
  m.assertNotInvalid(videoResources[2].url)
  m.assertNotInvalid(videoResources[2].length)
  m.assertInvalid(videoResources[2].drmParams)
  m.assertInvalid(videoResources[2].drmHeaders)
  m.assertEqual(videoResources[2].streamformat, "hls")
End Function


'@Test translateEPGChannelIds unit tests
Function tubiMetadataTranslate_translateEPGChannelIds_test()
  epgChannelIdsJson = ReadAsciiFile("pkg:/source/tests/rooibos/units/epgChannelIds.json")
  fetchTime = CreateObject("roDateTime").AsSeconds()
  parsedLinearEPG = ParseJson(epgChannelIdsJson)
  translated = m.translate.translateEPGChannelIds(parsedLinearEPG, m.constants.ui.screenIds.epgScreen)
  m.assertNotInvalid(translated)
  m.assertTrue(translated.getChildCount() = 88)
  m.assertTrue(translated.getChild(0).id = "613683")
  m.assertTrue(translated.getChild(0).containerName = "Sports on Tubi")

End Function


'@Test translateEPGPrograms unit tests
Function tubiMetadataTranslate_translateEPGPrograms_test()
  'test for valid fields
  epgProgramsJson = ReadAsciiFile("pkg:/source/tests/rooibos/units/epgProgram.json")
  fetchTime = CreateObject("roDateTime").AsSeconds()
  translated = m.translate.translateEPGPrograms(ParseJson(epgProgramsJson), m.constants.ui.screenIds.epgScreen)
  datetimeObj = CreateObject("roDateTime")

  m.assertNotInvalid(translated)

  channelInfo = translated.getchild(0)
  channelFromJson = ParseJson(epgProgramsJson)
  channelDescription = channelFromJson.rows[0].description
  HDSMALLICONURL = channelFromJson.rows[0].images.thumbnail[0]

  m.assertEqual(channelInfo.id, "557344")
  m.assertEqual(channelInfo.channelName, "fubo Sports Network")
  m.assertEqual(channelInfo.type, "linear")
  m.AssertNotEqual(channelInfo.validUntil, 0)
  m.assertEqual(channelInfo.HDSMALLICONURL, HDSMALLICONURL)
  m.assertEqual(channelInfo.description, channelDescription)
  m.assertTrue(channelInfo.backgrounds.count() > 0)
  m.assertTrue(channelInfo.videoResources.count() > 0)
  m.assertNotInvalid(channelInfo.hasSubtitles)
  m.assertNotInvalid(channelInfo.pubId)


  program = channelInfo.getchild(0)
  programInfo = channelFromJson.rows[0].programs[0]

  datetimeObj.FromISO8601String(programInfo.start_time)
  datetimeObj.ToLocalTime()
  program_startTime = datetimeObj.asSeconds()
  start_Time = GetAMPMTimeString(datetimeObj, false)

  datetimeObj.FromISO8601String(programInfo.end_time)
  datetimeObj.ToLocalTime()
  program_endTime= datetimeObj.asSeconds()
  end_Time = GetAMPMTimeString(datetimeObj, false)

  hours_of_airing = start_Time + " - " + end_Time

  m.assertEqual(program.id, "557344")
  m.assertEqual(program.TITLE, "No Chill With Gilbert Arenas")
  m.assertEqual(program.startTime, program_startTime)
  m.assertEqual(program.endTime, program_endTime)
  m.assertEqual(program.hoursOfAiring, hours_of_airing)
  m.assertEqual(program.description, programInfo.description)
  m.assertEqual(program.FHDPosterUrl, programInfo.images.poster[0])

  'test for optional fields for program

  epgProgramsJson = ReadAsciiFile("pkg:/source/tests/rooibos/units/epgProgram.json")
  fetchTime = CreateObject("roDateTime").AsSeconds()
  translated = m.translate.translateEPGPrograms(ParseJson(epgProgramsJson), m.constants.ui.screenIds.epgScreen)

  channelInfo = translated.getchild(0)
  program = channelInfo.getchild(0)

  m.assertTrue(program.Categories.count() = 0)
  m.assertEqual(program.Rating, "")
  'm.assertTrue(program.descriptors.count() = 0) '- commenting this as epgProgram.json tags is empty. If you want to use this assert, add value to tags in epgProgram.json
  m.assertEqual(program.ReleaseDate, "")

End Function


'@Test setDescriptorCodeAndDescription unit tests
Function tubiMetadataTranslate_setDescriptorCodeAndDescription_test()

  descriptors = [
    {
        "code": "L",
        "description": "Coarse or crude language"
    },
    {
        "code": "V",
        "description": "Violence"
    }
  ]
  content = CreateObject("roSGNode", "TubiContentNode")
  m.translate.setDescriptorCodeAndDescription(content, descriptors)

  m.assertNotInvalid(content.descriptorCode)
  m.assertEqual(content.descriptorCode, "L V ")

  m.assertNotInvalid(content.descriptorDescription)
  m.assertEqual(content.descriptorDescription, "Coarse or crude language, Violence")


  descriptors = []
  content = CreateObject("roSGNode", "TubiContentNode")
  m.translate.setDescriptorCodeAndDescription(content, descriptors)

  m.assertNotInvalid(content.descriptorCode)
  m.assertEqual(content.descriptorCode, "")

  m.assertNotInvalid(content.descriptorDescription)
  m.assertEqual(content.descriptorDescription, "")


End Function
