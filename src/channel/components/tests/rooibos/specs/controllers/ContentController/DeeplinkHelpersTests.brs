'@TestSuite [DeeplinkHelpers] DeeplinkHelpers.brs


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests DeeplinkHelper
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test populateInfoPanelItem unit test
'@Params [ "asdf", {channel: invalid, program: invalid} ]
'@Params [ "a,b", {channel: invalid, program: invalid} ]
'@Params [ "a:,b:,c:1234", {channel: invalid, program: invalid} ]
'@Params [ "channel:1235,program:a_program_id", {channel: 12345, channel: a_program_id} ]
Function deeplinkHelper_parseSportsEventContentId_test(input, expected)
  result = parseSportsEventContentId(input.encodeUriComponent())
  m.assertEqual(result, expected)
End Function

Function GeneralTaskModule(a, b)
  ' ignored
End Function

Function retrieveClientErrorConfig(a, b)
  ' ignored
End Function