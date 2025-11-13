' The structure we receive from the backend is different from the one we use in the app. This function converts the backend structure to the app structure.
Function convertClientErrorConfig(clientErrorConfig)
  ' Only thing we are changing is services property
  services = clientErrorConfig.services
  clientErrorConfig.delete("services")
  urlSpecificConfig = {}

  for each serviceName in services
    service = services[serviceName]
    if isAA(service) = true then
      routes = service.routes
      if isAA(routes) = true then
        for each routePath in routes
          foundUrl = invalid
          possibleUrls = m.constants.urls[serviceName]
          if isString(possibleUrls) = true then
            if possibleUrls.instr(routePath) >= 0 then
              foundUrl = possibleUrls
            end if
          else if isAA(possibleUrls) = true then
            for each key in possibleUrls
              possibleUrl = possibleUrls[key]
              if isString(possibleUrl) = true AND possibleUrl.instr(routePath) >= 0 then
                foundUrl = possibleUrl
                exit for
              end if
            end for
          end if

          if foundUrl <> invalid then
            urlSpecificConfig[foundUrl] = routes[routePath]
          else
            tubiLog("Could not find a matching url for route " + routePath + " in service " + serviceName)
          end if
        end for
      end if
    end if
  end for

  clientErrorConfig["urlSpecificConfig"] = urlSpecificConfig

  ' Make sure we always have retry_strategies so we don't have to do a check for it for every request
  if isAA(clientErrorConfig.retry_strategies) = false then
    clientErrorConfig.retry_strategies = {}
  end if

  ' Make sure we always have conditions so we don't have to do a check for it for every request
  if isAA(clientErrorConfig.conditions) = false then
    clientErrorConfig.conditions = {}
  end if

  return clientErrorConfig
End Function


