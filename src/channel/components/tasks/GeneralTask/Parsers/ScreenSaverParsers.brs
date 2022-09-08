' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseGetScreenSaverContainerSuccess(fullResponse, _reqInfo)
  items = []
  data = fullResponse.data
  container = data.container
  contents = data.contents

  if isAA(container) = true AND isAA(contents) = true then
    itemIds = container.children
    if isArray(itemIds) = false then
      itemIds = []
    end if

    for each itemId in itemIds
      if isString(itemId) = true then
        item = validateAndBuildItem(contents[itemId])
        if item <> invalid then
          items.push(item)
        end if
      end if
    end for
  end if

  convertedMetadata = createObject("roSGNode", "Node")
  convertedMetadata.update({
    "id": container.id
    "items": items
  }, true)
  return convertedMetadata
End Function


Function validateAndBuildItem(item)
  images = item.images
  if isAA(images) = false then
    return invalid
  end if

  title = item.title
  if isString(title) = false then
    return invalid
  end if

  tags = item.tags
  if isArray(tags) = false then
    return invalid
  end if

  hasAllowedRating = false
  for each rating in item.ratings
    code = rating.code
    if isString(code) = true then
      allowedCodes = [
        "TV-14"
        "TV-PG"
        "TV-G"
        "TV-Y7_FV"
        "TV-Y7"
        "TV-Y"
        "PG-13"
        "PG"
        "G"
      ]
      for each allowedCode in allowedCodes
        if code = allowedCode then
          hasAllowedRating = true
          exit for
        end if
      end for
    end if
  end for

  if hasAllowedRating = false then
    return invalid
  end if

  ' Only want to allow known types in case a new incompatible type is added or linear is encountered
  if item.type = "v" OR item.type = "s" then
    return {
      "images": images
      "title": title
      "tags": tags
    }
  else
    return invalid
  end if
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseGetScreenSaverHomeScreenContainerIdsSuccess(fullResponse, _reqInfo)
  containerIds = []
  containers = fullResponse.data.containers

  if isArray(containers) = true then
    for each container in containers
      containerId = container.id
      if isString(containerId) = true then
        containerIds.push(containerId)
      end if
    end for
  end if

  convertedMetadata = createObject("roSGNode", "Node")
  convertedMetadata.update({
    "containerIds": containerIds
  }, true)
  return convertedMetadata
End Function
