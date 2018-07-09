Function TestSuite_TubiMetadataTranslate() as Object
  this = BaseTestSuite()
  this.Name = "TubiMetadataTranslateTestSuite"
  this.SetUp = TubiMetadataTranslateTestSuite_SetUp
  this.addTest("translateRecursive_testTranslateTypes", testCase_tubiMetadataTranslate_translateRecursive_testTranslateTypes)
  this.addTest("translateRecursive_testParentTypes", testCase_tubiMetadataTranslate_translateRecursive_testParentTypes)
  this.addTest("translateRecursive_testCreditsCuepoints", testCase_tubiMetadataTranslate_translateRecursive_testCreditsCuepoints)
  this.addTest("translateRecursive_channel", testCase_tubiMetadataTranslate_translateRecursive_channel)
  this.addTest("translateContainer_category", testCase_tubiMetadataTranslate_translateContainer_category)
  this.addTest("translateContainer_channel", testCase_tubiMetadataTranslate_translateContainer_channel)
  this.addTest("translateChannel", testCase_tubiMetadataTranslate_translateChannel)
  this.addTest("translateHomescreen", testCase_tubiMetadataTranslate_translateHomescreen)
  this.addTest("translate", testCase_tubiMetadataTranslate_translate)
  this.addTest("generateChannelPosterUrl", testCase_tubiMetadataTranslate_generateChannelPosterUrl)
  this.addTest("generateChannelPosterUrl_unbranded", testCase_tubiMetadataTranslate_generateChannelPosterUrl_unbranded)
  return this
End Function

Function TubiMetadataTranslateTestSuite_SetUp()
  m.constants = getConstants()
  m.translate = TubiMetadataTranslate(m.constants)
End Function


'''''''''''''''''''
' translateRecursive

Function testCase_tubiMetadataTranslate_translateRecursive_testTranslateTypes()
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

  result = ""
  for each contentType in serverContentTypes
    dest = CreateObject("roSGNode", "TubiContentNode")
    source.type = contentType
    m.translate.translateRecursive(source, dest)
    if contentType = "s" or contentType = "a"
      result = result + m.assertEqual("0" + source.id, dest.id)
    else
      result = result + m.assertEqual(source.id, dest.id)
    end if
    result = result + m.assertEqual(dest.type, serverContentTypes[contentType])
  end for
  ' check invalid types too
  source.type = ""
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  result = result + m.assertEqual(dest.type, "")
  return result
End Function


Function testCase_tubiMetadataTranslate_translateRecursive_testParentTypes()
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

  result = ""
  for each contentType in parentContentTypes
    parent = CreateObject("roSGNode", "TubiContentNode")
    parent.id = "parent"
    parent.type = contentType
    child = parent.createChild("TubiContentNode")
    m.translate.translateRecursive(source, child)
    if contentType = m.constants.ui.contentTypes.series or contentType = m.constants.ui.contentTypes.season
      result = result + m.assertEqual(child.parentId, parent.id)
    else
      result = result + m.assertEqual(child.parentId, "")
    end if
  end for
  return result
End Function

