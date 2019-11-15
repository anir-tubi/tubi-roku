Function TubiExperiments(constants) as Object

  return {
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
    '
    ' The backend allows for a "resource" assoiciative array where we can place any additional info about the experiement
    '   i.e. a color scheme, values for multiple parameters, etc.
    ' Right now this code is not using the resource AA but if it is desired to store valiues on the experiment backend, then we can change this code so it is giving the client this data 
    ' For more info on on the experiement backend, see: https://github.com/adRise/popper-config
'//::TODO::popper = get rid of old kidsMode experiments before releasing the popper experiment
    defaultValues: {
      UserNamespace: {
      }
      RokuNamespace: {
      }
    }

    'public methods
    init: tubiExperiments_init
    getExperimentValue: tubiExperiments_getExperimentValue
    getExperimentTracking: tubiExperiments_getExperimentTracking
    getExperimentResource: tubiExperiments_getExperimentResource

    'private methods
    getNamespaces: tubiExperiments_getNamespaces_
    parseNamespace: tubiExperiments_parseNamespace_
    getDefault: tubiExperiments_getDefault_
    getExperiment: tubiExperiments_getExperiment_
  }
End Function


' @reqest: assocArray, a request module as returned by TubiRequest()
Function tubiExperiments_init(request)
  '//go through all the exisiting namespaces and call the backend to get the data of existing experiments
  namespaces = m.getNamespaces(request)
  allNamespaces = invalid
  
  if namespaces <> invalid
    allNamespaces = {}
  
    for each namespace in namespaces
      parsedNamespace = m.parseNamespace(namespace)

      if parsedNamespace.namespace <> invalid
        '//Note: The backend only returns one experiment per namespaces at any one time. 
        '//If there are multiple experiements under a single namespace, then the backend will choose one for the client to display
        allNamespaces[parsedNamespace.namespace] = parsedNamespace
      end if
    end for
  end if

  m.constants.experiments.info = allNamespaces
  return allNamespaces    'can return invalid
End Function


'Returns an Array of namespaces
'We expect to return an array containing a single or multiple namespace assocArrays
Function tubiExperiments_getNamespaces_(request)
  namespaces = m.defaultValues
  returnNamespaces = invalid
  url = m.constants.urls.experiments.evaluate + "?request_context.device_id=" + m.constants.deviceInfo.deviceId

  nameSpaceQuery = ""
  for each namespace in namespaces
    nameSpaceQuery = nameSpaceQuery + "&namespaces=" + namespace
  end for

  if Len(nameSpaceQuery) > 0
    '//if no experiements then do not call backend. Just return invalid return
    url = url + nameSpaceQuery
    expRequest = request.createAsync(url, "getExperiment")
    res = expRequest.runSynchronous()
    
    if res <> invalid
      parsedResults = ParseJson(res)
      if parsedResults <> invalid and parsedResults.namespace_results <> invalid
        returnNamespaces = parsedResults.namespace_results
      end if
    end if
  end if

  return returnNamespaces   'can return invalid
End Function


'Parses the namespace object returned from the backed so it can be used easier later 
'@namespaces: assocArray, an experiments namespace as returned by API 
Function tubiExperiments_parseNamespace_(namespace as Object) as Object
  'The API returns a resource JSON object that still needs to be parsed into a JSON object
  if namespace <> invalid and namespace.resource <> invalid
    namespace.resource = ParseJson(namespace.resource)
  end if
  return namespace    'can return invalid
End Function


Function tubiExperiments_getExperiment_(namespaceName as string, experimentName as string) as Object
  trackInfo = invalid
  experimentOriginalValue = invalid
  experiment = invalid

  allExperiments = m.constants.experiments.info
  if namespaceName <> invalid and experimentName <> invalid and allExperiments <> invalid
    possibleExperiment = allExperiments[namespaceName]
    if possibleExperiment <> invalid and possibleExperiment.experiment_result <> invalid and possibleExperiment.experiment_result.experiment_name <> invalid
      '//Make sure everything exists before proceeding
      if possibleExperiment.experiment_result.experiment_name = experimentName
        '//We found the desired experiment
        experiment = possibleExperiment
      end if
    end if 
  end if

  return experiment
End Function


Function tubiExperiments_getExperimentTracking(namespaceName as string, experimentName as string) as Object
  treatmentName = invalid
  trackInfo = invalid
  saltId = invalid

  experiment = m.getExperiment(namespaceName, experimentName)
  if experiment <> invalid 

    if experiment.experiment_result <> invalid and experiment.experiment_result.treatment <> invalid
      treatmentName = experiment.experiment_result.treatment
      saltId = experiment.experiment_result.segment
    end if

    if treatmentName <> invalid
      'trackInfo keys can be sent as params to TubiTracking().trackUserEvent(), in order to make a tracking API call
      'trackInfo can be set as an AA on the trackEvent field in the trackingLoggingTask, in order to make a tracking API call
      trackInfo = {
        type: "exposure"
        values: {
          experiment: {
            namespace: namespaceName
            name: experimentName
            salt: saltId
            parameter_name: experimentName
            parameter_value: treatmentName
          }
        }
      }
    end if
  end if

  return trackInfo
End Function


Function tubiExperiments_getExperimentValue(namespaceName as string, experimentName as string) as Object
  experimentValue = invalid
  treatmentName = invalid

  experiment = m.getExperiment(namespaceName, experimentName)
  if experiment <> invalid 
    if experiment.experiment_result <> invalid and experiment.experiment_result.treatment <> invalid
      treatmentName = experiment.experiment_result.treatment
    end if
    
    if (type(treatmentName) = "roString" or type(treatmentName) = "String") and treatmentName = "control"
      treatmentName = m.getDefault(namespaceName, experimentName)
    end if
  end if

  if treatmentName = invalid
    experimentValue = m.getDefault(namespaceName, experimentName)
  else 
    experimentValue = treatmentName
  end if

  return experimentValue
End Function


' tubiExperiments_getExperimentResource
' 
' Get more info about the experiment. This is an associative array that is defined when the experiment is set up on the popper server
' The AA can include anything and be formatted in anyway. It depends on how you set up the experiment on the popper server.
Function tubiExperiments_getExperimentResource(namespaceName as string, experimentName as string) as Object
  oReturn = invalid

  experiment = m.getExperiment(namespaceName, experimentName)
  if experiment <> invalid 
    oReturn = experiment.resource
  end if

  return oReturn
End Function


'This function gets the appropriate default value from a repository of default values for experiments.
'If we can't find an experiment from the Popper server response, we'll go here to get the default value for that experiment
'
'@namespaceName: string, the name of the namespace in which we will find the experiment
'@experimentName: string, the name of the experiment as found in the experiment definition
Function tubiExperiments_getDefault_(namespaceName as string, experimentName as string) as Object  
  defaultValue = invalid
  if namespaceName <> invalid and experimentName <> invalid
    if m.defaultValues[namespaceName] <> invalid
      defaultValue = m.defaultValues[namespaceName][experimentName]
    end if
  end if

  return defaultValue
End Function
