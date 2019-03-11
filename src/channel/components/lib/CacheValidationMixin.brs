' Helper to determine if content is out of the cache window and should be refreshed
' @content: roSGNode, ContentNode of the content that is being checked. This can be a TubiContentNode, CategoryContentNode, etc.
Function shouldRefresh(content)
  if content = invalid or content.validUntil = invalid or content.validUntil < UpTime(0)
    return true
  end if
  return false
End Function