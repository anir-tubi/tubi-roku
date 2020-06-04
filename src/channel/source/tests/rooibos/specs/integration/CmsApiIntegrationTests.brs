'@TestSuite [CmsApi] CmsApi.brs 

'@Setup
Function CmsApiSetup()
  m.constants = getConstants()
  m.request = TubiRequest(m.constants.settings.mode)
  ' For now, don't test any signed-in users
  m.mockAuth = {
    createAuthRequest: Function(a, b, c)
      return invalid
    End Function
  }
  m.api = CmsApi(m.constants, m.request, m.mockAuth)
End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in CmsApi.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test singleContentReq integration tests
Function cmsApi_singleContentReq_test()
  request = m.api.singleContentReq("111770")
  content = request.runSynchronous()
  m.AssertNotInvalid(content)
  parsed = ParseJson(content)
  m.AssertNotInvalid(parsed.id)
  m.AssertEqual(parsed.id, "111770")
End Function


'@Test singleContentReq withChannels integration tests
Function cmsApi_singleContentReq_withChannels_test()
  request = m.api.singleContentReq("02076", true)
  content = request.runSynchronous()
  m.AssertNotInvalid(content)
  parsed = ParseJson(content)
  m.AssertNotInvalid(parsed.id)
  m.AssertNotInvalid(parsed.channel_id)
  m.AssertNotInvalid(parsed.channel_logo)
  m.AssertEqual(parsed.id, "2076")
End Function


'@Test upNextContentReq integration tests
Function cmsApi_upNextContentReq_test()
  request = m.api.upNextContentReq("312412")
  upNext = request.runSynchronous()
  m.AssertNotInvalid(upNext)
  parsed = ParseJson(upNext)
  m.AssertEqual(type(parsed), "roArray")
  m.AssertTrue(parsed.count() > 0)
End Function


'@Test upNextContentReq withContainer integration tests
Function cmsApi_upNextContentReq_withContainer()
  request = m.api.upNextContentReq("312412", "most_popular")
  upNext = request.runSynchronous()
  m.AssertNotInvalid(upNext)
  parsed = ParseJson(upNext)
  m.AssertEqual(type(parsed), "roArray")
  m.AssertTrue(parsed.count() > 0)
End Function


'@Test relatedContentReq integration tests
Function cmsApi_relatedContentReq_test()
  request = m.api.relatedContentReq("312412")
  related = request.runSynchronous()
  m.AssertNotInvalid(related)
  parsed = ParseJson(related)
  m.AssertEqual(type(parsed), "roArray")
  m.AssertTrue(parsed.count() > 0)
End Function


'@Test thumbnailsReq integration tests
Function cmsApi_thumbnailsReq_test()
  request = m.api.thumbnailsReq("312412")
  thumbnails = request.runSynchronous()
  m.AssertNotInvalid(thumbnails)
  parsed = ParseJson(thumbnails)
  m.AssertNotInvalid(parsed.id)
  m.AssertEqual(parsed.id, "312412")
  ' verify the fields we parse
  m.AssertNotInvalid(parsed.sprites)
  m.AssertNotInvalid(parsed.count_per_sprite)
  m.AssertNotInvalid(parsed.frame_width)
  m.AssertNotInvalid(parsed.height)
End Function


'@Test channelReq integration tests
Function cmsApi_channelReq_test()
  request = m.api.channelReq("aetv", 200)
  channel = request.runSynchronous()
  m.AssertNotInvalid(channel)
  if channel <> invalid
    parsed = ParseJson(channel)
    m.AssertNotInvalid(parsed)
    m.AssertNotInvalid(parsed.container)
    m.AssertEqual(parsed.container.type, "channel")
    m.AssertEqual(parsed.container.id, "aetv")
  end if
End Function


'@Test homeScreenReq integration tests
Function cmsApi_homeScreenReq_test()
  request = m.api.homeScreenReq(10)
  home = request.runSynchronous()
  parsed = ParseJson(home)
  m.AssertNotInvalid(parsed)
  m.AssertNotInvalid(parsed.containers)
  m.AssertTrue(type(parsed.containers) = "roArray")
End Function


'@Test categoryReq integration tests
Function cmsApi_categoryReq_test()
  request = m.api.categoryReq("featured", 200)
  category = request.runSynchronous()
  parsed = ParseJson(category)
  m.AssertNotInvalid(parsed)
  m.AssertNotInvalid(parsed.container)
  m.AssertEqual(parsed.container.type, "regular")
  m.AssertEqual(parsed.container.id, "featured")
End Function


'@Test searchReq integration tests
Function cmsApi_searchReq_test()
  request = m.api.searchReq("bea", 200)
  search = request.runSynchronous()
  parsed = ParseJson(search)
  m.AssertNotInvalid(parsed)
End Function
