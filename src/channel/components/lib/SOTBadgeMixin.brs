' Clear all SOT badges from target group
' @targetGroup: node to clear badges from
Function clearSOTBadges(targetGroup)
  if targetGroup <> invalid
    ' Remove all children using standard BrightScript
    childCount = targetGroup.getChildCount()
    targetGroup.removeChildrenIndex(childCount, 0)
  end if
End Function


Function showSotBadges(sotBadgeInfo, config, topLabelTargetGroup = invalid, markerTargetGroup = invalid, metedataTargetGroup = invalid)
  'Get the badges from the badge Info
  sotBadges = createSOTBadges(sotBadgeInfo, config)

  topLabels = sotBadges.topLabels
  showTopLabels(topLabelTargetGroup, topLabels)

  metaDataLabels = sotBadges.metaDataLabels
  showMetaDataLabels(metedataTargetGroup, metaDataLabels)

  marker = sotBadges.marker
  showMarkerLabels(markerTargetGroup, marker)
End Function


Function showTopLabels(topLabelTargetGroup, topLabels)
  if isNonEmptyArray(topLabels) = true AND topLabelTargetGroup <> invalid
    for each topLabel in topLabels
      topLabelTargetGroup.appendChild(topLabel)
    end for
  end if
End Function


Function showMetaDataLabels(metedataTargetGroup, metaDataLabels)
  if isNonEmptyArray(metaDataLabels) = true AND metedataTargetGroup <> invalid
    for each metaDataLabel in metaDataLabels
      metedataTargetGroup.appendChild(metaDataLabel)
    end for
  end if
End Function


Function showMarkerLabels(markerTargetGroup, marker, insertPosition = -1)
  if marker <> invalid AND markerTargetGroup <> invalid
    isMarkerPrent = markerTargetGroup.findNode("sotMarker")

    markerTargetGroup.removeChild(isMarkerPrent)

    if insertPosition >= 0
      markerTargetGroup.insertChild(marker, insertPosition)
    else
      markerTargetGroup.appendChild(marker)
    end if
  end if
End Function


' Creates SOT (Signals of Trust) badge nodes from sotInfo data
' @param sotInfo - AssocArray containing sotMetaDataTopLabels and sotMarkers
' @param config - AssocArray with optional styling configuration:
'   - focusedTextColor: color for top label badges (required)
'   - maxWidth: maximum width for badges (required)
'   - bodyMediumStrongFont: font for marker badge (optional)
'   - textColor: color for marker badge (optional)
' @return AssocArray with topLabels (array of Badge nodes) and marker (Badge node or invalid)
Function createSOTBadges(sotInfo, config)
  result = {
    topLabels: []
    metaDataLabels: []
    marker: invalid
  }

  if sotInfo = invalid OR config = invalid then return result

  if isNonEmptyAA(sotInfo) = true
    metaDataTopLabels = sotInfo.sotMetaDataTopLabels
    if isNonEmptyArray(metaDataTopLabels) = true
      sotTopLabels = createTopLabels(sotInfo.sotMetaDataTopLabels, config)
      if isNonEmptyArray(sotTopLabels) = true
        result.topLabels = sotTopLabels
      end if
    end if

    metaDataLabels = sotInfo.sotMetaData
    if isNonEmptyArray(metaDataLabels) = true
      sotMetadataLabels = createMetadataLabels(metaDataLabels, config)
      if isNonEmptyArray(sotMetadataLabels) = true
        result.metaDataLabels = sotMetadataLabels
      end if
    end if

    marker = sotInfo.sotMarkers
    sotMarker = createSotMarker(marker, config)
    if sotMarker <> invalid
      result.marker = sotMarker
    end if
  end if

  return result
End Function


