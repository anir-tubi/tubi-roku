'@TestSuite [TubiExperiments] TubiExperiments.brs

'@Setup
Function TubiExperimentsSetup()
  m.experimentsInfo = {
    "roku_tupian_background_images": {
      "experiment_result": {
        "experiment_name": "roku_tupian_background_images_v1",
        "segment": "0x00C50289",
        "treatment": "tupian_background_images"
      },
      "namespace": "roku_tupian_background_images",
      "resource": {
        "enabled": true
      }
    }
  }
End function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiExperiments.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test getExperiment
Function tubiExperiments_getExperiment_test()
  experiments = TubiExperiments(m.experimentsInfo)
  namespace = "roku_tupian_background_images"
  experimentName = "roku_tupian_background_images_v1"
  result = experiments.getExperiment(namespace, experimentName)
  m.assertEqual(result.namespace, namespace)
  m.assertEqual(result.resource, m.experimentsInfo[namespace].resource)
  m.assertEqual(experimentName, m.experimentsInfo[namespace].experiment_result.experiment_name)
  m.assertEqual(result.experiment_result.segment, m.experimentsInfo[namespace].experiment_result.segment)
  m.assertEqual(result.experiment_result.treatment, m.experimentsInfo[namespace].experiment_result.treatment)
End Function
