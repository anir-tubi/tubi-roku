Function TubiExperiments(constants) as Object

  return {
    constants: constants

    ' Every namespace needs to have a default resource AA
    ' Default resources are always used in case that the experiment API doesn't return a response
    ' with our experiment.
    '
    'example of how defaultResources should be constructed
    ' defaultResources = {
    '   UserNamespace: {
    '     single_row: {background_color: "00FF12"}
    '     livetv: {opacity: .6}
    '   }
    '   RokuNamespace: {
    '       background_color: {background_color: "FF0000"}
    '   }
    ' }
    '
    ' For more info on on the experiment backend, see: https://github.com/adRise/popper-config
    defaultResources: {
      roku_discovery_v3: {
        roku_discovery_row_v3: {"position" : -2, "has_tvshows" : false, "has_movies" : false}
      }
      roku_initial_content_type_selector_icts: {
        roku_initial_content_type_selector_icts_v3: {"icts_menu_option": "movies_tv_separate"} ' valid values are : "no_icts", "movies_tv_combined", "movies_tv_separate", "no_espanol"
      }
      roku_instant_resume: {
        roku_instant_resume_v2: {"enabled": true}
      }  
      roku_postplayexp_aptimer_5sec: {
        roku_postplayexp_aptimer_10sec: {"ap_timer": 30}  
      }  

      roku_linear_countdown_timer: {
        roku_linear_countdown_timer_v1: {"countdown_timer": 10}
      }

      roku_email_prefill_login_age_gate:{
        roku_email_prefill_login_age_gate_v1: {"enabled": true}
      }     

      roku_sports: {
        roku_sports_v1: {"enabled": true}
      }
    
      roku_skip_intro:{
        roku_skip_intro_v2: {"skip_button_type": "transparent"} 'valid values are : "no_button", "fill", "transparent"
      }

      roku_instant_resume_tweak: {
        roku_instant_resume_tweak_v1: {"enabled": false}
      }

      roku_homepage_endpoint:{
        roku_homepage_endpoint_v1: {"endpoint": "matrix"} 'valid values are : "tensor", "matrix"
      }
    }
    
    'public methods
    init: tubiExperiments_init
    getExperimentTracking: tubiExperiments_getExperimentTracking
    getExperimentResource: tubiExperiments_getExperimentResource
    getNamespaceRequest: tubiExperiments_getNamespaceRequest
    handleAsyncNamespaceResponse: tubiExperiments_handleAsyncNamespaceResponse

    'private methods
    getNamespaces: tubiExperiments_getNamespaces
    parseNamespace: tubiExperiments_parseNamespace
    getDefaultResource: tubiExperiments_getDefaultResource
    getExperiment: tubiExperiments_getExperiment
    handleNamespaceResponse: tubiExperiments_handleNamespaceResponse
    mapNamespaces: tubiExperiments_mapNamespaces
  }
End Function


' @reqest: assocArray, a request module as returned by TubiRequest()
Function tubiExperiments_init(request)
  '//go through all the exisiting namespaces and call the backend to get the data of existing experiments
  namespaces = m.getNamespaces(request)
  allNamespaces = invalid
  
  if namespaces <> invalid
    allNamespaces = m.mapNamespaces(namespaces)
  end if

  m.constants.experiments.info = allNamespaces
  return allNamespaces    'can return invalid
End Function


' Returns an Array of namespaces, synchronously
' We expect to return an array containing a single or multiple namespace assocArrays
' @reqest: assocArray, a request module as returned by TubiRequest()
Function tubiExperiments_getNamespaces(request)
  returnNamespaces = invalid
  req = m.getNamespaceRequest(request)
  if req <> invalid
    res = req.runSynchronous()
    if res <> invalid
      returnNamespaces = m.handleNamespaceResponse(res)
    end if
  end if

  return returnNamespaces   'can return invalid
End Function


