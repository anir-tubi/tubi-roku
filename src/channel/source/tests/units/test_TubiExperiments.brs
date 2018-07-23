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
  experiments = TubiExperiments(request, constants)
  experiments.getNamespaces = testHelper_tubiExperiments_mockGetNamespaces
  result = m.assertInvalid(constants.experiments.info)
  experiments.init()
  result += m.assertNotInvalid(constants.experiments.info)
  return result
End Function

Function testCase_tubiExperiments_initFailed()
  constants = getConstants()
  request = TubiRequest()
  experiments = TubiExperiments(request, constants)
  experiments.getNamespaces = testHelper_tubiExperiments_mockGetInvalidNamespaces
  result = ""
  result += m.assertInvalid(constants.experiments.info)
  experiments.init()
  result += m.assertInvalid(constants.experiments.info)
  ' We don't want to crash if init() failed, just use defaults if available, otherwise return 'invalid' for the value
  value = experiments.getExperimentValue("UserNamespace", "preroll_at_90")
  result += m.assertNotInvalid(value)
  result += m.assertTrue(value.DoesExist("experimentvalue"))
  result += m.assertTrue(value.DoesExist("trackinfo"))
  result += m.assertInvalid(value.experimentvalue)
  return result
End Function

Function testCase_tubiExperiments_getExperimentValueValid()
  constants = getConstants()
  request = TubiRequest()
  experiments = TubiExperiments(request, constants)
  experiments.getNamespaces = testHelper_tubiExperiments_mockGetNamespaces
  result = ""
  experiments.init()
  value = experiments.getExperimentValue("UserNamespace", "preroll_at_90")
  result += m.assertNotInvalid(value)
  result += m.assertTrue(value.DoesExist("experimentvalue"))
  result += m.assertTrue(value.DoesExist("trackinfo"))
  result += m.assertFalse(value.experimentvalue)
  return result
End Function

Function testCase_tubiExperiments_getExperimentValueDefault()
  constants = getConstants()
  request = TubiRequest()
  experiments = TubiExperiments(request, constants)
  experiments.getNamespaces = testHelper_tubiExperiments_mockGetNamespaces
  experiments.defaultValues = {
    UserNamespace: {
      roku_test_experiment: true
    }   
  }
  result = ""
  experiments.init()
  value = experiments.getExperimentValue("UserNamespace", "roku_test_experiment")
  result += m.assertNotInvalid(value)
  result += m.assertTrue(value.DoesExist("experimentvalue"))
  result += m.assertTrue(value.DoesExist("trackinfo"))
  result += m.assertTrue(value.experimentvalue)
  return result
End Function

Function testCase_tubiExperiments_getExperimentValueInvalid()
  constants = getConstants()
  request = TubiRequest()
  experiments = TubiExperiments(request, constants)
  experiments.getNamespaces = testHelper_tubiExperiments_mockGetNamespaces
  result = ""
  experiments.init()
  value = experiments.getExperimentValue("UserNamespace", "roku_missing_experiment")
  result += m.assertNotInvalid(value)
  result += m.assertTrue(value.DoesExist("experimentvalue"))
  result += m.assertTrue(value.DoesExist("trackinfo"))
  result += m.assertInvalid(value.experimentvalue)
  return result
End Function


' Mock that the server did not respond, or response was invalid
Function testHelper_tubiExperiments_mockGetInvalidNamespaces() As Object
  return invalid
End Function

