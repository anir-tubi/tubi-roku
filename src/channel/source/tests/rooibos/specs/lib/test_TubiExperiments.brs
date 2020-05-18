Function TestSuite_TubiExperiments()
  this = BaseTestSuite()
  this.name = "TubiExperimentsTestSuite"
  this.addTest("init_success", testCase_tubiExperiments_initSuccess)
  this.addTest("init_failed", testCase_tubiExperiments_initFailed)
  this.addTest("getExperimentValue_invalid", testCase_tubiExperiments_getExperimentValueInvalid)
  this.addTest("getExperimentValue_valid", testCase_tubiExperiments_getExperimentValueValid)
  this.addTest("getExperimentValue_default", testCase_tubiExperiments_getExperimentValueDefault)
  return this
End Function

Function testCase_tubiExperiments_initSuccess()
  constants = getConstants()
  request = TubiRequest()
  experiments = TubiExperiments(constants)
  experiments.getNamespaces = testHelper_tubiExperiments_mockGetNamespaces
  result = m.assertInvalid(constants.experiments.info)
  experiments.init(request)
  result += m.assertNotInvalid(constants.experiments.info)
  return result
End Function

Function testCase_tubiExperiments_initFailed()
  constants = getConstants()
  request = TubiRequest()
  experiments = TubiExperiments(constants)
  experiments.getNamespaces = testHelper_tubiExperiments_mockGetInvalidNamespaces
  result = ""
  result += m.assertInvalid(constants.experiments.info)
  experiments.init(request)
  result += m.assertInvalid(constants.experiments.info)
  ' We don't want to crash if init() failed, just use defaults if available, otherwise return 'invalid' for the value
  value = experiments.getExperimentValue("UserNamespace", "preroll_at_90")
  trackinfo = experiments.getExperimentTracking("UserNamespace", "preroll_at_90")
  moreinfo = experiments.getExperimentResource("UserNamespace", "preroll_at_90")

  result += m.assertInvalid(value)
  result += m.assertInvalid(trackinfo)
  result += m.assertInvalid(moreinfo)
  return result
End Function

Function testCase_tubiExperiments_getExperimentValueValid()
  constants = getConstants()
  request = TubiRequest()
  experiments = TubiExperiments(constants)
  experiments.getNamespaces = testHelper_tubiExperiments_mockGetNamespaces
  result = ""
  experiments.init(request)
  value = experiments.getExperimentValue("UserNamespace", "preroll_at_90")
  trackinfo = experiments.getExperimentTracking("UserNamespace", "preroll_at_90")
  moreinfo = experiments.getExperimentResource("UserNamespace", "preroll_at_90")
  result += m.assertNotInvalid(value)
  result += m.assertNotInvalid(trackinfo)
  result += m.assertNotInvalid(moreinfo)
  result += m.assertNotInvalid(moreinfo.testParam)
  result += m.assertFalse(moreinfo.testParam)
  result += m.assertEqual(value, "off")
  return result
End Function


'// This test case will not be found in the "backend" so the default will be used.
Function testCase_tubiExperiments_getExperimentValueDefault()
  constants = getConstants()
  request = TubiRequest()
  experiments = TubiExperiments(constants)
  experiments.getNamespaces = testHelper_tubiExperiments_mockGetNamespaces
  experiments.defaultValues = {
    UserNamespace: {
      roku_test_experiment: true
    }   
  }
  result = ""
  experiments.init(request)
  value = experiments.getExperimentValue("UserNamespace", "roku_test_experiment")
  trackinfo = experiments.getExperimentTracking("UserNamespace", "roku_test_experiment")
  result += m.assertNotInvalid(value)
  result += m.assertTrue(value)
  return result
End Function

Function testCase_tubiExperiments_getExperimentValueInvalid()
  constants = getConstants()
  request = TubiRequest()
  experiments = TubiExperiments(constants)
  experiments.getNamespaces = testHelper_tubiExperiments_mockGetNamespaces
  result = ""
  experiments.init(request)
  value = experiments.getExperimentValue("UserNamespace", "roku_missing_experiment")
  trackinfo = experiments.getExperimentTracking("UserNamespace", "roku_missing_experiment")
  moreinfo = experiments.getExperimentResource("UserNamespace", "roku_missing_experiment")
  result += m.assertInvalid(value)
  result += m.assertInvalid(trackinfo)
  result += m.assertInvalid(moreinfo)
  return result
End Function


' Mock that the server did not respond, or response was invalid
Function testHelper_tubiExperiments_mockGetInvalidNamespaces(request) As Object
  return invalid
End Function


' Mock experiment response from swagger: 
' https://default_server/datascience/evaluate/namespaces?platform=roku&inputs=%7B%22deviceId%22%3A%22AABBCCDDEE%22%7D
Function testHelper_tubiExperiments_mockGetNamespaces(request) As Object
  return ParseJson("[{""namespace"": ""UserNamespace"",""resource"": ""{\""testParam\"":false}"",""experiment_result"": {""experiment_name"": ""preroll_at_90"",""treatment"": ""off""}}]")
end Function