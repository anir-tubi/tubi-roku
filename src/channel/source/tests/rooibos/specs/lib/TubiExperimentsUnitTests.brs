'@TestSuite [TubiExperiments] TubiExperiments.brs 

'@Setup
Function TubiExperimentsSetup()

  m.constants = getConstants()
  m.request = TubiRequest()
  m.experiments = TubiExperiments(m.constants)
  m.experiments.getNamespaces = tubiExperiments_mockGetNamespaces_testHelper

End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiExperiments.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


' Mock experiment response from swagger: 
' https://default_server/datascience/evaluate/namespaces?platform=roku&inputs=%7B%22deviceId%22%3A%22AABBCCDDEE%22%7D
Function tubiExperiments_mockGetNamespaces_testHelper(request) As Object
  return ParseJson("[{""namespace"": ""UserNamespace"",""resource"": ""{\""testParam\"":false}"",""experiment_result"": {""experiment_name"": ""qa.preroll_at_90"",""treatment"": ""off""}}]")
end Function


'@Test initSuccess unit tests
Function tubiExperiments_initSuccess_test()
  experiments = m.experiments
  m.assertInvalid(m.constants.experiments.info)
  experiments.init(m.request)
  m.assertNotInvalid(m.constants.experiments.info)
End Function


'@Test getExperimentValueValid unit tests
Function tubiExperiments_getExperimentValueValid_test()
  experiments = m.experiments
  experiments.init(m.request)
  value = experiments.getExperimentValue("UserNamespace", "preroll_at_90")
  trackinfo = experiments.getExperimentTracking("UserNamespace", "preroll_at_90")
  moreinfo = experiments.getExperimentResource("UserNamespace", "preroll_at_90")
  m.assertNotInvalid(value)
  m.assertNotInvalid(trackinfo)
  m.assertNotInvalid(moreinfo)
  m.assertNotInvalid(moreinfo.testParam)
  m.assertFalse(moreinfo.testParam)
  m.assertEqual(value, "off")
End Function


'// This test case will not be found in the "backend" so the default will be used.
'@Test getExperimentValueDefault unit tests
Function tubiExperiments_getExperimentValueDefault_test()
  experiments = m.experiments
  experiments.defaultValues = {
    UserNamespace: {
      roku_test_experiment: true
    }   
  }
  experiments.init(m.request)
  value = experiments.getExperimentValue("UserNamespace", "roku_test_experiment")
  trackinfo = experiments.getExperimentTracking("UserNamespace", "roku_test_experiment")
  m.assertNotInvalid(value)
  m.assertTrue(value)
End Function


'@Test getExperimentValueInvalid unit tests
Function tubiExperiments_getExperimentValueInvalid_test()
  experiments = m.experiments
  experiments.init(m.request)
  value = experiments.getExperimentValue("UserNamespace", "roku_missing_experiment")
  trackinfo = experiments.getExperimentTracking("UserNamespace", "roku_missing_experiment")
  moreinfo = experiments.getExperimentResource("UserNamespace", "roku_missing_experiment")
  m.assertInvalid(value)
  m.assertInvalid(trackinfo)
  m.assertInvalid(moreinfo)
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It initFailed in TubiExperiments.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



' Mock that the server did not respond, or response was invalid
Function tubiExperiments_mockGetInvalidNamespaces_testHelper(request) As Object
  return invalid
End Function


'@BeforeEach
Function tubiExperiments_updateNamespaces()

  m.experiments.getNamespaces = tubiExperiments_mockGetInvalidNamespaces_testHelper  

End Function


'@Test initFailed unit tests
Function tubiExperiments_initFailed_test()
  experiments = m.experiments
  experiments.init(m.request)
  m.assertInvalid(m.constants.experiments.info)
  ' We don't want to crash if init() failed, just use defaults if available, otherwise return 'invalid' for the value
  value = experiments.getExperimentValue("UserNamespace", "preroll_at_90")
  trackinfo = experiments.getExperimentTracking("UserNamespace", "preroll_at_90")
  moreinfo = experiments.getExperimentResource("UserNamespace", "preroll_at_90")

  m.assertInvalid(value)
  m.assertInvalid(trackinfo)
  m.assertInvalid(moreinfo)
End Function