'@TestSuite [CmsApiIntegration] CmsApi.brs 

'@Setup
Function CmsApiIntegrationSetup()
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


'@Test channelReq integration tests
Function cmsApi_channelReq_integration_test()
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
Function cmsApi_homeScreenReq_integration_test()
  request = m.api.homeScreenReq(10)
  home = request.runSynchronous()
  parsed = ParseJson(home)
  m.AssertNotInvalid(parsed)
  m.AssertNotInvalid(parsed.containers)
  m.AssertTrue(type(parsed.containers) = "roArray")
End Function


'@Test categoryReq integration tests
Function cmsApi_categoryReq_integration_test()
  request = m.api.categoryReq("featured", 200)
  category = request.runSynchronous()
  parsed = ParseJson(category)
  m.AssertNotInvalid(parsed)
  m.AssertNotInvalid(parsed.container)
  m.AssertEqual(parsed.container.type, "regular")
  m.AssertEqual(parsed.container.id, "featured")
End Function


'@Test searchReq integration tests
Function cmsApi_searchReq_integration_test()
  request = m.api.searchReq("bea", 200)
  search = request.runSynchronous()
  parsed = ParseJson(search)
  m.AssertNotInvalid(parsed)
End Function
