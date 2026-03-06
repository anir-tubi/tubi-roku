sub say(stext as String, role = "" as String, role2 = "" as String, flushSpeech = false as Boolean, role3 = "" as String, role4 = "" as String)
  if isValid(m.roAudioGuide) AND isString(stext)
    if flushSpeech then m.roAudioGuide.Flush()
    if isString(role) then m.roAudioGuide.say(role, false, false)
    m.roAudioGuide.say(stext, false, false)
    if isString(role2) then m.roAudioGuide.say(role2, false, false)
    if isValid(role3) then m.roAudioGuide.say(role3, false, false)
    if isValid(role4) then m.roAudioGuide.say(role4, false, false)
  end if
end sub

sub sayPoster(node)
  if isValid(node) AND isString(node["audioGuideText"]) then say(node["audioGuideText"])
end sub

sub sayText(node, role = "", visible = false as Boolean, role2 = "", flushSpeech = false as Boolean)
  if isValid(node) AND isString(node.text) AND ((isValid(node.visible) AND node.visible) OR visible) AND isValid(role) then say(node.text, role, role2, flushSpeech)
end sub

sub sayLayout(node, role, role2 = "", flushSpeech = false as Boolean)
  if isValid(node)
    nodeChildren = node.getChildren(-1, 0)
    if isArray(nodeChildren)
      for each item in nodeChildren
        tempRole = role
        if item.id = "dpdTitle" OR (item.id.Instr("_Header") <> -1 AND item.id.Instr("_Sub_Header") = -1 AND item.id <> "cookieMaxAgeSeconds_Header") then tempRole = m.WCAGRoles.headingAriaLabel
        iscontinue = true
        if item.id = "buttonLayout"
          btext = item.getChild(0)
          subtext = item.getChild(1)
          if isvalid(subtext) AND subtext.id = "statusText" AND subtext.visible
            iscontinue = false
            sayText(btext, tempRole, false, "", flushSpeech)
            sayText(subtext, "", false, role2, false)
          end if
        end if
        if iscontinue
          if item.id.Instr("_bullet") <> -1
            say(m.WCAGRoles.listItemAriaLabel, role, role2, flushSpeech)
          else
            sayText(item, tempRole, false, role2, flushSpeech)
          end if
          sayLayout(item, role, role2, flushSpeech)
        end if

      end for
    end if
  end if
end sub

sub saylist(node, role)
  if isValid(node)
    nodeChildren = node.content.getChildren(-1, 0)
    if isArray(nodeChildren)
      for each item in nodeChildren
        if isValid(item.id) AND isValid(item.Btype) AND item.Btype <> "circleBtn" then sayText(item, role, true)
      end for
    end if
  end if
end sub

sub sayFocused(node, role, role2)
  if isValid(node) AND isValid(node.content) AND isValid(node.itemFocused)
    item = node.content.getChild(node.itemFocused)
    say(item.text, role, role2)
  end if
end sub

sub saySelected(node, role, flushSpeech = false)
  if isValid(node) AND isValid(node.content) AND isValid(node.itemFocused)
    Mcount = node.content.getChildCount()
    itemFocused = node.itemFocused + 1
    item = node.content.getChild(node.itemFocused)
    if isvalid(item)
      text = item.text
      if node.id = "OTPurposeChildButtons"
        if item.status = 1 AND isValid(item.activeTextNode)
          text += " " + item.activeTextNode.text
        end if
        if item.status = 0 AND isValid(item.inActiveTextNode)
          text += " " + item.inActiveTextNode.text
        end if
      end if
      role2 = m.WCAGRoles.button + " " + itemFocused.toStr() + " of " + Mcount.toStr() + " " + m.WCAGRoles.selectedAriaLabel
      say(text, role, role2, flushSpeech)
    end if
  end if
end sub