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

      '//This will be added to the holdout
      roku_search_autocomplete: {
        roku_search_autocomplete_v3 : {
          default: {"enabled": true}
          holdout_control: {"enabled": false}
          holdout_winning: {"enabled": true}
        }
      }

      'This experiment will be under holdout
      roku_video_autostart_ui_refresh: {
        roku_video_autostart_ui_refresh_v1 : {
          default: {"enabled": true}
          holdout_control: {"enabled": false}
          holdout_winning: {"enabled": true}
        }
      }

      roku_add_movies_series: {
        roku_add_movies_series_uk_v2 : {
          default: {"enabled": false}
          holdout_control: {"enabled": false}
          holdout_winning: {"enabled": false}
        }
      }

      roku_async_stop: {
        roku_async_stop_v6: {
          default: {"enabled": false}
          holdout_control: {"enabled": false}
          holdout_winning: {"enabled": false}
        }
      }

      roku_player_ui_refresh: {
        ' We will run 4 overlay types. Possible values are none, variant1, variant2, variant3, variant4
        roku_ads_overlay_v1 : {
          default: {"overlay_type": "none"}
          holdout_control: {"overlay_type": "none"}
          holdout_winning: {"overlay_type": "none"}
        },
        ' We will run 4 ui control types including control. Possible values are none, variant1, variant2, variant3
        roku_player_control_ui_refresh_v2: {
          default: {"type": "none"}
          holdout_control: {"type": "none"}
          holdout_winning: {"type": "none"}
        }
      }

      'This experiment will not be under holdout and will clean up once we take the decision.
      roku_home_screen_redesign: {
        roku_home_screen_redesign_v_1_3 : {
          ' Possible values for design_type are "withDescriptionPortraitSmall", "controlReOrderContainers",  "none"
          ' Possible values for container_id are "featured" or any other tensor container id
          ' Possible values for gridItemSize are [310, 442] or [252, 360]
          ' Possible values for featuredRowPosterSize are [788, 442] or [720, 360]
          ' sample ex: default: {"design_type": "withDescriptionPortraitSmall", container_id: "featured", gridItemSize: [252, 360], featuredRowPosterSize: [720, 360] }
          ' default: {"design_type": "withDescriptionPortraitSmall", should_dim: true, gridItemSize: [310, 442], featuredRowPosterSize: [788, 442] }
          default: {"design_type": "none", container_id: "none", gridItemSize: [], featuredRowPosterSize: [] }
          holdout_control: {"design_type": "none", container_id: "none", gridItemSize: [], featuredRowPosterSize: [] }
          holdout_winning: {"design_type": "none", container_id: "none", gridItemSize: [], featuredRowPosterSize: [] }
         }
       }


      'This experiment will enable any skinAds wrapper campaigns.
      'ads_tubi_skins_v1 is enabled by default to ensure users see ads if no response from popper
      ads_tubi_skins: {
        ads_tubi_skins_v1: {
          default: {"enabled": true}
          holdout_control: {"enabled": false}
          holdout_winning: {"enabled": false}
        }
      }

      'This experiment will not be under holdout and will clean up once we take the decision.
      roku_no_change_experiment: {
        roku_no_change_experiment_v3: {
          default: {"enabled": false}
          holdout_control: {"enabled": false}
          holdout_winning: {"enabled": false}}
      }

      'This experiment will not be under holdout and will clean up once we take the decision.
      roku_bww_deeplinked_content: {
        roku_bww_deeplinked_content_v1: {
          default: {"enabled": false}
          holdout_control: {"enabled": false}
          holdout_winning: {"enabled": false}}
      }

      'Experiment to control LiveTV feature visibility
      roku_linear_no_show: {
        roku_linear_no_show_v2: {
          default: {"enabled": false}
          holdout_control: {"enabled": false}
          holdout_winning: {"enabled": false}
        }
      }

      roku_categories_screen_filters_reorder: {
        roku_categories_screen_filters_reorder_v1: {
          default: {"enabled": false}
          holdout_control: {"enabled": false}
          holdout_winning: {"enabled": false}
        }
      }

      roku_search_larger_poster:{
        roku_search_larger_poster_v1: {
          default: {"enabled": false}
          holdout_control: {"enabled": false}
          holdout_winning: {"enabled": false}
        }
      }

      roku_category_large_poster: {
        roku_category_large_poster_v1: {
          default: {"enabled": false}
          holdout_control: {"enabled": false}
          holdout_winning: {"enabled": false}
        }
      }

      roku_home_screen_fixed_focus: {
        roku_home_screen_fixed_focus_v1: {
          default: {"enabled": true}
          holdout_control: {"enabled": false}
          holdout_winning: {"enabled": false}
        }
      }

    }

    'public methods
    getExperimentTracking: tubiExperiments_getExperimentTracking
    getExperimentResource: tubiExperiments_getExperimentResource
    getNamespaceRequestInfo: tubiExperiments_getNamespaceRequestInfo
    getExperimentResult: tubiExperiments_getExperimentResult
    mapNamespaces: tubiExperiments_mapNamespaces
    getHoldOutInfo: tubiExperiments_getHoldOutInfo

    'private methods
    parseNamespace: tubiExperiments_parseNamespace
    getDefaultResource: tubiExperiments_getDefaultResource
    getExperiment: tubiExperiments_getExperiment
    getDefaultHoldOutControlResource: tubiExperiments_getDefaultHoldOutControlResource
    getDefaultHoldOutWinningResource: tubiExperiments_getDefaultHoldOutWinningResource
  }
