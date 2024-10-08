Function TubiExperiments(experimentsInfo) as Object
  return {
    experimentsInfo: experimentsInfo

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

      roku_screensaver: {
        roku_screensaver_v2 : {"enabled": false}
      }

      roku_category_redesign: {
        roku_category_redesign_v2: {"enabled": true}
      }

      roku_autoplay_timer: {
        roku_autoplay_timer_v1 : {"enabled": false}
      }
      
      roku_linear_favorites: {
        roku_linear_favorites_v1: {"enabled": false}
      }

      roku_async_stop: {
        roku_async_stop_v5: {"enabled": false}
      }

      roku_cw_consent_existing_user: {
        roku_cw_consent_existing_user_after_playback_v4: {"enabled": false}
      }

      roku_linear_player_view: {
        roku_linear_player_view_v2: {"enabled": false}
      }

      roku_registration_player_signup_save_progress: {
        roku_registration_player_signup_save_progress_exit_prompt_v2: {"enabled": true}
      }

      roku_horizontal_menu:{
        roku_horizontal_menu_v2: {"enabled": false}
      }

      roku_detect_preroll_from_cue_point: {
        roku_detect_preroll_from_cue_point_v1: {"enabled": false}
      }

      roku_spotlight_carousel: {
        roku_spotlight_carousel_v1 : {"enabled": false}
      }

      roku_player_client_log: {
        roku_player_client_log_v1: {"enabled": false}
      }

    }

    'public methods
    getExperimentTracking: tubiExperiments_getExperimentTracking
    getExperimentResource: tubiExperiments_getExperimentResource
    getNamespaceRequestInfo: tubiExperiments_getNamespaceRequestInfo
    getExperimentResult: tubiExperiments_getExperimentResult
    mapNamespaces: tubiExperiments_mapNamespaces

    'private methods
    parseNamespace: tubiExperiments_parseNamespace
    getDefaultResource: tubiExperiments_getDefaultResource
    getExperiment: tubiExperiments_getExperiment
  }
End Function


' returns a request info required for experiments request.
Function tubiExperiments_getNamespaceRequestInfo(constants)
  requestInfo = invalid
  namespaces = m.defaultResources
  url = constants.urls.experiments.evaluate + "?request_context.device_id=" + constants.deviceInfo.deviceId

  nameSpaceQuery = ""
  for each namespace in namespaces
    nameSpaceQuery = nameSpaceQuery + "&namespaces=" + namespace
  end for

  if Len(nameSpaceQuery) > 0
    '//if no experiments then do not call create request. Just return invalid
    url = url + nameSpaceQuery
    requestInfo = {
      url: url
      requestType: constants.reqNames.getNamespaces
      responseType: "assocarray"
    }
  end if

  return requestInfo 'may return invalid
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
  if namespace <> invalid AND namespace.resource <> invalid
    namespace.resource = ParseJson(namespace.resource) 'bs:disable-line 1016 1019 1056
  end if
  return namespace    'can return invalid
End Function


Function tubiExperiments_getExperiment(namespaceName as string, experimentName as string) as Object
  whitelistedExperimentName = "qa." + experimentName

  experiment = invalid

  allExperiments = m.experimentsInfo
  if namespaceName <> invalid AND experimentName <> invalid AND allExperiments <> invalid
    possibleExperiment = allExperiments[namespaceName]
    if possibleExperiment <> invalid AND possibleExperiment.experiment_result <> invalid AND possibleExperiment.experiment_result.experiment_name <> invalid
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


' tubiExperiments_getExperimentResult
'
' namespaceName: string, namespace of experiment
' experimentName: string, name of experiment
'
' returns the experiment result in assocarray if experiment is running in popper, or else returns invalid
'   eg. "experiment_name": "qa.roku_in_pod_stitching_v2",
'       "treatment": "in_pod_stitching",
'       "segment": "WHITELISTED"
' this result can be used in youbora requests
Function tubiExperiments_getExperimentResult(namespaceName as string, experimentName as string) as Object
  experimentResult = invalid
  experiment = m.getExperiment(namespaceName, experimentName)

  if experiment <> invalid
    experimentResult = experiment.experiment_result
  end if

  return experimentResult
End Function


' tubiExperiments_getExperimentResource
'
' Get more info about the experiment. This is an associative array that is defined when the experiment is set up on the popper server
' The AA can include anything and be formatted in anyway. It depends on how you set up the experiment on the popper server.
Function tubiExperiments_getExperimentResource(namespaceName as string, experimentName as string) as Object

  oReturn = m.getDefaultResource(namespaceName, experimentName)
  experiment = m.getExperiment(namespaceName, experimentName)
  if experiment <> invalid AND experiment.resource <> invalid
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
  if namespaceName <> invalid AND experimentName <> invalid
    if m.defaultResources[namespaceName] <> invalid
      defaultResource = m.defaultResources[namespaceName][experimentName]
    end if
  end if

  return defaultResource
End Function
