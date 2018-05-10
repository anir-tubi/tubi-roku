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

  tubiLog("DetailMetadataTask getting content for " + m.top.request.contentId)
  ' request setup
  constants = m.global.constants
  RequestModule = TubiRequest()
  AuthModule = TubiAuth(constants, RequestModule)
  cms = CmsApi(constants, RequestModule, AuthModule)
  translate = TubiMetadataTranslate(constants)
  port = CreateObject("roMessagePort")

  contentReq = cms.singleContentReq(m.top.request.contentId)
  contentReq.start(port)

  relatedReq = invalid
  if m.top.request.getRelated = true
    relatedReq = cms.relatedContentReq(m.top.request.contentId)
    relatedReq.start(port)
  end if

  thumbnailsReq = invalid
  if m.top.request.getThumbnails = true
    thumbnailsReq = cms.thumbnailsReq(m.top.request.contentId)
    thumbnailsReq.start(port)
  end if

  ' Wait for all responses
  contentResult = invalid
  relatedResult = invalid
  thumbnailsResult = invalid
  while true
    msg = wait(0, port)
    if contentResult = invalid
      contentResult = contentReq.handleEvent(msg)
    end if
    if relatedReq <> invalid and relatedResult = invalid
      relatedResult = relatedReq.handleEvent(msg)
    end if
    if thumbnailsReq <> invalid and thumbnailsResult = invalid
      thumbnailsResult = thumbnailsReq.handleEvent(msg)
    end if
    if contentResult <> invalid and (relatedReq = invalid or relatedResult <> invalid) and (thumbnailsReq = invalid or thumbnailsResult <> invalid)
      exit while
    end if
  end while

  ' Parse results
  if contentResult <> invalid and contentResult.response <> invalid and success(contentResult.response.code)
    parsed = ParseJSON(contentResult.response.data)
    if parsed = invalid then
      tubiLog("DetailMetadataTask failed to parse JSON response")
      m.top.error = contentResult.response
    else
      detail = CreateObject("roSGNode", "TubiContentNode")
      translate.translateRecursive(parsed, detail)

      if relatedResult <> invalid and relatedResult.response <> invalid and success(relatedResult.response.code)
        parsed = ParseJSON(relatedResult.response.data)
        if parsed = invalid then
          tubiLog("DetailMetadataTask failed to parse JSON response")
        else
          detail.relatedContent = translate.translateRelatedContent(parsed)
        end if
      end if

      if thumbnailsResult <> invalid and thumbnailsResult.response <> invalid and success(thumbnailsResult.response.code)
        parsed = ParseJSON(thumbnailsResult.response.data)
        if parsed = invalid then
          tubiLog("DetailMetadataTask failed to parse JSON response")
        else
          detail.thumbnailUrls = parsed.sprites
          detail.thumbnailSpan = parsed.count_per_sprite
          detail.thumbnailSize = [parsed.frame_width, parsed.height]
        end if
      end if
      m.top.response = detail
    end if
  else
    m.top.error = {
      code: contentResult.response.code
      data: ""
      failReason: "Result is invalid"
    }
  end if
End Function

' Helper for checking HTTP request success
Function success(code)
  return code >= 200 and code < 400
End Function