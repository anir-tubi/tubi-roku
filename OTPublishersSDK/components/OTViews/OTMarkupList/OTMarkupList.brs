' OneTrust SDK Header
sub init()
  m.WCAGRoles = CreateObject("roSGNode", "OTWCAGInterface")
  m.listViewSectionScroll = m.top.findNode("listViewSectionScroll")

  m.listScrollAnimation = m.top.findNode("listScrollAnimation")
  m.listScrollAnimationInterpolator = m.top.findNode("listScrollAnimationInterpolator")

  m.top.observeField("focusedChild", "onFocusedChildChange")

  m.lastTranslation = [0, 0]
  m.itemFocused = 0
  m.top.reset = false
  m.roAudioGuide = CreateObject("roAudioGuide")
end sub

sub onContentChange()
  data = m.top.content
  m.lastTranslation = [0, 0]
  m.itemFocused = 0
  m.top.reset = false
  m.loadindex = 12
  if isValid(m.global.OT_Data) AND isValid(m.global.OT_Data["WCAGRoles"]) then m.WCAGRoles = m.global.OT_Data["WCAGRoles"]
  while m.listViewSectionScroll.getChildCount() > 0
    m.listViewSectionScroll.removeChild(m.listViewSectionScroll.getChild(0))
  end while
  if data <> invalid AND data.getChildCount() > 0
    m.listViewSectionScroll.itemSpacings = m.top.itemSpacing
    m.startItemIndex = 0
    m.endItemIndex = data.getChildCount() - 1
    if m.endItemIndex < m.loadindex then m.loadindex = m.endItemIndex

    for i = m.startItemIndex to m.loadindex
      item = CreateObject("roSGNode", m.top.itemComponentName)
      item.width = m.top.width
      item.height = m.top.height
      item.itemContent = data.getChild(i)
      m.listViewSectionScroll.appendChild(item)
    end for

    m.lastScrollIndex = m.endItemIndex
    m.scrollHeight = 0

    if m.endItemIndex > m.loadindex
      createTaskPromise("OTCommonTask", {
        data: {
          data: data,
          top: m.top,
          startItemIndex: m.loadindex + 1
          view: m.listViewSectionScroll
        },
        functionName: "updatelazyloadingListView",
      }, true, "complete").then(sub(complete)
        if complete then setLastScrollItem()
      end sub)
    else
      setLastScrollItem()
    end if
  end if
end sub

Function setLastScrollItem()
  if m.top.isScrollable then m.lastScrollIndex = m.startItemIndex
  if m.listViewSectionScroll.getChildCount() > 0 AND m.top.height <> 0 AND m.top.isScrollable
    endItemIndex = m.listViewSectionScroll.getChildCount() - 1
    totalHeight = 0 - m.listViewSectionScroll.itemSpacings[0]
    for i = endItemIndex to m.startItemIndex step -1
      height = m.listViewSectionScroll.getChild(i).boundingRect().height + m.listViewSectionScroll.itemSpacings[0]
      totalHeight = totalHeight + height
      if totalHeight >= m.top.height
        m.lastScrollIndex = i
        m.scrollHeight = totalHeight - m.top.height
        exit for
      end if
    end for
  end if
End Function

'***********************************************************************
'* onFocusedChildChanged(data)
'* Should be overridden by inherited view.
'***********************************************************************
Function onFocusedChildChange() as Void
  if(m.itemFocused = invalid)
    m.itemFocused = m.top.itemFocused
  end if
  if(m.itemFocused <> invalid)
    itemFocusedIndex = m.itemFocused
    if m.listViewSectionScroll.getChildCount() > 0
      focusedchild = m.listViewSectionScroll.getChild(itemFocusedIndex)
      if isValid(focusedchild)
        if m.top.hasFocus()
          focusedchild.setFocus(true)
        else if not m.top.isInFocusChain() AND focusedchild.itemContent.Btype = "listViewRectangle" AND m.key = "right"
          focusedchild.itemUnfocused = true
        end if
      end if
    end if
  end if
End Function

