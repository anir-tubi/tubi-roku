' Host-driven Only on Tubi / Tubi Presents promo: parents assign exclusiveContentInfo once per update (targetGroup, index, linePromoData, content).
Function init()
  topRef = m.top

  m.exclusiveContentRowGroup = topRef.findNode("exclusiveContentRowGroup")
  m.onlyOnRow = m.exclusiveContentRowGroup.findNode("onlyOnRow")
  m.onlyOnTubiLabel = m.onlyOnRow.findNode("onlyOnTubiLabel")
  m.onlyOnTubiBadgePoster = m.onlyOnRow.findNode("onlyOnTubiBadgePoster")
  m.tubiPresentsLogo = m.exclusiveContentRowGroup.findNode("tubiPresentsLogo")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.onlyOnTubiLabel, typographyConstants.ids.bodySmall)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  topRef.observeFieldScoped("exclusiveContentInfo", "onExclusiveContentInfoChanged")

End Function


Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid AND m.onlyOnTubiLabel <> invalid
    m.onlyOnTubiLabel.color = theme.primaryTextColor
  end if
End Function


Function onExclusiveContentInfoChanged() as Void
  handleExclusiveContentSignalsDisplay()
End Function


Function getExclusiveContentInfo() as Object
  result = {
    targetGroup: invalid
    exclusiveSignalsInsertIndex: -1
    linePromoData: invalid
    content: invalid
  }

  exclusiveContentInfo = m.top.exclusiveContentInfo
  if isAA(exclusiveContentInfo) = false
    return result
  end if

  if exclusiveContentInfo.targetGroup <> invalid
    result.targetGroup = exclusiveContentInfo.targetGroup
  end if

  if exclusiveContentInfo.exclusiveSignalsInsertIndex <> invalid
    result.exclusiveSignalsInsertIndex = exclusiveContentInfo.exclusiveSignalsInsertIndex
  end if

  if exclusiveContentInfo.linePromoData <> invalid
    result.linePromoData = exclusiveContentInfo.linePromoData
  end if

  if exclusiveContentInfo.content <> invalid
    result.content = exclusiveContentInfo.content
  end if

  return result
End Function


Function handleExclusiveContentSignalsDisplay() as Void
  exclusiveContentInfo = getExclusiveContentInfo()
  tubiPresentationInfo = getTubiPresentationFromExclusiveContentInfo(exclusiveContentInfo)
  targetGroup = exclusiveContentInfo.targetGroup

  applyPresentationToChildren(tubiPresentationInfo)

  if isNonEmptyString(tubiPresentationInfo.badgeType) = false OR targetGroup = invalid
    detachFromHostIfAttached()
    m.top.visible = false
    return
  end if

  insertExclusiveSignalsToTargtGroup(targetGroup, tubiPresentationInfo, exclusiveContentInfo.exclusiveSignalsInsertIndex)
  m.top.visible = true
End Function


Function getTubiPresentationFromExclusiveContentInfo(exclusiveContentInfo) as Object
  linePad = exclusiveContentInfo.linePromoData
  if isAA(linePad) = true
    onlyOnAA = invalid
    metaDataArray = invalid
    if linePad.onlyOnTubi <> invalid
      onlyOnAA = linePad.onlyOnTubi
    end if

    metaDataArray = linePad.sotMetaData
    return getTubiExclusiveSotSignals(onlyOnAA, metaDataArray)
  end if

  content = exclusiveContentInfo.content
  if content <> invalid
    if content.hasField("sotBadgeType") AND content.sotBadgeType <> invalid AND isNonEmptyString(content.sotBadgeType) = true
      badgeType = content.sotBadgeType
      res = {
        badgeType: badgeType
        tubiPresentsIconUri: ""
        tubiPresentsWidth: 0
        tubiPresentsHeight: 0
      }
      if badgeType = "tubiPresents"
        res.tubiPresentsIconUri = "pkg:/images/tubi_presents_logo.webp"
      end if
      return res
    end if

    if content.hasField("sotInfo") AND isAA(content.sotInfo) = true
      return getTubiExclusiveSotSignalsFromSotInfo(content.sotInfo)
    end if
  end if

  return getTubiExclusiveSotSignals(invalid, invalid)
