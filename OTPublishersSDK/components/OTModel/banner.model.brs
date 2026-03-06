Function getBannerModelData(data)
  model = CreateObject("roSGNode", "OTBannerInterface")
  try
    if data <> invalid
      regx = createObject("roRegex", "\s(\s+)?", "")
      model.fonts = m.OT_Data.fonts
      if data.appConfig <> invalid
        if data.appConfig.bannerReasonCode <> invalid then model.bannerReasonCode = data.appConfig.bannerReasonCode
        if data.appConfig.bannerReason <> invalid then model.bannerReason = data.appConfig.bannerReason
      end if
      data = data.bannerUIData
      if isValid(data)
        getWCAGRoles(data)
        if data.logo <> invalid AND data.logo.url <> invalid then model.logo = data.logo.url
        if data.logo <> invalid AND data.logo.logoVoiceOverText <> invalid then model.logoVoiceOverText = data.logo.logoVoiceOverText
        if data.general <> invalid
          if data.general.layout <> invalid then model.layout = data.general.layout
          if data.general.backgroundColor <> invalid then model.backgroundColor = data.general.backgroundColor
          if data.general.buttonFocusColor <> invalid then model.buttonFocusColor = data.general.buttonFocusColor
          if data.general.buttonFocusTextColor <> invalid then model.buttonFocusTextColor = data.general.buttonFocusTextColor
          if data.general.buttonBorderShow <> invalid then model.border = data.general.buttonBorderShow
          if data.general.additionalDescriptionPlacement <> invalid then model.additionalDescriptionPlacement = data.general.additionalDescriptionPlacement
          model.ratio = [0.75, 0.25]
        end if
        if data.summary <> invalid
          if data.summary.title <> invalid then model.pageHeaderTitle = setbannerTextModel(data.summary.title, regx)
          if data.summary.dpdTitle <> invalid then model.dpdTitle = setbannerTextModel(data.summary.dpdTitle, regx)
          if data.summary.dpdDescription <> invalid then model.dpdDescription = setbannerTextModel(data.summary.dpdDescription, regx)
          if data.summary.description <> invalid then model.description = setbannerTextModel(data.summary.description, regx, true)
          if data.summary.additionalDescription <> invalid then model.additionalDescription = setbannerTextModel(data.summary.additionalDescription, regx, true)
        end if
        if data.buttons <> invalid
          if data.buttons.closeButton <> invalid then
            if isValid(data.buttons.closeButton.closeBtnVoiceOverText) then model.closeBtnVoiceOverText = data.buttons.closeButton.closeBtnVoiceOverText
            model.closeButton = buttonContentNodeItem(data.buttons, model, "closeButton")
          end if
          if data.buttons.acceptAll <> invalid then model.acceptAll = buttonContentNodeItem(data.buttons, model, "acceptAll")
          if data.buttons.rejectAll <> invalid then model.rejectAll = buttonContentNodeItem(data.buttons, model, "rejectAll")
          if data.buttons.showPreferences <> invalid then model.showPreferences = buttonContentNodeItem(data.buttons, model, "showPreferences")
          if data.buttons.vendorList <> invalid then model.vendorList = buttonContentNodeItem(data.buttons, model, "vendorList")
        end if
        if data.links <> invalid
          if data.links.policyLink <> invalid then model.policyLink = setbannerTextModel(data.links.policyLink, regx)
        end if
      end if
    end if
  catch e
    ? "Error in getBannerModelData: " + e.message
  end try
  return model
End Function

Function setbannerTextModel(data, regx, removeHTMLTags = false)
  contentNodeItem = CreateObject("roSGNode", "OTTextInterface")
  if data.text <> invalid AND data.text.Trim() <> ""
    text = regx.replaceAll(data.text, " ")
    if removeHTMLTags then text = StringRemoveHTMLTags(data.text)
    contentNodeItem.text = text
    if data.textColor <> invalid then contentNodeItem.textColor = data.textColor
    if data.urlQRCode <> invalid then contentNodeItem.url = data.urlQRCode
    return contentNodeItem
  end if
  return invalid
End Function

Function buttonContentNodeItem(button as Object, model, id as String)
  isBorder = false
  if model.border <> invalid AND model.border then isBorder = true
  btext = button[id].text
  textColor = button[id].textColor
  color = button[id].color
  maxLines = 2
  position = 0
  Btype = "rectangleBtn"
  if button[id].position <> invalid then position = button[id].position
  if id = "closeButton"
    btext = ""
    textColor = "0x000000"
    Btype = "circleBtn"
    color = model.description.textColor
    textColor = model.description.textColor
    maxLines = 2
    'if button[id].imgcolor <> invalid then textColor = button[id].imgcolor
    if button[id].showText <> invalid AND button[id].showText
      Btype = "rectangleBtn"
      btext = button[id].text
      color = button[id].color
      textColor = button[id].textColor
      if button[id].showAsLink <> invalid AND button[id].showAsLink
        isBorder = false
        color = model.backgroundColor
        textColor = model.description.textColor
      end if
    end if
  end if

  'if (id = "showPreferences" and button[id].showAsLink) or (id = "vendorList" and isValid(model.showPreferences) and model.showPreferences.border) then isBorder = true

  contentNodeItem = CreateObject("roSGNode", "OTButtonInterface")
  contentNodeItem.id = id
  contentNodeItem.text = btext
  contentNodeItem.color = color
  contentNodeItem.textColor = textColor
  contentNodeItem.focusButtonColor = model.buttonFocusColor
  contentNodeItem.focusButtonTextColor = model.buttonFocusTextColor
  contentNodeItem.border = isBorder
  contentNodeItem.position = position
  contentNodeItem.maxLines = maxLines
  contentNodeItem.Btype = Btype
  contentNodeItem.fonts = model.fonts
  contentNodeItem.horizAlign = "center"
  contentNodeItem.interactionType = button[id].interactionType
  return contentNodeItem
End Function