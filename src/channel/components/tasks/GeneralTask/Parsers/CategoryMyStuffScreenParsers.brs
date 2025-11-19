' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseCategoryMyStuffContentSuccess(fullResponse, reqInfo)
  tubiLog("CategoryMyStuffScreenParsers.parseCategoryMyStuffContentSuccess")
  parsedResponse = fullResponse.data
  fullJson = fullResponse.fullJson

  orientation = ""
  container = parsedResponse.container
  contents = parsedResponse.contents
  if contents.Count() > 0
    if container.id = m.constants.ui.categoryIds.history
      '//if this is the continue watching container, then ensure the orientation is landscape
      orientation = m.constants.ui.gridItemTypes.landscapeInnerMetadata
    end if

    bFullData = false
    contentMode = m.constants.ui.contentMode.homescreen

    if reqInfo <> invalid
      options = reqInfo.options
      if options <> invalid AND options.params <> invalid
        contentMode = options.params.contentMode
      end if
    end if

    isSignedInUser = false
    if reqInfo <> invalid
      isSignedInUser = reqInfo.isSignedInUser
    end if

    convertedMetadata = m.metadataTranslate.translateContainer(parsedResponse, fullJson, orientation, bFullData, contentMode, m.constants.ui.screenIds.myStuffScreen, isSignedInUser)
  else
    convertedMetadata = m.metadataTranslate.translateEmptyMyStuffContainer(parsedResponse)
  end if


  return convertedMetadata 'may return an empty container
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseMultipleContentSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data

  parentContainer = CreateObject("roSGNode", "CategoryContentNode")
  if reqInfo <> invalid AND reqInfo.categoryId <> invalid
    parentContainer.id = reqInfo.categoryId
  end if
  parentContainer.json = fullResponse.fulljson

  nValidReturn = 0
  shortestValidDuration = invalid

  for each contentId in parsedResponse
    contentTitle = parsedResponse[contentId]
    if contentTitle <> invalid
      updatedContent = CreateObject("roSGNode", "TubiContentNode")
      m.metadataTranslate.translateRecursive(contentTitle, updatedContent, reqInfo.issignedinuser)
      parentContainer.appendChild(updatedContent)

      '//Find out which of valid content title's have the shortest validUntil property
      if shortestValidDuration = invalid
        shortestValidDuration = updatedContent.validUntil
      else if updatedContent.validUntil <> invalid
        if updatedContent.validUntil < shortestValidDuration
          shortestValidDuration = updatedContent.validUntil
        end if
      end if
    end if
  end for

  '//Set the validUntil property based on the array of content titles
  if shortestValidDuration <> invalid
    nValidReturn = shortestValidDuration
  else
    nValidReturn = Uptime(0) + m.constants.cacheTimes.category
  end if

  parentContainer.validUntil = nValidReturn
  return parentContainer
End Function