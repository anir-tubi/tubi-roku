' Helper to determine if content is out of the cache window and should be refreshed
' @content: roSGNode, ContentNode of the content that is being checked. This can be a TubiContentNode, CategoryContentNode, etc.
Function shouldRefresh(content)
  if content <> invalid
    validUntil = content.validUntil
    ' -1 indicates we will never refresh it. Used for client generated content.
    if (validUntil = invalid OR validUntil < UpTime(0)) AND validUntil <> -1
      return true
    end if
  end if
  return false
End Function