
' Override onItemContentChange which is triggered when the itemContent field value changes.
Function onItemContentChange(msg)
  itemContent = msg.getData()
  if itemContent <> invalid then
    m.label.text = itemContent.title
    m.labelFocused.text = itemContent.title
    checked = itemContent.checked

    ' Setting the visibility of the check icon based on the checked value.
    m.checkIcon.visible = (checked = true)
    m.checkIconFocused.visible = (checked = true)
    m.background.visible = (checked = true)

    if isArray(itemContent.contentRatings)
      removeBadges() 'remove old badges if any
      createBadges()

      for each badge in itemContent.contentRatings
        badgeNode = createObject("roSGNode", "Badge")
        badgeNode.text = badge

        badgeNode.backgroundColor = m.neutralColor
        badgeNode.textColor = m.unfocusedThemeColor
        m.badges.appendChild(badgeNode)
      end for
      m.container.appendChild(m.badges)
    else if m.badges <> invalid
      removeBadges()
    end if


    ' Used in settings screen to calculate the list width dynamically based on the text width of each item.
    nBoundingTextWidth = m.label.boundingRect().width
    m.top.calculatedWidth = nBoundingTextWidth + getWidthMinusText()
  else
    m.label.text = ""
    m.labelFocused.text = ""
    m.checkIcon.visible = false
    m.checkIconFocused.visible = false
  end if
End Function


' Callback triggered when the width field value gets updated. We don't need to do anything here.
Function onWidthChange(_msg)

End Function


' Returns the width that needs to be subtracted from the width.
Function getWidthMinusText()
  if m.badges <> invalid
    nBadgesWidth = m.badges.boundingRect().width
  else
    nBadgesWidth = 0
  end if
  ' The width include the checkbox, the space in between the checkbox and the label, and the space before the 1st and last elements of the checkbutton
  return m.checkIcon.width + (m.container.itemSpacings[0] * 2) + (m.container.translation[0] * 2) + nBadgesWidth
End Function


Function removeBadges()
  if m.badges <> invalid
    m.badges.visible = false
    m.container.removeChild(m.badges)
    m.badges = invalid
  end if
End Function


Function createBadges()
  if m.badges = invalid
    m.badges = createObject("roSGNode", "LayoutGroup")
    m.badges.layoutDirection = "horiz"
    m.badges.horizAlignment = "left"
    m.badges.vertAlignment = "center"
    m.badges.itemSpacings = [8]
  end if
End Function
