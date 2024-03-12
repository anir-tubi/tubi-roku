' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseUpdateParentalRatingSuccess(fullResponse, reqInfo)
  return {
    requestInput: reqInfo
    parsedResponse: fullResponse.data
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseGetUserSettingsSuccess(fullResponse, reqInfo)
  parsed = fullResponse.data
  result = {}
  if parsed.user_id <> invalid then
    ' Converting to string to maintain commonality from registry response
    result["userId"] = parsed.user_id.toStr()
  end if

  if parsed.profile_pic <> invalid then
    result["profilePic"] = parsed.profile_pic
  end if

  if parsed.birthday <> invalid then
    result.birthday = parsed.birthday
  end if

  if parsed.phone_number <> invalid then
    result["phoneNumber"] = parsed.phone_number
  end if

  if parsed.is_confirmed <> invalid then
    result["isConfirmed"] = parsed.is_confirmed
  end if

  if parsed.has_password <> invalid then
    result["hasPassword"] = parsed.has_password
  end if

  if parsed.parental_rating <> invalid
    result["parentalRating"] = parsed.parental_rating
    if reqInfo.isGDPR = true then
      'Setting Parental Control option to Older Kids for nz & uk region, if the parental option was selected as Teens from other region
      if parsed.parental_rating = 2
        result["parentalRating"] = 1
      end if
    end if
  end if

  result.email = ""
  if parsed.email <> invalid
    result.email = parsed.email
  end if

  result.name = ""
  if parsed.name <> invalid
    result.name = parsed.name
  end if

  result["firstName"] = ""
  if parsed.first_name <> invalid
    result["firstName"] = parsed.first_name
  end if

  result["lastName"] = ""
  if parsed.last_name <> invalid
    result["lastName"] = parsed.last_name
  end if

  if parsed.has_age <> invalid
    result["hasAge"] = parsed.has_age
  end if

  return result
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseGetContentRatingSuccess(fullResponse, reqInfo)
  data = fullResponse.data
  nodes = []

  if isArray(data.data) then
    for each contentId in data.data
      node = createObject("roSGNode", "LikeContentNode")
      node.id = contentId
      node.state = reqInfo.options.params.type
      nodes.push(node)
    end for
  end if

  return {
    "nodes": nodes
    "nextPageId": data.next
  }
End Function
