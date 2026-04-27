' Parsers for Pivot API responses
' API: GET /api/v1/apps?type=PIVOT
' Returns curated pivot collections (e.g., "High-Intensity Thrillers", "Trending This Week")


' Parses the successful response from the getAllPivots API call
' Converts the apps array into a RowList content structure for PivotList
' Automatically adds a static search button at the end
'
' @response: assocArray, as returned by Request.handleEvent, with .data converted from JSON to AA
'                Expected structure: { response: { data: { apps: [...] } } }
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest (unused)
' @return: ContentNode structure for RowList (rootContent → rowNode → itemNodes)
Function parsePivotsSuccess(response, _reqInfo) as Dynamic
  if response = invalid OR response.data = invalid
    return invalid
  end if

  appsArray = response.data.apps

  ' Ensure we have an array to work with
  if isArray(appsArray) = false
    appsArray = []
  end if

  ' Build content structure for RowList: rootContent → rowNode → itemNodes
  rootContent = CreateObject("roSGNode", "ContentNode")

  ' Get remove_pivots list from roku_pivots_v_1_4 experiment
  removePivots = []
  if m.statSigExperiments <> invalid
    pivotExperiment = m.statSigExperiments.getExperimentResource("", "roku_pivots_v_1_4")
    if pivotExperiment <> invalid AND isNonEmptyArray(pivotExperiment.remove_pivots) = true
      removePivots = pivotExperiment.remove_pivots
    end if
  end if

  pivotNodes = []
  for each appAA in appsArray
    shouldRemove = isNonEmptyArray(removePivots) = true AND isAA(appAA) = true AND isString(appAA.id) = true AND arrayIncludes(removePivots, appAA.id)
    if shouldRemove = false
      pivotNode = parsePivotApp(appAA)
      if pivotNode <> invalid
        pivotNodes.push(pivotNode)
      end if
    end if
  end for

  ' Add static search button at the end
  searchNode = createSearchPivotNode()
  if searchNode <> invalid
    pivotNodes.push(searchNode)
  end if

  rootContent.update({
    children: [
      {
        subType: "ContentNode"
        children: pivotNodes
      }
    ]
  }, true)

  return rootContent
End Function


' Parses a single pivot app object into a node
' Validates all fields and provides safe defaults to prevent crashes
'
' @appAA: assocArray, a single pivot app object from the API response
'         Expected structure: {
'           id: string - unique pivot identifier (e.g., "tubitv_pivot_trending_this_week")
'           title: string - display title for the pivot
'           description: string - pivot description
'           type: string - always "PIVOT" for pivot apps
'           genres: array - list of genre identifiers
'           tags: array - list of tag identifiers
'           images: assocarray - image assets for the pivot
'         }
' @return: AssocArray with validated pivot properties, or invalid if appAA is not valid
Function parsePivotApp(appAA) as Dynamic
  if isAA(appAA) = false
    return invalid
  end if

  ' Build return object with validated/defaulted fields (avoids mutating input)
  pivotId = ""
  if isString(appAA.id) then pivotId = appAA.id

  title = ""
  if isString(appAA.title) then title = appAA.title

  description = ""
  if isString(appAA.description) then description = appAA.description

  pivotType = ""
  if isString(appAA.type) then pivotType = appAA.type

  genres = []
  if isArray(appAA.genres) then genres = appAA.genres

  tags = []
  if isArray(appAA.tags) then tags = appAA.tags

  images = {
    "background": "pkg:/images/pivot-background-$$RES$$.9.png"
  }
  if isAA(appAA.images)
    images.append(appAA.images)
  end if

  return {
    "id": pivotId
    "title": title
    "description": description
    "type": pivotType
    "genres": genres
    "tags": tags
    "images": images
    "isPrimaryButton": true
  }
End Function


' Creates a static search pivot node
' Uses the existing sideNavSearch icon from side navigation
' @return: AssocArray with search button properties
Function createSearchPivotNode() as Dynamic
  return {
    "id": "search"
    "title": getTranslation("menu_search")
    "description": "" ' Internal-only field, not user-facing
    "type": "SEARCH"
    "genres": []
    "tags": []
    "images": {}
    "isPrimaryButton": true
    "iconUrl": "pkg:/images/sideNavSearch.webp"
  }
End Function


' Parses pivot container responses, delegating to parseHomeScreenContentSuccess
' for standard translation and extracting optional app.images for the screen
' @fullResponse: assocArray, raw response with .response.data containing the parsed JSON
' @reqInfo: AA, request context
Function parsePivotContainersSuccess(fullResponse, reqInfo)
  convertedMetadata = parseHomeScreenContentSuccess(fullResponse, reqInfo)

  parsedResponse = fullResponse.response.data
  if parsedResponse.app <> invalid
    appFields = {}

    if isString(parsedResponse.app.title) then appFields.appTitle = parsedResponse.app.title

    if parsedResponse.app.images <> invalid
      appImages = parsedResponse.app.images

      if isNonEmptyArray(appImages.logo) then appFields.logo = appImages.logo[0]
      if isNonEmptyArray(appImages.hero) then appFields.background = appImages.hero[0]
      if isNonEmptyArray(appImages.title_art) then appFields.titleArt = appImages.title_art[0]
    end if

    convertedMetadata.update(appFields, true)
  end if

  return convertedMetadata
End Function