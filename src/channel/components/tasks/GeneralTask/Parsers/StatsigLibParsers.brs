' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseStatsigLibInitializeSuccess(fullResponse, reqInfo)
  response = fullResponse.data
  experimentInfo = {}

  if response <> invalid
    layerConfigs = response.layer_configs

    for each statsigKey in layerConfigs
      config = layerConfigs[statsigKey]

      namespaceName = config.name
      experimentName = config.allocated_experiment_name

      if isNonEmptyString(experimentName) = true
        experimentInfo[experimentName] = {
          statsigKey: statsigKey
          config: config
          experimentName: experimentName
          namespaceName: namespaceName
          isActive: config.is_experiment_active
          userInExperiment: config.is_user_in_experiment
          groupName: config.group_name
        }
      end if

    end for

  end if

  return experimentInfo
End Function
