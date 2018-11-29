Function TubiExperiments(request as Object, constants as Object) as Object

  return {
    request: request
    constants: constants

    'example of how defaultValues should be constructed
    ' defaultValues = {
    '   UserNamespace: {
    '     single_row: false
    '     livetv: false
    '   }
    '   RokuNamespace: {
    '       background_color: "00FF12"
    '   }
    ' }
    '
    ' Default values are always used in case of a "control" value or
    ' in the case that the experiment API doesn't return a response with our experiment.
    ' All experiments are required by the backend to have one of the experiment values to be "control"
    defaultValues: {
      UserNamespace: {
        roku_on_now: 0
        roku_single_feature_poster: "control"
      }
      RokuNamespace: {
        roku_simple_register_screen: 0
        roku_ad_content_type: "hls"
      }
    }

    'public methods
    init: tubiExperiments_init
    getExperimentValue: tubiExperiments_getExperimentValue

    'private methods
    getNamespaces: tubiExperiments_getNamespaces_
    parseNamespace: tubiExperiments_parseNamespace_
    getDefault: tubiExperiments_getDefault_
  }

End Function


Function tubiExperiments_init()
  namespaces = m.getNamespaces()

  allNamespaces = invalid
  
  if namespaces <> invalid
    allNamespaces = {}
  
    for each namespace in namespaces
      parsedNamespace = m.parseNamespace(namespace)

      if parsedNamespace.name <> invalid
        allNamespaces[parsedNamespace.name] = parsedNamespace
      end if
    end for
  end if

  m.constants.experiments.info = allNamespaces
  return allNamespaces    'can return invalid
End Function


' Example JSON response from the service:
'
'[
' {
'   "name": "UserNamespace",
'   "unit": "deviceId",
'   "segments": 100,
'   "default_experiment": "UserDefaults",
'   "experiment_sequence": [
'     {
'       "action": "add",
'       "definition": "PreRollAt90",
'       "name": "PreRollAt90.1",
'       "segments": 10
'     }
'   ],
'   "experiment_definitions": [
'     {
'       "name": "PreRollAt90",
'       "salt": "PreRollAt90",
'       "assign": "preroll_at_90 = uniformChoice(choices=['0', '90'], unit=deviceId);\n",
'       "compiled": {
'         "op": "seq",
'         "seq": [
'           {
'             "op": "set",
'             "var": "preroll_at_90",
'             "value": {
'               "choices": {
'                 "op": "array",
'                 "values": [
'                   "0",
'                   "90"
'                 ]
'               },
'               "unit": {
'                 "op": "get",
'                 "var": "deviceId"
'               },
'               "op": "uniformChoice"
'             }
'           }
'         ]
'       },
'       "auto_log_exposure": true
'     },
'     {
'       "name": "UserDefaults",
'       "salt": "UserDefaults",
'       "assign": "preroll_at_90 = false;\n",
'       "compiled": {
'         "op": "seq",
'         "seq": [
'           {
'             "op": "set",
'             "var": "preroll_at_90",
'             "value": false
'           }
'         ]
'       },
'       "auto_log_exposure": false
'     }
'   ],
'   "evaluated_experiment_name": "UserDefaults",
'   "evaluated_experiment_salt": "UserDefaults",
'   "evaluated_params": {
'     "preroll_at_90": false
'   },
'   "evaluated_default": true
' }
']

'Returns an Array of namespaces from UAPI.
'We expect to return an array containing a single or multiple namespace assocArrays
Function tubiExperiments_getNamespaces_()
  inputs = CreateObject("roAssociativeArray")
  inputs.SetModeCaseSensitive()
  inputs.AddReplace("deviceId", m.constants.deviceInfo.deviceId)
  inputs = FormatJson(inputs)

  escapeUrlObj = CreateObject("roUrlTransfer")
  inputs = escapeUrlObj.Escape(inputs)

  url = m.constants.urls.datascience.experiment + "?platform=" + m.constants.platform + "&inputs=" + inputs

  expRequest = m.request.createAsync(url, "getExperiment")
  res = expRequest.runSynchronous()

  namespaces = invalid
  if res <> invalid
    namespaces = ParseJson(res)
  end if

  return namespaces   'can return invalid
End Function



'takes the assocArray as given by the UAPI server and updates it as necessary to be easier to work with... including removing underscores from assocArray keys
'@namespaces: assocArray, an experiments namespace as returned by UAPI and whose json has been parsed to a Brightscript array of assocArrays
Function tubiExperiments_parseNamespace_(namespace as Object) as Object

  'turn the experiment definitions to an assoc array from an array so grabbing definitions later is easier 
  newExperimentDefs = {}
  for each def in namespace.experiment_definitions
    newExperimentDefs[def.name] = def
  end for

  namespace.experiment_definitions = newExperimentDefs

  return namespace    'can return invalid
End Function


'returns the value from the experiment or a default value along with an object that contains all the info for a user tracking request
'the tracking object needs a request queue to be added to it, and then it can be sent via TubiTracking().trackUserEvent()
'
'@namespaceName: string, the name of the namespace in which we will find the experiment
'@parameterName: string, the name of the experiment as found in the experiment definition
Function tubiExperiments_getExperimentValue(namespaceName as string, parameterName as string) as Object
  allExperiments = m.constants.experiments.info

  experimentValue = invalid
  experimentDef = invalid
  experimentName = invalid
  trackInfo = invalid

  namespace = invalid
  if allExperiments <> invalid
    namespace = allExperiments[namespaceName]
  end if

  if namespace <> invalid
    if namespace.evaluated_params <> invalid
      experimentValue = namespace.evaluated_params[parameterName]
      if experimentValue = "control"
        experimentValue = m.getDefault(namespaceName, parameterName)
      end if
    end if

    if namespace.evaluated_experiment_name <> invalid
      experimentName = namespace.evaluated_experiment_name
    end if

    if namespace.experiment_definitions <> invalid and experimentName <> invalid
      experimentDef = namespace.experiment_definitions[experimentName]
    end if
  end if

  if experimentValue <> invalid
    if experimentDef <> invalid and experimentDef.auto_log_exposure = true

      'trackInfo can be sent into TubiTracking().getTrackData() in order to make a tracking API call
      trackInfo = {
        trackType: "experiment"
        value: experimentName
        ctx: namespace.evaluated_experiment_salt
        extraCtx: namespace.evaluated_params
      }

    end if
  else
    experimentValue = m.getDefault(namespaceName, parameterName)
  end if

  return {
    experimentValue: experimentValue
    trackInfo: trackInfo
  }

End Function


'This function gets the appropriate default value from a repository of default values for experiments.
'If we can't find an experiment from the UAPI server response, we'll go here to get the default value for that experiment
'
'@namespaceName: string, the name of the namespace in which we will find the experiment
'@parameterName: string, the name of the experiment as found in the experiment definition
Function tubiExperiments_getDefault_(namespaceName as string, parameterName as string) as Object
  
  defaultValue = invalid
  if m.defaultValues[namespaceName] <> invalid
    defaultValue = m.defaultValues[namespaceName][parameterName]
  end if

  return defaultValue

End Function
