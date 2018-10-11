Function init()
  m.top.functionName = "execGetDetailMetadata"
End Function

'
' Simultaneously request content detail and related items.
'
' Note that we raise errors if content detail fails, but ignore
' them if related items fails
'
Function execGetDetailMetadata() As Void
  tubiLog("DetailMetadataTask.execGetDetailMetadata")
  if type(m.top.request) <> "roAssociativeArray" or m.top.request.contentId = invalid
    m.top.error = {
      code: -1
      data: ""
      failReason: "Content was invalid"
    }
    return
  end if

  ' request setup
  constants = m.global.constants
  RequestModule = TubiRequest()
  AuthModule = TubiAuth(constants, RequestModule)
  cms = CmsApi(constants, RequestModule, AuthModule)
  translate = TubiMetadataTranslate(constants)
  port = CreateObject("roMessagePort")

  contentReq = invalid
  if m.top.request.getContent = true
    tubiLog("DetailMetadataTask getting content for " + m.top.request.contentId)
    contentReq = cms.singleContentReq(m.top.request.contentId, true)
    contentReq.start(port)
  end if

  relatedReq = invalid
  if m.top.request.getRelated = true
    tubiLog("DetailMetadataTask getting related (you may also like) for " + m.top.request.contentId)
    relatedReq = cms.relatedContentReq(m.top.request.contentId)
    relatedReq.start(port)
  end if

  thumbnailsReq = invalid
  if m.top.request.getThumbnails = true
    tubiLog("DetailMetadataTask getting sprites for " + m.top.request.contentId)
    thumbnailsReq = cms.thumbnailsReq(m.top.request.contentId)
    thumbnailsReq.start(port)
  end if

  ' Wait for all responses
  contentResult = invalid
  relatedResult = invalid
  thumbnailsResult = invalid
  while true
    msg = wait(0, port)
    if contentReq <> invalid and contentResult = invalid
      contentResult = contentReq.handleEvent(msg)
    end if
    if relatedReq <> invalid and relatedResult = invalid
      relatedResult = relatedReq.handleEvent(msg)
    end if
    if thumbnailsReq <> invalid and thumbnailsResult = invalid
      thumbnailsResult = thumbnailsReq.handleEvent(msg)
    end if
    if (contentReq = invalid or contentResult <> invalid) and (relatedReq = invalid or relatedResult <> invalid) and (thumbnailsReq = invalid or thumbnailsResult <> invalid)
      exit while
    end if
  end while

  updatedContent = invalid

  ' Parse results
  if contentReq <> invalid
    if contentResult <> invalid and contentResult.response <> invalid and success(contentResult.response.code)
      parsed = ParseJSON(contentResult.response.data)
      if parsed = invalid then
        tubiLog("DetailMetadataTask failed to parse JSON response")
        m.top.error = contentResult.response
      else
        updatedContent = CreateObject("roSGNode", "TubiContentNode")
        translate.translateRecursive(parsed, updatedContent)
      end if
    else
      code = -1
      if contentResult <> invalid and contentResult.response <> invalid
        code = contentResult.response.code
      end if
      m.top.error = {
        code: code
        data: ""
        failReason: "Result is invalid"
      }
    end if
  end if

  if relatedReq <> invalid
    if relatedResult <> invalid and relatedResult.response <> invalid and success(relatedResult.response.code)
      parsed = ParseJSON(relatedResult.response.data)
      if parsed = invalid then
        tubiLog("DetailMetadataTask failed to parse JSON response")
      else
        if updatedContent = invalid
          updatedContent = CreateObject("roSGNode", "TubiContentNode")
          updatedContent.id = m.top.request.contentId
        end if
        updatedContent.relatedContent = translate.translateRelatedContent(parsed)
      end if
    else
      tubiLog("DetailMetadataTask did not get valid response for related content.")
    end if
  end if

  if thumbnailsReq <> invalid
    if thumbnailsResult <> invalid and thumbnailsResult.response <> invalid and success(thumbnailsResult.response.code)
      parsed = ParseJSON(thumbnailsResult.response.data)
      spritesContentNode = invalid
      if parsed = invalid then
        tubiLog("DetailMetadataTask failed to parse JSON response")
      else
        spritesContentNode = CreateObject("roSGNode", "TubiContentNode")
        spritesContentNode.id = m.top.request.contentId
        spritesContentNode.thumbnailUrls = parsed.sprites
        spritesContentNode.thumbnailSpan = parsed.count_per_sprite
        spritesContentNode.thumbnailSize = [parsed.frame_width, parsed.height]
      end if
    else
      tubiLog("DetailMetadataTask did not get a valid response for thumbnails/sprites")
    end if
    m.top.thumbnailsResponse = spritesContentNode
  end if

  if updatedContent <> invalid
    m.top.response = updatedContent
  end if
End Function

' Helper for checking HTTP request success
Function success(code)
  return code >= 200 and code < 400
End Function