' Creates a Badge node with SOT label configuration
' @param labelData - AssocArray containing sotLabelText and sotIcon
' @param config - AssocArray with styling configuration (backgroundColor, textColor, maxWidth, badgeFont)
' @return Badge node or invalid
Function createBadge(labelData, config)
  if isAA(labelData) = false OR isAA(config) = false then return invalid

  badge = createObject("roSGNode", "Badge")
  badge.text = labelData.sotLabelText
  badge.backgroundColor = config.backgroundColor
  badge.height = 40
  badge.borderUri = "pkg:/images/rounded-badge-border-dark-$$RES$$.9.png"
  badge.backgroundUri = "pkg:/images/rounded-background-$$RES$$.9.png"
  badge.iconUri = labelData.sotIcon
  badge.textColor = config.textColor
  if config.badgeFont <> invalid
    badge.badgeTextFont = config.badgeFont
  end if
  badge.maxWidth = config.maxWidth

  return badge
End Function


Function createTopLabels(sotMetaDataTopLabels, config)
  ' Create top label badges from sotMetaDataTopLabels
  sotTopLabels = []
  if isNonEmptyArray(sotMetaDataTopLabels) = true
    for each signal in sotMetaDataTopLabels
      ' Ignore TubiPresents (sotType = "tubiPresentsLogo") as it's handled separately
      if isAA(signal) = true AND (signal.sotType <> "tubi_presents" AND signal.sotType <> "tubiPresentsLogo")
        topLabel = createBadge(signal, config)
        if topLabel <> invalid
          sotTopLabels.push(topLabel)
        end if
      end if
    end for
  end if

  return sotTopLabels
End Function


Function createMetadataLabels(sotMetaDataLabels, config)
  sotMetaDataLabel = []
  if isNonEmptyArray(sotMetaDataLabels) = true
    for each metaDataLabel in sotMetaDataLabels
      ' Ignore TubiPresents (sotType = "tubiPresentsLogo") as it's handled separately
      if isAA(metaDataLabel) = true AND (metaDataLabel.sotType <> "tubi_presents" AND metaDataLabel.sotType <> "tubiPresentsLogo")
        metaDataLabelBadge = createBadge(metaDataLabel, config)
        if metaDataLabelBadge <> invalid
          sotMetaDataLabel.push(metaDataLabelBadge)
        end if
      end if
    end for
  end if

  return sotMetaDataLabel
End Function


Function createSotMarker(sotMarkers, config, marker = invalid)
  if isNonEmptyAA(sotMarkers) = true
    if marker = invalid
      marker = createObject("roSGNode", "Badge")
      marker.id = "sotMarker"
    end if
    marker.showBackground = false
    marker.backgroundColor = config.backgroundColor
    marker.maxWidth = config.maxWidth
    marker.text = sotMarkers.sotLabelText
    marker.iconUri = sotMarkers.sotIcon

    if config.bodyMediumStrongFont <> invalid
      marker.badgeTextFont = config.bodyMediumStrongFont
    end if

    if config.primaryTextColor <> invalid
      marker.textColor = config.primaryTextColor
    end if

    return marker
  end if

  return invalid
End Function


Function createSotPosterLabels(sotInfo, config, targetParent)
  if isNonEmptyString(sotInfo.sotLabelText) = true
    sotBadge = createObject("roSGNode", "Badge")
    sotBadge.id = "sotBadge"
    sotBadge.translation = [6, 6]
    sotBadge.textColor = config.primaryTextColor
    sotBadge.borderUri = "pkg:/images/rounded-badge-border-dark-$$RES$$.9.png"
    sotBadge.backgroundUri = "pkg:/images/rounded-background-$$RES$$.9.png"
    sotBadge.backgroundColor = config.backgroundColor
    sotBadge.iconUri = sotInfo.sotIcon
    sotBadge.maxWidth = config.maxWidth
    sotBadge.text = sotInfo.sotLabelText.Replace("days left", "Days Left")
    sotBadge.visible = true
    targetParent.appendChild(sotBadge)
    return sotBadge
  end if

  return invalid
End Function
