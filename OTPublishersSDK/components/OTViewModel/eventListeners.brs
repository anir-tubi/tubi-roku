Function eventListeners(event, name, value = true, etype = invalid, data = invalid)
  if etype = "click"
    if name = "BANNER_ALLOW_ALL" then name = m.constant.listener["ELB101"]
    if name = "BANNER_REJECT_ALL" then name = m.constant.listener["ELB102"]
    if name = "BANNER_CLOSE" OR name = "BANNER_CONTINUE_WITHOUT_ACCEPTING" then name = m.constant.listener["ELB106"]
    if name = "PREFERENCE_CENTER_ALLOW_ALL" then name = m.constant.listener["ELP101"]
    if name = "PREFERENCE_CENTER_REJECT_ALL" then name = m.constant.listener["ELP102"]
    if name = "PREFERENCE_CENTER_CONFIRM" then name = m.constant.listener["ELP103"]
    if name = "PREFERENCE_CENTER_CLOSE" then name = m.constant.listener["ELP107"]
    if name = "VENDOR_LIST_ALLOW_ALL" then name = m.constant.listener["ELV101"]
    if name = "VENDOR_LIST_REJECT_ALL" then name = m.constant.listener["ELV102"]
    if name = "VENDOR_LIST_CONFIRM" then name = m.constant.listener["ELV103"]
    if name = "SDK_LIST_ALLOW_ALL" then name = m.constant.listener["ELS101"]
    if name = "SDK_LIST_REJECT_ALL" then name = m.constant.listener["ELS102"]
    if name = "SDK_LIST_CONFIRM" then name = m.constant.listener["ELS103"]
  end if
  if data <> invalid
    event[name] = data
  else
    event[name] = {
      name: name,
      response: value
    }
  end if
End Function