End Function


Function detachFromHostIfAttached() as Void
  p = m.top.getParent()
  if p <> invalid
    p.removeChild(m.top)
  end if
End Function


Function insertExclusiveSignalsToTargtGroup(targetGroup, pres, insertIndex) as Void
  detachFromHostIfAttached()

  ' onlyOnTubi and tubiPresents both use exclusiveSignalsInsertIndex (e.g. row title: 1 after EnhancedButton; -1 appends at end).
  if pres.badgeType = "onlyOnTubi" OR pres.badgeType = "tubiPresents"
    index = insertIndex
    childCount = targetGroup.getChildCount()
    if index < 0 OR index > childCount
      index = childCount
    end if
    targetGroup.insertChild(m.top, index)
  end if
End Function


Function applyPresentationToChildren(pres) as Void
  if pres = invalid OR isNonEmptyString(pres.badgeType) = false
    m.exclusiveContentRowGroup.visible = false
    m.onlyOnRow.visible = false
    m.onlyOnTubiLabel.visible = false
    m.onlyOnTubiBadgePoster.visible = false
    m.tubiPresentsLogo.visible = false
    ensureOnlyOnRowChildOfPromoRow()
    return
  end if

  m.exclusiveContentRowGroup.visible = true

  m.tubiPresentsLogo.visible = false
  ensureOnlyOnRowChildOfPromoRow()
  m.onlyOnRow.visible = false
  m.onlyOnTubiLabel.visible = false
  m.onlyOnTubiBadgePoster.visible = false

  if pres.badgeType = "onlyOnTubi"
    m.onlyOnRow.visible = true
    m.onlyOnTubiLabel.text = getTranslation("info_panel_only_on")
    m.onlyOnTubiLabel.visible = true
    m.onlyOnTubiBadgePoster.uri = "pkg:/images/tub-logo-small.png"
    m.onlyOnTubiBadgePoster.visible = true
    return
  end if

  if pres.badgeType = "tubiPresents"
    if m.onlyOnRow.getParent() <> invalid
      if m.onlyOnRow.getParent().id = m.exclusiveContentRowGroup.id
        m.exclusiveContentRowGroup.removeChild(m.onlyOnRow)
      end if
    end if
    m.tubiPresentsLogo.width = 192
    m.tubiPresentsLogo.height = 27

    iconUri = "pkg:/images/tubi_presents_logo.webp"
    if isNonEmptyString(pres.tubiPresentsIconUri) = true
      iconUri = pres.tubiPresentsIconUri
    end if
    m.tubiPresentsLogo.uri = iconUri

    if pres.tubiPresentsWidth <> invalid AND pres.tubiPresentsWidth > 0
      m.tubiPresentsLogo.width = pres.tubiPresentsWidth
    end if

    if pres.tubiPresentsHeight <> invalid AND pres.tubiPresentsHeight > 0
      m.tubiPresentsLogo.height = pres.tubiPresentsHeight
    end if

    m.tubiPresentsLogo.visible = true
    return
  end if

  m.exclusiveContentRowGroup.visible = false
  ensureOnlyOnRowChildOfPromoRow()
End Function


' Restores onlyOnRow under exclusiveContentRowGroup (index 0) after tubiPresents removed it, so layout is not empty.
Function ensureOnlyOnRowChildOfPromoRow() as Void
  if m.onlyOnRow = invalid OR m.exclusiveContentRowGroup = invalid
    return
  end if

  parent = m.onlyOnRow.getParent()
  if parent = invalid OR parent.id <> m.exclusiveContentRowGroup.id
    m.exclusiveContentRowGroup.insertChild(m.onlyOnRow, 0)
  end if
End Function