'***********************************************************************
'* onitemFocusedChanged()
'***********************************************************************
Function onItemFocusedChange()
  m.itemFocused = m.top.itemFocused
  itemFocusedIndex = m.itemFocused
  newFocusedItem = m.listViewSectionScroll.getChild(itemFocusedIndex)
  lastFocusedItem = m.listViewSectionScroll.getChild(itemFocusedIndex - 1)
  if m.top.isInFocusChain() AND itemFocusedIndex >= 0 AND newFocusedItem <> invalid AND not m.top.reset
    newFocusedItem.setFocus(true)
    if m.key = "up" AND itemFocusedIndex <= m.lastScrollIndex
      height = newFocusedItem.boundingRect().height + m.listViewSectionScroll.itemSpacings[0]
      if m.lastScrollIndex = itemFocusedIndex then height = m.scrollHeight
      m.top.scrollHeight = height
      if m.top.isScrollable then scrollAnimation()
    else if m.key = "down" AND lastFocusedItem <> invalid AND itemFocusedIndex - 1 <= m.lastScrollIndex
      height = lastFocusedItem.boundingRect().height + m.listViewSectionScroll.itemSpacings[0]
      if m.lastScrollIndex = itemFocusedIndex - 1 then height = m.scrollHeight
      m.top.scrollHeight = height
      if m.top.isScrollable then scrollAnimation()
    end if
    setFocusWCAG()
  else
    m.top.reset = false
  end if
End Function

sub setFocusWCAG()
  if m.top.id = "OTConsentButtons"
    item = m.listViewSectionScroll.getChild(m.top.itemFocused)
    role = m.WCAGRoles.button
    role2 = m.WCAGRoles.selectedAriaLabel
    if item.id = "legitInterestCheckBox" OR item.id = "consentCheckBox" OR item.id = "activeTextCheckBox" OR item.id = "inActiveTextCheckBox" OR item.id = "sdkFilterList" OR item.id = "iabFilterList"
      role = m.WCAGRoles.checkBoxDisabledAriaLabel
      if item.status = 1 then role = m.WCAGRoles.checkBoxEnabledAriaLabel
      role2 = ""
      if item.id = "iabFilterList" OR item.id = "sdkFilterList"
        Mcount = m.top.content.getChildCount()
        itemFocused = m.top.itemFocused + 1
        role2 = itemFocused.toStr() + " of " + Mcount.toStr()
      end if
    end if
    saylayout(item, role, role2, true)
  else if m.top.id = "OTAdditionalButtons"
    saylayout(m.listViewSectionScroll.getChild(m.top.itemFocused), m.WCAGRoles.button, m.WCAGRoles.selectedAriaLabel, true)
  else if m.top.id = "OTPurposeChildButtons"
    saySelected(m.top, "", true)
    'saylayout(m.listViewSectionScroll.getChild(m.top.itemFocused), m.WCAGRoles.button, m.WCAGRoles.selectedAriaLabel, true)
  else if m.top.id = "backButton"
    item = m.listViewSectionScroll.getChild(m.top.itemFocused)
    say(item.itemContent.subText, m.WCAGRoles.button, m.WCAGRoles.selectedAriaLabel, true)
  end if
end sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
  handled = false
  m.key = key
  m.top.key = key
  if press AND m.listViewSectionScroll.isInFocusChain()
    if key = "up"
      itemFocused = m.itemFocused - 1
      if itemFocused >= 0
        m.top.itemFocused = m.itemFocused - 1
        handled = true
      end if
    else if key = "down"
      itemFocused = m.itemFocused + 1
      if itemFocused <= m.listViewSectionScroll.getChildCount() - 1
        m.top.itemFocused = m.itemFocused + 1
        handled = true
      end if
    end if
  end if
  return handled
End Function

Function scrollAnimation()
  offsetY = m.top.scrollHeight
  m.listScrollAnimation.duration = 0.5 'm.scrollTimer.duration
  if (m.key = "up") offsetY = -offsetY
  nextTranslation = [0, m.lastTranslation[1] - offsetY]
  m.listScrollAnimationInterpolator.keyValue = [m.listViewSectionScroll.translation, nextTranslation]
  m.listScrollAnimation.control = "start"
  m.lastTranslation = nextTranslation
End Function

Function resetGrid()
  if m.top.reset
    m.top.itemFocused = 0
    m.lastTranslation = [0, 0]
    m.listViewSectionScroll.translation = [0, 0]
  end if
End Function