End Function


' returns a request info required for experiments request.
Function tubiExperiments_getNamespaceRequestInfo(constants)
  requestInfo = invalid
  namespaces = m.defaultResources
  url = constants.urls.experiments.evaluate + "?request_context.device_id=" + constants.deviceInfo.deviceId
  url += "&request_context.platform=" + constants.analyticsPlatform
  url += "&request_context.country=" + UCase(constants.deviceInfo.countryCode)

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
    namespace.resource = ParseJson(namespace.resource) 'bs:disable-line 1016 1019
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
      else
        '//the namespace has been chosen under holdout experiment, so now holdout experiment becomes the desired experiment.
        holdOutInfo = possibleExperiment.experiment_result.holdout_info
        if holdOutInfo <> invalid AND holdOutInfo.in_holdout = true
          experiment = possibleExperiment
        end if
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

      'send the domain name if the experiment is in holdout instead of the namespace Name.
      holdoutInfo = experiment.experiment_result.holdout_info

      if holdoutInfo <> invalid AND holdoutInfo.in_holdout = true
        namespaceName = holdoutInfo.domain
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

    expResource = experiment.resource
    inHoldOut = false
    expResult = experiment.experiment_result

    if expResult <> invalid AND expResult.holdout_info <> invalid
      inHoldout = expResult.holdout_info.in_holdout
    end if

    if inHoldout = true
      if expResult.treatment = "status_quo"
        oReturn = m.getDefaultHoldOutControlResource(namespaceName, experimentName)
      else
        oReturn = m.getDefaultHoldOutWinningResource(namespaceName, experimentName)
      end if
    else
      oReturn = expResource
    end if

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
    if m.defaultResources[namespaceName] <> invalid AND m.defaultResources[namespaceName][experimentName] <> invalid
      defaultResource = m.defaultResources[namespaceName][experimentName]["default"]
    end if
  end if

  return defaultResource
End Function


Function tubiExperiments_getDefaultHoldOutControlResource(namespaceName as string, experimentName as string) as Object
  defaultResource = invalid
  if namespaceName <> invalid AND experimentName <> invalid
    if m.defaultResources[namespaceName] <> invalid AND m.defaultResources[namespaceName][experimentName] <> invalid
      defaultResource = m.defaultResources[namespaceName][experimentName]["holdout_control"]
    end if
  end if

  return defaultResource
End Function


Function tubiExperiments_getHoldOutInfo(namespaceName as string, experimentName as string) as Object
  holdoutInfo = {}
  experiment = m.getExperiment(namespaceName, experimentName)

  if experiment <> invalid AND experiment.experiment_result <> invalid AND experiment.experiment_result.holdout_info <> invalid
    holdoutInfo = experiment.experiment_result.holdout_info
  end if

  return holdoutInfo

End Function


Function tubiExperiments_getDefaultHoldOutWinningResource(namespaceName as string, experimentName as string) as Object
  defaultResource = invalid
  if namespaceName <> invalid AND experimentName <> invalid
    if m.defaultResources[namespaceName] <> invalid AND m.defaultResources[namespaceName][experimentName] <> invalid
      defaultResource = m.defaultResources[namespaceName][experimentName]["holdout_winning"]
    end if
  end if

  return defaultResource
End Function
