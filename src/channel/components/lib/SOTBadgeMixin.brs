' Clear all SOT badges from target group
' @targetGroup: node to clear badges from
Function clearSOTBadges(targetGroup)
  if targetGroup <> invalid
    ' Remove all children using standard BrightScript
    childCount = targetGroup.getChildCount()
    targetGroup.removeChildrenIndex(childCount, 0)
  end if
End Function


'**
' * Displays SOT (Signals of Trust) badges in the specified target groups
' *
' * Creates and displays top label badges, marker badges, and poster labels based on
' * the provided SOT badge information. Top labels are displayed if available from
' * sotBadgeInfo, otherwise poster labels are used as fallback.
' *
' * @param {AssocArray} sotBadgeInfo - AssocArray containing SOT badge data:
' *   - sotMetaDataTopLabels: Array of top label badge data (sotLabelText, sotIcon, sotType)
' *   - sotMarkers: AssocArray with marker badge data (sotLabelText, sotIcon)
' *   - sotMetaData: Array of metadata label badge data (optional)
' * @param {AssocArray} config - Styling configuration for badges:
' *   - textColor: Color for poster label badges (required)
' *   - maxWidth: Maximum width for badges in pixels (required)
' *   - markerFont: Font for marker badge (optional)
' *   - badgeTextFont: Font for poster label badges (optional)
' *   - textColor: Color for marker badge (optional)
' * @param {Node} topLabelTargetGroup - Target group node where top label badges will be appended (optional)
' * @param {Node} markerTargetGroup - Target group node where marker badge will be appended (optional)
' * @param {AssocArray} posterLabels - Fallback poster label data when top labels are not available:
' *   - sotLabelText: Text to display on the badge (required)
' *   - sotIcon: Icon URI for the badge (optional)
' * @return {Void}
'**
Function showSotBadges(sotBadgeInfo, config, topLabelTargetGroup = invalid, markerTargetGroup = invalid, posterLabels = {})
  if topLabelTargetGroup <> invalid AND config.translation <> invalid
    topLabelTargetGroup.translation = config.translation
  end if

  'Get the badges from the badge Info
  sotBadges = createSOTBadges(sotBadgeInfo, config)

  topLabels = sotBadges.topLabels
  if isNonEmptyArray(topLabels) = true
    showTopLabels(topLabelTargetGroup, topLabels)
  else if isNonEmptyAA(posterLabels) = true
    posterLabels = createSotPosterLabels(posterLabels, config)
    showPosterLabesls(posterLabels, topLabelTargetGroup)
  end if

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
'   - maxWidth: maximum width for badges (required)
'   - markerFont: font for marker badge (optional)
'   - textColor: text color for badges
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
' @param config - AssocArray with styling configuration ( textColor, maxWidth, badgeTextFont, textColor)
' @return Badge node or invalid
Function createBadge(labelData, config)
  if isAA(labelData) = false OR isAA(config) = false then return invalid

  badge = createObject("roSGNode", "Badge")
  badge.isSotBadge = true
  badge.text = labelData.sotLabelText
  badge.borderUri = ""
  badge.backgroundUri = config.backgroundUri
  badge.textColor = config.textColor

  if config.badgeTextFont <> invalid
    badge.badgeTextFont = config.badgeTextFont
  end if

  badge.iconUri = labelData.sotIcon
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
    marker.maxWidth = config.maxWidth
    marker.text = sotMarkers.sotLabelText
    marker.iconUri = sotMarkers.sotIcon

    if config.markerFont <> invalid
      marker.badgeTextFont = config.markerFont
    end if

    if config.markerTextColor <> invalid
      marker.textColor = config.markerTextColor
    end if

    return marker
  end if

  return invalid
End Function


Function showPosterLabesls(posterLabels, targetParent)
  if posterLabels <> invalid AND targetParent <> invalid
    targetParent.appendChild(posterLabels)
  end if
End Function