' Mock experiement response from swagger: 
' https://default_server/datascience/evaluate/namespaces?platform=roku&inputs=%7B%22deviceId%22%3A%22AABBCCDDEE%22%7D
Function testHelper_tubiExperiments_mockGetNamespaces() As Object
  return ParseJson("[{""name"":""WebNamespace"",""unit"":""deviceId"",""segments"":500,""default_experiment"":""WebDefaults"",""experiment_sequence"":[{""action"":""add"",""definition"":""CommentsWeb"",""name"":""CommentsWeb.1"",""segments"":150},{""action"":""add"",""definition"":""LiveTvOrCarousel"",""name"":""LiveTvOrCarousel.1"",""segments"":150}],""experiment_definitions"":[{""name"":""CommentsWeb"",""salt"":""CommentsWeb"",""assign"":""show_comments = bernoulliTrial(p=0.75, unit=deviceId);\nif (show_comments) {\n  pageid = uniformChoice(choices=['individual', 'global'], unit=deviceId);\n}\n"",""compiled"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""show_comments"",""value"":{""p"":0.75,""unit"":""AABBCCDDEE"",""op"":""bernoulliTrial"",""salt"":""show_comments""}},{""op"":""cond"",""cond"":[{""if"":{""op"":""get"",""var"":""show_comments""},""then"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""pageid"",""value"":{""choices"":[""individual"",""global""],""unit"":""AABBCCDDEE"",""op"":""uniformChoice"",""salt"":""pageid""}}]}}]}]},""auto_log_exposure"":true},{""name"":""LiveTvOrCarousel"",""salt"":""LiveTvOrCarousel"",""assign"":""display = uniformChoice(choices=['livetv', 'carousel'], unit=deviceId);\n"",""compiled"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""display"",""value"":{""choices"":{""op"":""array"",""values"":[""livetv"",""carousel""]},""unit"":{""op"":""get"",""var"":""deviceId""},""op"":""uniformChoice""}}]},""auto_log_exposure"":true},{""name"":""WebDefaults"",""salt"":""WebDefaults"",""assign"":""show_comments = 1;\npageid = 'global';\ndisplay = 'carousel';\n"",""compiled"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""show_comments"",""value"":1},{""op"":""set"",""var"":""pageid"",""value"":""global""},{""op"":""set"",""var"":""display"",""value"":""carousel""}]},""auto_log_exposure"":false}],""evaluated_experiment_name"":""CommentsWeb"",""evaluated_experiment_salt"":""WebNamespace-CommentsWeb"",""evaluated_params"":{""show_comments"":1,""pageid"":""individual""},""evaluated_default"":false},{""name"":""ImdbNamespace"",""unit"":""deviceId"",""segments"":100,""default_experiment"":""ImdbSorting"",""experiment_sequence"":[{""action"":""add"",""definition"":""ImdbSorting"",""name"":""ImdbSorting.1"",""segments"":100}],""experiment_definitions"":[{""name"":""ImdbSorting"",""salt"":""ImdbSorting"",""assign"":""sort = bernoulliTrial(p=0.8, unit=deviceId);\n"",""compiled"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""sort"",""value"":{""p"":0.8,""unit"":""AABBCCDDEE"",""op"":""bernoulliTrial"",""salt"":""sort""}}]},""auto_log_exposure"":false}],""evaluated_experiment_name"":""ImdbSorting"",""evaluated_experiment_salt"":""ImdbNamespace-ImdbSorting"",""evaluated_params"":{""sort"":1},""evaluated_default"":false},{""name"":""ContentNamespace"",""unit"":""deviceId"",""segments"":500,""default_experiment"":""ContentDefaults"",""experiment_sequence"":[{""action"":""add"",""definition"":""RottenTomatoesSorting"",""name"":""RottenTomatoesSorting.1"",""segments"":200}],""experiment_definitions"":[{""name"":""RottenTomatoesSorting"",""salt"":""RottenTomatoesSorting"",""assign"":""rt_exp_number = uniformChoice(choices=[0, 1, 2, 3], unit=deviceId);\n"",""compiled"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""rt_exp_number"",""value"":{""choices"":[0,1,2,3],""unit"":""AABBCCDDEE"",""op"":""uniformChoice"",""salt"":""rt_exp_number""}}]},""auto_log_exposure"":false},{""name"":""ContentDefaults"",""salt"":""ContentDefaults"",""assign"":""sort = 0;\nfeatured = 0;\nflattened = 0;\n"",""compiled"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""sort"",""value"":0},{""op"":""set"",""var"":""featured"",""value"":0},{""op"":""set"",""var"":""flattened"",""value"":0}]},""auto_log_exposure"":false}],""evaluated_experiment_name"":""RottenTomatoesSorting"",""evaluated_experiment_salt"":""ContentNamespace-RottenTomatoesSorting"",""evaluated_params"":{""rt_exp_number"":2},""evaluated_default"":false},{""name"":""AndroidNamespace"",""unit"":""deviceId"",""segments"":100,""default_experiment"":""AndroidDefaults"",""experiment_sequence"":[{""action"":""add"",""definition"":""NewUserCategories"",""name"":""NewUserCategories.1"",""segments"":100},{""action"":""remove"",""name"":""NewUserCategories.1""},{""action"":""add"",""definition"":""SkipLogin"",""name"":""SkipLogin.1"",""segments"":75},{""action"":""add"",""definition"":""LiveTv"",""name"":""LiveTv.1"",""segments"":25}],""experiment_definitions"":[{""name"":""NewUserCategories"",""salt"":""NewUserCategories"",""assign"":""# experiment group is 80%, control group is 20%\nshow_categories = bernoulliTrial(p=0.8, unit=deviceId);\nif (show_categories) {\n  # user either in test group to choose categories and see changes in category list\n  show_and_reorder = bernoulliTrial(p=0.5, unit=deviceId);\n}\n"",""compiled"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""show_categories"",""value"":{""p"":0.8,""unit"":{""op"":""get"",""var"":""deviceId""},""op"":""bernoulliTrial""}},{""op"":""cond"",""cond"":[{""if"":{""op"":""get"",""var"":""show_categories""},""then"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""show_and_reorder"",""value"":{""p"":0.5,""unit"":{""op"":""get"",""var"":""deviceId""},""op"":""bernoulliTrial""}}]}}]}]},""auto_log_exposure"":true},{""name"":""SkipLogin"",""salt"":""SkipLogin"",""assign"":""skip_login = bernoulliTrial(p=0.5, unit=deviceId);\n"",""compiled"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""skip_login"",""value"":{""p"":0.5,""unit"":{""op"":""get"",""var"":""deviceId""},""op"":""bernoulliTrial""}}]},""auto_log_exposure"":true},{""name"":""LiveTv"",""salt"":""LiveTv"",""assign"":""livetv = weightedChoice(choices=[true, false], weights=[0.5, 0.5], unit=deviceId);\n"",""compiled"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""livetv"",""value"":{""choices"":[true,false],""weights"":[0.5,0.5],""unit"":""AABBCCDDEE"",""op"":""weightedChoice"",""salt"":""livetv""}}]},""auto_log_exposure"":true},{""name"":""AndroidDefaults"",""salt"":""AndroidDefaults"",""assign"":""skip_login = 0;\nlivetv = false;\n"",""compiled"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""skip_login"",""value"":0},{""op"":""set"",""var"":""livetv"",""value"":false}]},""auto_log_exposure"":false}],""evaluated_experiment_name"":""LiveTv"",""evaluated_experiment_salt"":""AndroidNamespace-LiveTv"",""evaluated_params"":{""livetv"":false},""evaluated_default"":false},{""name"":""UserNamespace"",""unit"":""deviceId"",""segments"":100,""default_experiment"":""UserDefaults"",""experiment_sequence"":[{""action"":""add"",""definition"":""PreRollAt90"",""name"":""PreRollAt90.1"",""segments"":10}],""experiment_definitions"":[{""name"":""PreRollAt90"",""salt"":""PreRollAt90"",""assign"":""preroll_at_90 = uniformChoice(choices=['0', '90'], unit=deviceId);\n"",""compiled"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""preroll_at_90"",""value"":{""choices"":{""op"":""array"",""values"":[""0"",""90""]},""unit"":{""op"":""get"",""var"":""deviceId""},""op"":""uniformChoice""}}]},""auto_log_exposure"":true},{""name"":""UserDefaults"",""salt"":""UserDefaults"",""assign"":""preroll_at_90 = false;\n"",""compiled"":{""op"":""seq"",""seq"":[{""op"":""set"",""var"":""preroll_at_90"",""value"":false}]},""auto_log_exposure"":false}],""evaluated_experiment_name"":""UserDefaults"",""evaluated_experiment_salt"":""UserDefaults"",""evaluated_params"":{""preroll_at_90"":false},""evaluated_default"":true}]")
end Function