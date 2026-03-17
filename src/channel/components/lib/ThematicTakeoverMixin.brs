' ThematicTakeoverMixin.brs
' Shared utility functions for thematic takeover ad handling across screens


' Clears sponsorship info from a container node
' @param container: roSGNode, the container node to clear sponsorship from
Function clearContainerSponsorship(container) as Void
  if container = invalid
    return
  end if
  container.sponsorImages = invalid
  container.sponsorExp = invalid
End Function


' Finds a matching thematic takeover ad by containerId
' @param aThematicAds: array, array of thematic takeover ads
' @param containerId: string, the container ID to match
' @return assocarray or invalid, the matching ad if found
Function findMatchingThematicAd(aThematicAds, containerId) as Dynamic
  if isNonEmptyArray(aThematicAds) = false OR containerId = invalid
    return invalid
  end if

  for each thematicAd in aThematicAds
    if thematicAd <> invalid AND thematicAd.containerId = containerId
      return thematicAd
    end if
  end for

  return invalid
End Function


' Filters thematic takeover ads from an ad response
' @param response: assocarray with data array containing ad responses
' @return array of thematic takeover ads only
Function filterThematicTakeovers(response) as Object
  aThematicTakeovers = []

  aAdData = []
  if response <> invalid AND response.data <> invalid
    aAdData = response.data
  end if

  for each adResponse in aAdData
    if adResponse <> invalid AND adResponse.type = m.constants.ui.contentTypes.thematicTakeover
      aThematicTakeovers.push(adResponse)
    end if
  end for

  return aThematicTakeovers
End Function


' Sets sponsorship info on a container node
' @param container: roSGNode, the container node to apply sponsorship to
' @param sponsorshipInfo: assocArray, sponsorship info with spon_exp, image_urls, and pixels
Function setSponsorshipInfo(container, sponsorshipInfo) as Void
  if container <> invalid AND isAA(sponsorshipInfo) = true AND sponsorshipInfo.spon_exp <> invalid AND sponsorshipInfo.image_urls <> invalid
    images = sponsorshipInfo.image_urls
    info = CreateObject("roSGNode", "TubiSponsorImagesNode")
    info.brandLogo = images.brand_logo
    info.brandGraphic = images.brand_graphic
    info.pixels = sponsorshipInfo.pixels

    container.sponsorImages = info
    container.sponsorExp = sponsorshipInfo.spon_exp
  end if
End Function


' Sets the thematic takeover ad ID on a container's sponsorImages node
' @param container: roSGNode, the container node with sponsorImages
' @param sAdId: string, the thematic takeover ad ID
Function setThematicTakeoverId(container, sAdId) as Void
  if container <> invalid AND container.sponsorImages <> invalid
    container.sponsorImages.thematicTakeoverId = sAdId
  end if
End Function


' Applies thematic takeover theme to a single container
' Core helper used by all thematic takeover theme application functions
' @param container: roSGNode, the container node to apply theme to
' @param thematicAd: assocArray, the thematic takeover ad with sponsorshipInfo, id, validUntil
Function applyThemeToContainer(container, thematicAd) as Void
  if container = invalid OR thematicAd = invalid
    return
  end if

  ' Apply sponsorship info to this container
  setSponsorshipInfo(container, thematicAd.sponsorshipInfo)

  ' Store reference to the thematic takeover ad for pixel tracking
  setThematicTakeoverId(container, thematicAd.id)

  ' Set container's validUntil to the lower of container or ad expiry
  if thematicAd.validUntil <> invalid
    if container.validUntil = invalid OR thematicAd.validUntil < container.validUntil
      container.validUntil = thematicAd.validUntil
    end if
  end if
End Function


' Applies thematic takeover theme to content by matching containerId to content id
' @param content: roSGNode, the content node to apply theme to (CategoryContentNode)
' @param adContent: array of thematic takeover ads
' @return boolean, true if a matching theme was applied
Function applyThematicThemeToContent(content, adContent) as Boolean
  if content = invalid OR isNonEmptyArray(adContent) = false
    return false
  end if

  contentId = content.id

  ' Find matching thematic takeover for this content
  for each thematicAd in adContent
    if thematicAd <> invalid AND thematicAd.type = m.constants.ui.contentTypes.thematicTakeover
      if thematicAd.containerId <> invalid AND thematicAd.containerId = contentId
        ' Found matching theme - apply it
        applyThemeToContainer(content, thematicAd)
        return true
      end if
    end if
  end for

  return false
End Function