Function createSotPosterLabels(sotInfo, config)
  if isNonEmptyString(sotInfo.sotLabelText) = true
    sotBadge = createObject("roSGNode", "Badge")
    sotBadge.id = "sotBadge"
    sotBadge.borderUri = ""
    sotBadge.isSotBadge = true
    sotBadge.backgroundUri = config.backgroundUri
    sotBadge.textColor = config.textColor
    sotBadge.translation = config.translation

    if config.badgeTextFont <> invalid
      sotBadge.badgeTextFont = config.badgeTextFont
    end if

    sotBadge.iconUri = sotInfo.sotIcon
    sotBadge.maxWidth = config.maxWidth

    sotBadge.text = sotInfo.sotLabelText
    sotBadge.visible = true
    return sotBadge
  end if

  return invalid
End Function


' @param sotPosterLabels - optional AA from content.sotInfo.sotPosterLabels
Function isOnlyOnTubiAvailable(sotPosterLabels)
  showOnlyOn = false
  onlyOnPrefix = getTranslation("info_panel_only_on")
  if isNonEmptyAA(sotPosterLabels) = true AND isNonEmptyString(sotPosterLabels.sotLabelText) = true AND isNonEmptyString(onlyOnPrefix) = true AND InStr(1, sotPosterLabels.sotLabelText, onlyOnPrefix) > 0
    showOnlyOn = true
  end if

  return showOnlyOn
End Function


' @param sotInfo - content.sotInfo assoc
' @returns - sotMetaData or sotMetadata array from translate (both keys supported)
Function getTubiExclusiveMetaDataArrayFromSotInfo(sotInfo) as Object
  if isAA(sotInfo) = false
    return invalid
  end if

  if isNonEmptyArray(sotInfo.sotMetaData) = true
    return sotInfo.sotMetaData
  end if

  return invalid
End Function


' Applies the first tubiPresentsLogo entry from sotMetaDataArray onto result (mutates result).
' @param result - assoc with badgeType, tubiPresentsIconUri, tubiPresentsWidth, tubiPresentsHeight
' @param sotMetaDataArray - optional array of sot metadata AAs
Function applyTubiPresentsPresentationFromSotMetaDataArray(result, sotMetaDataArray) as Void
  if isNonEmptyArray(sotMetaDataArray) = false
    return
  end if

  for each sotMetadata in sotMetaDataArray
    if isNonEmptyAA(sotMetadata) = true AND sotMetadata.sotType <> invalid AND sotMetadata.sotType = "tubiPresentsLogo"
      result.badgeType = "tubiPresents"
      if isNonEmptyString(sotMetadata.sotIcon) = true
        result.tubiPresentsIconUri = sotMetadata.sotIcon
      end if
      if isNumber(sotMetadata.width) = true
        result.tubiPresentsWidth = sotMetadata.width
      end if
      if isNumber(sotMetadata.height) = true
        result.tubiPresentsHeight = sotMetadata.height
      end if
      exit for
    end if
  end for
End Function


' @param onlyOnTubiAA - optional sotPosterLabels-shaped AA from detail line-one
' @param sotMetaDataArray - optional array from line-one sotMetaData
' @returns - assoc: badgeType ("", "onlyOnTubi", "tubiPresents"), tubiPresentsIconUri, tubiPresentsWidth, tubiPresentsHeight
Function getTubiExclusiveSotSignals(onlyOnTubiAA, sotMetaDataArray) as Object
  result = {
    badgeType: ""
    tubiPresentsIconUri: ""
    tubiPresentsWidth: 0
    tubiPresentsHeight: 0
  }

  if isOnlyOnTubiAvailable(onlyOnTubiAA) = true
    result.badgeType = "onlyOnTubi"
    return result
  end if

  applyTubiPresentsPresentationFromSotMetaDataArray(result, sotMetaDataArray)

  return result
End Function


' Same as line-field resolver but reads from content.sotInfo (expanded tile, grids, etc.).
Function getTubiExclusiveSotSignalsFromSotInfo(sotInfo) as Object
  result = {
    badgeType: ""
    tubiPresentsIconUri: ""
    tubiPresentsWidth: 0
    tubiPresentsHeight: 0
  }

  if isAA(sotInfo) = false
    return result
  end if

  if isOnlyOnTubiAvailable(sotInfo.sotPosterLabels) = true
    result.badgeType = "onlyOnTubi"
    return result
  end if

  metaDataArray = getTubiExclusiveMetaDataArrayFromSotInfo(sotInfo)
  applyTubiPresentsPresentationFromSotMetaDataArray(result, metaDataArray)

  return result
End Function