' This function determines if a network request should be retried after an error and if so, how long to wait before retrying. Since current config does not tell us how long to wait, we are currently returning 0 and allowing our code to handle when to retry.
' @param clientErrorConfig, assocArray: The client error config object
' @param url, string: The url of the request that failed
' @param method, string: The method of the request that failed IE 'GET', 'POST', 'PUT', 'DELETE', 'PATCH'
' @param statusCode, string: The status code of the failed request if we received a response from the server. Other types might be added in the future for failures such as time out or loosing connection.
' @param responseHeaders, AssocArray: The headers of the request that failed
' @param responseBody, string: The body of the failed request
' @param retriesAttempted, integer: The number of times this request has been retried so far
' @return integer: -1 if the request should not be retried, 0 if the request should be retried immediately, or a positive integer representing the number of seconds to wait before retrying.
Function clientErrorConfigCheckIfShouldRetryAfter(clientErrorConfig, url, method, statusCode, responseHeaders, responseBody, retriesAttempted)
  ' If the client error config is invalid, we can't do anything so default to never retrying
  if isAA(clientErrorConfig) = false then
    return -1
  end if

  method = UCase(method)

  matchedConfig = invalid

  ' Check for url specific config
  urlSpecificConfig = clientErrorConfig.urlSpecificConfig[url]
  if isAA(urlSpecificConfig) = true then
    ' Check if we have a matching method for this url and the request's method
    urlSpecificConfigForMethod = clientErrorConfigCheckIfPartMatches(urlSpecificConfig[method], statusCode)
    if urlSpecificConfigForMethod <> invalid then
      matchedConfig = urlSpecificConfigForMethod
    else
      ' If we don't have a matching method then check the url config directly for a match
      urlSpecificMatchingConfig = clientErrorConfigCheckIfPartMatches(urlSpecificConfig, statusCode)
      if urlSpecificMatchingConfig <> invalid then
        matchedConfig = urlSpecificMatchingConfig
      end if
    end if
  end if

  if matchedConfig = invalid then
    ' If no matched config yet then check against defaults
    matchedConfig = clientErrorConfigCheckIfPartMatches(clientErrorConfig.default, statusCode)
  end if

  if matchedConfig <> invalid then
    ' If there are conditions for the matched config check if any of them match
    if isArray(matchedConfig.conditions) = true then
      jsonBody = parseJsonFromNetworkRequest(responseHeaders, responseBody, {})
      for each condition in matchedConfig.conditions
        conditionConfig = clientErrorConfig.conditions[condition]
        if isAA(conditionConfig) = true AND isAA(jsonBody) = true then
          allConditionChecksMet = true
          if isString(conditionConfig.response_code) = true then
            if isString(jsonBody.code) <> true OR UCase(jsonBody.code) <> UCase(conditionConfig.response_code) then
              allConditionChecksMet = false
            end if
          end if

          ' Add support for header checks in the future here

          if allConditionChecksMet = true then
            ' If all condition checks were met go ahead and switch to this condition config
            matchedConfig = conditionConfig
            exit for
          end if
        end if
      end for
    end if

    ' Make sure we have a retry_strategy
    if isString(matchedConfig.retry_strategy) = true then
      if matchedConfig.retry_strategy = "new_token" then

        ' ContentController uses convertClientErrorConfig but does not use this method so need to ignore getUpdatedAuth not existing
        ' bs:disable-next-line 1001 LINT1001
        if isFunction(getUpdatedAuth) = true then
          getUpdatedAuth() 'bs:disable-line 1140 LINT1001
        else
          print "getUpdatedAuth is not in scope"
        end if
      else if matchedConfig.retry_strategy = "sign_off" then
        ' ContentController uses convertClientErrorConfig but does not use this method so need to ignore logoutAndRestartApp not existing
        ' bs:disable-next-line 1001 LINT1001
        if isFunction(logoutAndRestartApp) = true then
          logoutAndRestartApp() 'bs:disable-line 1140 LINT1001
        else
          print "logoutAndRestartApp is not in scope"
        end if
      end if

      retryStrategy = clientErrorConfig.retry_strategies[matchedConfig.retry_strategy]
      if isAA(retryStrategy) = true AND retryStrategy.max_retries <> invalid then
        if retriesAttempted >= retryStrategy.max_retries then
          ' If we have already retried the max number of times then we don't retry
          return -1
        else
          ' Built based off the logic here https://www.notion.so/tubi/Client-Error-Handling-Spec-V2-11472557e920809da609ed59476d52f3
          delay = 0

          ' If we have a retry base then we set that to start
          if isNumber(retryStrategy.retry_base_millis) = true then
            delay = retryStrategy.retry_base_millis
          end if

          ' If an exponent is given then we multiply the delay by the exponent to the power of the number of retries attempted
          if isNumber(retryStrategy.retry_exponent) = true then
            delay = (retryStrategy.retry_exponent ^ retriesAttempted) * delay
          end if

          ' We want to enforce that delay will be no longer than retry_cap_millis if it is set
          if isNumber(retryStrategy.retry_cap_millis) = true AND delay > retryStrategy.retry_cap_millis then
            delay = retryStrategy.retry_cap_millis
          end if

          ' If we have a jitter ratio then we need to calculate a random delay between the min and max delay
          if isNumber(retryStrategy.retry_jitter_ratio) = true then
            maxDelay = delay

            ' We determine our minimum delay by taking the jitter ratio and multiplying by the delay
            minDelay = (1 - retryStrategy.retry_jitter_ratio) * delay

            ' We then take the difference between the max and min delay and add a random number between 0 and that difference to the min delay to calculate our final delay
            difference = maxDelay - minDelay
            if difference > 0 then
              delay = rnd(difference) + minDelay
            end if
          end if

          return delay
        end if
      end if
    end if
  end if

  ' If we got here we default to not retrying. This should never get hit since default.error.default should always match as long as it is there unless we get an invalid response from backend
  return -1
End Function


' To avoid writing duplicate code that checks status_codes and then errors for each object in clientErrorConfigConfigCheckIfShouldRetryAfter, we are moving the logic to this function.
' @param clientErrorConfigPart, assocArray: The client error config object part we are checking against
' @param statusCode, string: The status code of the failed request if we received a response from the server. Other types might be added in the future for failures such as time out or loosing connection.
' @return assocArray: The error config object that matched or invalid if no match was found
Function clientErrorConfigCheckIfPartMatches(clientErrorConfigPart, statusCode)
  if isAA(clientErrorConfigPart) = true then
    ' Check status codes first
    if isAA(clientErrorConfigPart.status_codes) = true AND isAA(clientErrorConfigPart.status_codes[statusCode]) = true then
      return clientErrorConfigPart.status_codes[statusCode]
    else
      ' Next check errors. For now default is the only one. If it exists in this part then we don't continue looking for a matching config
      if isAA(clientErrorConfigPart.errors) = true AND isAA(clientErrorConfigPart.errors.default) = true then
        return clientErrorConfigPart.errors.default
      end if
    end if
  end if

  return invalid
End Function


Function parseJsonFromNetworkRequest(responseHeaders, responseBody, fallback = invalid)
  if isString(responseBody) = false then
    return fallback
  end if

  if responseHeaders["Content-Type"] = invalid OR responseHeaders["Content-Type"].inStr("application/json") = -1 then
    return fallback
  end if

  json = parseJson(responseBody)
  if json = invalid then
    return fallback
  end if

  return json
End Function