' returns a request object that can be run asynchronously or synchronously - but may return invalid
' @reqest: assocArray, a request module as returned by TubiRequest()
Function tubiExperiments_getNamespaceRequest(request)
  expRequest = invalid
  namespaces = m.defaultResources
  returnNamespaces = invalid
  url = m.constants.urls.experiments.evaluate + "?request_context.device_id=" + m.constants.deviceInfo.deviceId

  nameSpaceQuery = ""
  for each namespace in namespaces
    nameSpaceQuery = nameSpaceQuery + "&namespaces=" + namespace
  end for

  if Len(nameSpaceQuery) > 0
    '//if no experiments then do not call create request. Just return invalid
    url = url + nameSpaceQuery
    expRequest = request.createAsync(url, "getExperiment")
  end if

  return expRequest 'may return invalid
End Function


' @resData: string, the response string - expect JSON.
Function tubiExperiments_handleNamespaceResponse(resData)
  namespaces = invalid
  parsedResults = ParseJson(resData)
  if parsedResults <> invalid and parsedResults.namespace_results <> invalid
    namespaces = parsedResults.namespace_results
  end if

  return namespaces
End Function


' wraps handleNamespaceResponse and mapNamespaces
' @resData: string, the response string - expect JSON.
Function tubiExperiments_handleAsyncNamespaceResponse(resData)
  experimentInfo = invalid

  if resData <> ""
    namespaces = m.handleNamespaceResponse(resData)
    experimentInfo = m.mapNamespaces(namespaces)
  end if

  return experimentInfo
End Function


' returns a map of namespace with the namespace names as keys
' @namespaces: an array of namespaces as returned by the popper API under the key "namespace_results"
Function tubiExperiments_mapNamespaces(namespaces)
  allNamespaces = {}

  for each namespace in namespaces
    parsedNamespace = m.parseNamespace(namespace)

    if parsedNamespace.namespace <> invalid
      '//Note: The backend only returns one experiment per namespaces at any one time.
      '//If there are multiple experiments under a single namespace, then the backend will choose one for the client to display
      allNamespaces[parsedNamespace.namespace] = parsedNamespace
    end if
  end for

  return allNamespaces
End Function



'Parses the namespace object returned from the backed so it can be used easier later 
'@namespaces: assocArray, an experiments namespace as returned by API 
Function tubiExperiments_parseNamespace(namespace as Object) as Object
  'The API returns a resource JSON object that still needs to be parsed into a JSON object
  if namespace <> invalid and namespace.resource <> invalid
    namespace.resource = ParseJson(namespace.resource)
  end if
  return namespace    'can return invalid
End Function


Function tubiExperiments_getExperiment(namespaceName as string, experimentName as string) as Object
  whitelistedExperimentName = "qa." + experimentName

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
      else if possibleExperiment.experiment_result.experiment_name = whitelistedExperimentName
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
    if experiment.experiment_result <> invalid
      if experiment.experiment_result.treatment <> invalid
        treatmentName = experiment.experiment_result.treatment
        saltId = experiment.experiment_result.segment
      end if

      if experiment.experiment_result.experiment_name <> invalid
        experimentName = experiment.experiment_result.experiment_name
      end if
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


' tubiExperiments_getExperimentResource
' 
' Get more info about the experiment. This is an associative array that is defined when the experiment is set up on the popper server
' The AA can include anything and be formatted in anyway. It depends on how you set up the experiment on the popper server.
Function tubiExperiments_getExperimentResource(namespaceName as string, experimentName as string) as Object
  
  oReturn = m.getDefaultResource(namespaceName, experimentName)
  experiment = m.getExperiment(namespaceName, experimentName)
  if experiment <> invalid and experiment.resource <> invalid
    oReturn = experiment.resource
  end if  

  return oReturn 
End Function


' This function gets the appropriate default resource from a repository of default resources for experiments.
' If we can't find an experiment from the Popper server response, we'll go here to get the default resource for that experiment.
' If there is no default resource, then this function can return invalid.
'
'@namespaceName: string, the name of the namespace in which we will find the experiment
'@experimentName: string, the name of the experiment as found in the experiment definition
Function tubiExperiments_getDefaultResource(namespaceName as string, experimentName as string) as Object  
  defaultResource = invalid
  if namespaceName <> invalid and experimentName <> invalid
    if m.defaultResources[namespaceName] <> invalid
      defaultResource = m.defaultResources[namespaceName][experimentName]
    end if
  end if

  return defaultResource
End Function