Function testCase_tubiMetadataTranslate_translateRecursive_testCreditsCuepoints()
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

  result = ""
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  result = result + m.assertTrue(dest.length = 600)
  result = result + m.assertTrue(dest.creditsCuepoint = 550)

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
  result = result + m.assertTrue(dest.length = 600)
  result = result + m.assertTrue(dest.creditsCuepoint = 560)

  ' missing cuepoints
  source = {
    id: "12345"
    type: "v"
    duration: 600
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  result = result + m.assertTrue(dest.length = 600)
  result = result + m.assertTrue(dest.creditsCuepoint = 560)

  ' cuepoint too close to the end
  source = {
    id: "12345"
    type: "v"
    duration: 600
    credit_cuepoints: {
      prologue: 0
      postlude: 595
    }
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  result = result + m.assertTrue(dest.length = 600)
  result = result + m.assertTrue(dest.creditsCuepoint = 560)

  ' no cuepoint or length given
  source = {
    id: "12345"
    type: "v"
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  result = result + m.assertTrue(dest.length = 0)
  result = result + m.assertTrue(dest.creditsCuepoint = 0)

  ' title isn't long enough for default cuepoint placement (no cuepoints)
  source = {
    id: "12345"
    type: "v"
    duration: 10
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  result = result + m.assertTrue(dest.length = 10)
  result = result + m.assertTrue(dest.creditsCuepoint = 0)

  ' title isn't long enough for default cuepoint placement (no cuepoints)
  source = {
    id: "12345"
    type: "v"
    duration: 10
    credit_cuepoints: {
      prologue: 0
      postlude: 8
    }
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  result = result + m.assertTrue(dest.length = 10)
  result = result + m.assertTrue(dest.creditsCuepoint = 0)
  return result
End Function

Function testCase_tubiMetadataTranslate_translateRecursive_channel()
  source = {
    id: "12345"
    type: "v"
    channel_id: "cbs"
    channel_logo: "http://image-server.staging-public.tubi.io/Hg40oOjtkAeV9bFYIFsoEa1qTI8=/180x60/img.adrise.tv/48152e63-af98-477d-a3c2-da391f45facc.png"
  }
  dest = CreateObject("roSGNode", "TubiContentNode")
  m.translate.translateRecursive(source, dest)
  result = ""
  result = result + m.assertNotInvalid(dest.channelImg)
  result = result + m.assertTrue(dest.channelId = "cbs")
  return result
End Function

'''''''''''''''''''
' translateContainer

Function testCase_tubiMetadataTranslate_translateContainer_category()
  categoryJson = ReadAsciiFile("pkg:/source/tests/units/category.json")
  result = ""
  translated = m.translate.translateContainer(ParseJson(categoryJson), categoryJson)
  result = result + m.assertNotInvalid(translated)
  result = result + m.assertEqual(translated.id, "featured")
  result = result + m.assertTrue(translated.totalCount = 8)
  result = result + m.assertTrue(translated.getChildCount() = 8)
  return result
End Function

Function testCase_tubiMetadataTranslate_translateContainer_channel()
  channelJson = ReadAsciiFile("pkg:/source/tests/units/channel.json")
  result = ""
  translated = m.translate.translateContainer(ParseJson(channelJson), channelJson)
  result = result + m.assertNotInvalid(translated)
  result = result + m.assertEqual(translated.id, "cbs")
  result = result + m.assertTrue(translated.totalCount = 96)
  result = result + m.assertTrue(translated.getChildCount() = 96)
  result = result + m.assertEqual(translated.getChild(0).id, "cbs")
  result = result + m.assertNotInvalid(translated.json)
  ' make sure the embedded JSON is also correct
  fullChannelJson = ParseJson(translated.json)
  result = result + m.assertNotInvalid(type(fullChannelJson) = "roAssociativeArray")
  result = result + m.assertNotInvalid(fullChannelJson["cbs"])
  result = result + m.assertTrue(fullChannelJson.count() = 96)
  return result
End Function

'''''''''''''''''''
' translateHomescreen

Function testCase_tubiMetadataTranslate_translateHomescreen()
  homeJson = ReadAsciiFile("pkg:/source/tests/units/homescreen.json")
  result = ""
  translated = m.translate.translateHomescreen(ParseJson(homeJson))
  result = result + m.assertNotInvalid(translated)
  result = result + m.assertTrue(translated.getChildCount() = 48)
  result = result + m.assertTrue(translated.getChild(0).id = "featured")
  result = result + m.assertTrue(translated.getChild(0).getChildCount() = 1)
  return result
End Function


'''''''''''''''''''
' translateMetadata

Function testCase_tubiMetadataTranslate_translate()
  matches = ReadAsciiFile("pkg:/source/tests/units/search.json")
  result = ""
  translated = m.translate.translate(ParseJson(matches))
  result = result + m.assertNotInvalid(translated)
  return result
End Function


'''''''''''''''''''
' translateChannel
Function testCase_tubiMetadataTranslate_translateChannel()
  channelJson = ReadAsciiFile("pkg:/source/tests/units/channel.json")
  result = ""
  translated = m.translate.translateChannel(ParseJson(channelJson))
  result = result + m.assertNotInvalid(translated)
print "translated.id = "; translated.id
  result = result + m.assertEqual(translated.id, "cbs")
print "translated.slug = "; translated.slug
  result = result + m.assertEqual(translated.slug, "cbs")
print "translated.totalCount = "; translated.totalCount
  result = result + m.assertTrue(translated.totalCount = 95)
  result = result + m.assertTrue(translated.getChildCount() = 95)
  return result
End Function

Function testCase_tubiMetadataTranslate_generateChannelPosterUrl()
  channel = ParseJson(ReadAsciiFile("pkg:/source/tests/units/channel.json"))
  posterUrl = m.translate.generateChannelPosterUrl(channel.container.id)
  return m.assertEqual(posterUrl, "http://cdn.adrise.tv/image/roku_support_images/channel-poster-cbs.png")
End Function

Function testCase_tubiMetadataTranslate_generateChannelPosterUrl_unbranded()
  channel = ParseJson(ReadAsciiFile("pkg:/source/tests/units/channel.json"))
  posterUrl = m.translate.generateChannelPosterUrl("")
  result = m.assertEqual(posterUrl, m.constants.urls.channelPosterUnbranded)
  posterUrl = m.translate.generateChannelPosterUrl(invalid)
  result += m.assertEqual(posterUrl, m.constants.urls.channelPosterUnbranded)
  return result
End Function
