Function TestSuite_CmsApi() as Object
  this = BaseTestSuite()
  this.Name = "CmsApiTestSuite"
'  this.xx_SetUp = CmsApiTestSuite_SetUp
  this.SetUp = CmsApiTestSuite_SetUp
  this.addTest("channelReq", testCase_cmsApi_channelReq)
  this.addTest("thumbnailsReq", testCase_cmsApi_thumbnailsReq)
  this.addTest("singleContentReq", testCase_cmsApi_singleContentReq)
  this.addTest("singleContentReq_withChannels", testCase_cmsApi_singleContentReq_withChannels)
  this.addTest("upNextContentReq", testCase_cmsApi_upNextContentReq)
  this.addTest("upNextContentReq_withContainer", testCase_cmsApi_upNextContentReq_withContainer)
  this.addTest("relatedContentReq", testCase_cmsApi_relatedContentReq)
  this.addTest("homeScreenReq", testCase_cmsApi_homeScreenReq)
  this.addTest("categoryReq", testCase_cmsApi_categoryReq)
  this.addTest("searchReq", testCase_cmsApi_searchReq)
  return this
End Function

Function CmsApiTestSuite_SetUp()
  m.constants = getConstants()
  m.request = TubiRequest()
  ' For now, don't test any signed-in users
  m.mockAuth = {
    createAuthRequest: Function(a, b, c)
      return invalid
    End Function
  }
  m.api = CmsApi(m.constants, m.request, m.mockAuth)
End Function


'''''''''''''''''''''
' singleContentReq
'
Function testCase_cmsApi_singleContentReq()
  request = m.api.singleContentReq("312412")
  content = request.runSynchronous()
  result = ""
  result = result + m.AssertNotInvalid(content)
  parsed = ParseJson(content)
  result = result + m.AssertNotInvalid(parsed.id)
  result = result + m.AssertEqual(parsed.id, "312412")
  return result
End Function


Function testCase_cmsApi_singleContentReq_withChannels()
  request = m.api.singleContentReq("01627", true)
  content = request.runSynchronous()
  result = ""
  result = result + m.AssertNotInvalid(content)
  parsed = ParseJson(content)
  result = result + m.AssertNotInvalid(parsed.id)
  result = result + m.AssertNotInvalid(parsed.channel_id)
  result = result + m.AssertNotInvalid(parsed.channel_logo)
  result = result + m.AssertEqual(parsed.id, "1627")
  return result
End Function

'''''''''''''''''''''
' upNextContentReq
'
Function testCase_cmsApi_upNextContentReq()
  request = m.api.upNextContentReq("312412")
  upNext = request.runSynchronous()
  result = ""
  result = result + m.AssertNotInvalid(upNext)
  parsed = ParseJson(upNext)
  result = result + m.AssertEqual(type(parsed), "roArray")
  result = result + m.AssertTrue(parsed.count() > 0)
  return result
End Function

Function testCase_cmsApi_upNextContentReq_withContainer()
  request = m.api.upNextContentReq("312412", "most_popular")
  upNext = request.runSynchronous()
  result = ""
  result = result + m.AssertNotInvalid(upNext)
  parsed = ParseJson(upNext)
  result = result + m.AssertEqual(type(parsed), "roArray")
  result = result + m.AssertTrue(parsed.count() > 0)
  return result
End Function


'''''''''''''''''''''
' relatedContentReq
'
Function testCase_cmsApi_relatedContentReq()
  request = m.api.relatedContentReq("312412")
  related = request.runSynchronous()
  result = ""
  result = result + m.AssertNotInvalid(related)
  parsed = ParseJson(related)
  result = result + m.AssertEqual(type(parsed), "roArray")
  result = result + m.AssertTrue(parsed.count() > 0)
  return result
End Function


'''''''''''''''''''''
' thumbnailsReq
'
Function testCase_cmsApi_thumbnailsReq()
  request = m.api.thumbnailsReq("312412")
  thumbnails = request.runSynchronous()
  result = ""
  result = result + m.AssertNotInvalid(thumbnails)
  parsed = ParseJson(thumbnails)
  result = result + m.AssertNotInvalid(parsed.id)
  result = result + m.AssertEqual(parsed.id, "312412")
  ' verify the fields we parse
  result = result + m.AssertNotInvalid(parsed.sprites)
  result = result + m.AssertNotInvalid(parsed.count_per_sprite)
  result = result + m.AssertNotInvalid(parsed.frame_width)
  result = result + m.AssertNotInvalid(parsed.height)
  return result
End Function

''''''''''''''
' channelReq
'
Function testCase_cmsApi_channelReq()
  request = m.api.channelReq("cbs", 200)
  channel = request.runSynchronous()
  result = ""
  result = result + m.AssertNotInvalid(channel)
  if channel <> invalid
    parsed = ParseJson(channel)
    result = result + m.AssertNotInvalid(parsed)
    result = result + m.AssertNotInvalid(parsed.container)
    result = result + m.AssertEqual(parsed.container.type, "channel")
    result = result + m.AssertEqual(parsed.container.id, "cbs")
  end if
  return result
End Function


Function testCase_cmsApi_homeScreenReq()
  request = m.api.homeScreenReq(10)
  home = request.runSynchronous()
  result = ""
  parsed = ParseJson(home)
  result = result + m.AssertNotInvalid(parsed)
  result = result + m.AssertNotInvalid(parsed.containers)
  result = result + m.AssertTrue(type(parsed.containers) = "roArray")
  return result
End Function


Function testCase_cmsApi_categoryReq()
  request = m.api.categoryReq("featured", 200)
  category = request.runSynchronous()
  result = ""
  parsed = ParseJson(category)
  result = result + m.AssertNotInvalid(parsed)
  result = result + m.AssertNotInvalid(parsed.container)
  result = result + m.AssertEqual(parsed.container.type, "regular")
  result = result + m.AssertEqual(parsed.container.id, "featured")
  return result
End Function

Function testCase_cmsApi_searchReq()
  request = m.api.searchReq("bea", 200)
  search = request.runSynchronous()
  result = ""
  parsed = ParseJson(search)
  result = result + m.AssertNotInvalid(parsed)
  return result
End Function
