' OneTrust SDK Banner
sub init()
    m.sdkData = m.global._OT_initialize_data
    screenSize = m.global.screenSize
    m.width = screenSize.w
    m.height = screenSize.h
    m.constant = applicationConstants()
    m.buttonListRect = m.top.findNode("buttonListRect")
    m.descriptionRec = m.top.findNode("descriptionRec")
    m.normalDescription = m.top.findNode("normalDescription")
    m.headerRect = m.top.findNode("headerRect")
    m.paddingBRect = m.top.findNode("paddingBRect")
    m.headersection = m.top.findNode("headersection")
    m.descriptionIAB = m.top.findNode("descriptionIAB")
    m.logo = m.top.findNode("logo")
    m.logo.observeField("loadStatus", "onDisplayLogo")
    m.close = m.top.findNode("close")
    m.closetextList = m.top.findNode("closetextList")
    m.buttonList = m.top.findNode("buttonList")
    m.privacyRect = m.top.findNode("privacyRect")
    m.actionRect = m.top.findNode("actionRect")
    m.qrCodeImg = m.top.findNode("qrCodeImg")
    m.policyLinkText = m.top.findNode("policyLinkText")
    m.descriptionScrollRec = m.top.findNode("descriptionScrollRec")
    m.buttonContent = []
    m.buttonList.observeField("itemSelected", "onButtonSelected")
    m.closetextList.observeField("itemSelected", "onCloseButtonSelected")
    saveToReg()
    m.title = m.top.findNode("title")
    m.dpdTitle = m.top.findNode("dpdTitle")
    m.dpdDescription = m.top.findNode("dpdDescription")
    m.AfterTitle = m.top.findNode("AfterTitle")
    m.AfterDescription = m.top.findNode("AfterDescription")
    m.AfterDPD = m.top.findNode("AfterDPD")
    m.dpdheading = m.top.findNode("dpdheading")
    m.bannerHeading = m.top.findNode("bannerHeading")
    m.scrollThumb = m.top.findNode("scrollThumb")
    m.fontSizeText = m.top.findNode("fontSizeText")
    m.poweredLogo = m.top.findNode("poweredLogo")
    m.poweredLogo.translation = [m.width - m.poweredLogo.width - 50, m.height - m.poweredLogo.height - 7]
    m.padding = 50
    m.bottomPadding = m.padding
    m.buttonListPadding = 30
    m.layout = "right"
    m.top.hideInteractionType = ""
    setMultistyleLabel()
end sub

function saveToReg()
    sdkReg = CreateObject("roRegistrySection", "OTsdkReg")
    bannerShownTime = CreateObject("roDateTime").AsSeconds().ToStr()
    sdkReg.Write("isBannershowed", bannerShownTime)
    sdkReg.Flush()
end function

function onBannerData()
    bannerData = m.top.bannerData
    if bannerData.keys().count() > 0
        m.layout = bannerData.layout
        m.charsize = 60
        if m.height = 1080 then m.charsize = 75
        styleData = bannerData.styleData
        setDescriptionColor(styleData.textColor)
        m.privacyRect.color = styleData.backgroundColor
        m.privacyRect.width = m.width
        m.privacyRect.height = m.height
        m.headersection.color = m.privacyRect.color
        m.headersection.width = m.width
        m.headerRect.color = m.privacyRect.color
        m.headerRect.translation = [m.padding, m.padding]
        m.headerRect.height = m.headersection.height - m.padding
        m.headerRect.width = m.headersection.width - 2 * m.headerRect.translation[0]
        m.actionRect.color = m.privacyRect.color
        m.buttonList.itemSize = [(m.width - (2 * m.buttonList.translation[0])) * 0.3 , m.charsize]
        m.actionRect.width = m.buttonList.itemSize[0] + (2 * m.buttonList.translation[0]) - m.scrollThumb.width
        m.actionRect.translation = [m.width - m.actionRect.width, m.headerRect.height + m.headerRect.translation[1]]
        m.actionRect.height = m.height - m.headerRect.height - m.headerRect.translation[1] - m.padding
        m.descriptionRec.color = m.privacyRect.color
        m.descriptionRec.translation = [m.padding, m.headerRect.height + m.headerRect.translation[1]]
        m.descriptionRec.width = m.actionRect.translation[0] - m.descriptionRec.translation[0]
        m.descriptionRec.height = m.height - m.headerRect.height - m.headerRect.translation[1] - m.padding
        m.paddingBRect.height = m.padding
        m.paddingBRect.width = m.width
        m.paddingBRect.color = m.privacyRect.color
        m.paddingBRect.translation = [0, m.actionRect.height + m.actionRect.translation[1]]
        descriptionWidth = m.actionRect.translation[0] - m.padding - m.scrollThumb.width
        setDescriptionWidth(descriptionWidth)
        m.scrollThumb.translation = [descriptionWidth, 0]
        m.scrollThumb.color = styleData.textColor
        if bannerData.doesExist("logoSize")
            if bannerData.logoSize.doesExist("width")
                m.logo.loadWidth = bannerData.logoSize.width
                m.logo.width = bannerData.logoSize.width
            end if
            if bannerData.logoSize.doesExist("height")
                m.logo.loadHeight = bannerData.logoSize.height
                m.logo.height = bannerData.logoSize.height
            end if
        end if
        if bannerData.logo <> invalid and bannerData.logo.show
            m.logo.visible = true
            m.logo.uri = getLogo(bannerData.logo)
        end if
        m.policyLinkText.scale = [0.0, 0.0]
        m.qrCodeImg.scale = [0.0, 0.0]
        m.qrCodeImg.visible = false
        m.policyLinkText.visible = false
        if bannerData.policyLink <> invalid and bannerData.policyLink.show and bannerData.policyLink.urlQRCode <> invalid and bannerData.policyLink.urlQRCode <> ""
            m.policyLinkText.scale = [1.0, 1.0]
            m.policyLinkText.visible = true
            m.policyLinkText.text = bannerData.policyLink.text
            m.policyLinkText.width = descriptionWidth
            m.policyLinkText.color = styleData.textColor
            m.qrCodeImg.scale = [1.0, 1.0]
            m.qrCodeImg.visible = true
            m.qrCodeImg.loadHeight = 250
            m.qrCodeImg.loadWidth = 250
            m.qrCodeImg.width =  m.qrCodeImg.loadHeight
            m.qrCodeImg.height = m.qrCodeImg.loadWidth
            m.qrCodeImg.uri = bannerData.policyLink.urlQRCode
            m.qrCodeImg.blendColor = styleData.textColor
        end if
        height = m.buttonList.numRows * (m.buttonList.itemSize[1] + m.buttonList.itemSpacing[1])
        m.buttonList.translation = [m.buttonList.translation[0], (m.actionRect.height / 2) - (height / 2)]
        if bannerData.closeButton.show
            closeButton = bannerData.closeButton
            if closeButton.showText
                m.closetextList.visible = true
                closeBtn = []
                paddingH = 12
                m.fontSizeText.maxLines = 2
                maxClosewidth = m.width * 0.4
                m.fontSizeText.text = closeButton.text
                itemSize = m.fontSizeText.boundingRect()
                if itemSize.width > maxClosewidth
                    m.fontSizeText.width = maxClosewidth
                    m.fontSizeText.text = closeButton.text
                    itemSize = m.fontSizeText.boundingRect()
                end if
                if m.height = 1080 then paddingH = 15
                m.closetextList.itemSize = [itemSize.width + 2*paddingH, itemSize.height + 2*paddingH]
                m.closetextList.translation = [m.headerRect.width - m.closetextList.itemSize[0], -paddingH]
                color = closeButton.color
                if closeButton.showAsLink then color = styleData.backgroundColor
                data = setButtonText(closeButton.text, color, closeButton.textColor, false, bannerData.styleData.acceptbuttonFocusColor, bannerData.styleData.acceptbuttonTextFocusColor, "closetextList", "closeText")
                closeBtn.push(data)
                m.closetextList.content = getButtonList(closeBtn, "closeBtn")
            else
                m.close.font.size = 30
                m.close.color = styleData.textColor
                closeWidth = m.close.boundingRect().width
                m.close.translation = [m.headerRect.width - closeWidth, 0]
                m.close.visible = true
            end if
        end if
        setButton(bannerData)
        setLayout()
        setDescription(bannerData)
        m.scrollThumb.height = scrollHeight()
        m.top.onShowBanner = true
    end if
end function

function setLayout()
    if m.layout = "bottom"
        m.buttonList.numRows = 1
        m.buttonList.numColumns = 4
        maxheight = m.charsize
        if m.buttonListWidth.count() > 0 then maxheight = m.buttonListWidth[0]
        m.actionRect.translation = [0, m.height - (maxheight + 2* m.buttonListPadding)]
        m.actionRect.height = maxheight + 2* m.buttonListPadding
        m.actionRect.width = m.width
        m.buttonList.translation = [m.padding, 30]
        m.buttonList.itemSpacing = [m.buttonListPadding, 0]
        acount = m.buttonList.content.getChildCount()
        m.buttonList.itemSize = [((m.width - (2 * m.padding)) - ((acount - 1) * m.buttonListPadding)) / acount, maxheight]
        descriptionWidth = m.actionRect.width - (2 * m.padding)
        setDescriptionWidth(descriptionWidth)
        m.scrollThumb.translation = [descriptionWidth, 0]
        m.bottomPadding = m.actionRect.height
    end if
end function

function scrollHeight()
    m.scrollThumb.visible = false
    ThumbHeight = 0
    ViewportHeight = m.height - m.bottomPadding - m.headersection.boundingRect().height
    ContentHeight = m.descriptionScrollRec.boundingRect().height
    scrolltextH = ContentHeight - ViewportHeight
    if scrolltextH >= 0
        m.scrollThumb.visible = true
        scrollacc = scrolltextH / 60
        ThumbHeight = ViewportHeight - (scrollacc * 60)
        m.scrollJump = 60
        if ThumbHeight <= 100
            ThumbHeight = 100
            scrollThumbSpace = viewportHeight - ThumbHeight
            m.scrollJump = scrollThumbSpace / scrollacc
        end if
    end if
    return ThumbHeight
end function

function getLogo(data as object) as string
    logoString = data.url
    if logoString <> "" and Instr(1, logoString, ".svg") = 0
        return data.url
    end if
    return "pkg:/components/OTPublishersSDK/images/ic_ot.png"
end function

function getButtonList(buttonList as object, btnName as string) as object
    m.fontSizeText.width = m.buttonList.itemSize[0] - 56
    m.fontSizeText.maxLines = 3
    maxheight = 0
    if m.layout = "bottom"
        acount = buttonList.count()
        width = ((m.width - (2 * m.padding)) - ((acount - 1) * m.buttonListPadding)) / acount - 16
        m.fontSizeText.width = width
        m.fontSizeText.maxLines = 2
    end if
    m.buttonListWidth = []
    data = CreateObject("roSGNode", "ContentNode")
    for each b in buttonList
        dataItem = data.CreateChild("OTGroupListData")
        dataItem.name = b.textData
        dataItem.buttonColor = b.buttonColor
        dataItem.buttonTextColor = b.buttonTextColor
        dataItem.focusButtonColor = b.focusButtonColor
        dataItem.focusButtonTextColor = b.focusButtonTextColor
        dataItem.id = b.id
        if b.groupRecId <> invalid then dataItem.groupRecId = b.groupRecId
        dataItem.isBorder = b.isBorder
        if btnName = "actionBtn"
            m.fontSizeText.text = dataItem.name
            height = m.fontSizeText.boundingRect().height + 30
            if maxheight < height then
                maxheight = height
            end if
            m.buttonListWidth.push(height)
        end if
    end for
    if m.layout = "bottom" AND m.buttonListWidth.count() > 0
        m.buttonListWidth[0] = maxheight
    end if
    return data
end function

function setButton(bannerData as object)
    id = "bannerbottomButtons"
    if m.layout = "right" then  id = "bannerRightButtons"
    accept = isAccept(bannerData)
    if accept <> ""
        data = setButtonText(accept, bannerData.styleData.acceptbuttonColor, bannerData.styleData.acceptbuttonTextColor, false, bannerData.styleData.acceptbuttonFocusColor, bannerData.styleData.acceptbuttonTextFocusColor, id, "acceptAll")
        m.buttonContent.push(data)
    end if
    refuse = isRefuse(bannerData)
    if refuse <> ""
        data = setButtonText(refuse, bannerData.styleData.rejectbuttonColor, bannerData.styleData.rejectbuttonTextColor, false, bannerData.styleData.rejectbuttonFocusColor, bannerData.styleData.rejectbuttonTextFocusColor, id, "rejectAll")
        m.buttonContent.push(data)
    end if
    setting = isSettings(bannerData)
    if setting <> ""
        data = setButtonText(setting, bannerData.styleData.pcbuttonColor, bannerData.styleData.pcbuttonTextColor, true, bannerData.styleData.pcbuttonFocusColor, bannerData.styleData.pcbuttonTextFocusColor, id, "confirmMyChoice")
        m.buttonContent.push(data)
    end if
    vendorListText = isVendorList(bannerData)
    if bannerData.isiab and vendorListText <> ""
        buttonColor = bannerData.styleData.vendorbuttonColor
        textColor = bannerData.styleData.vendorbuttonTextColor
        data = setButtonText(vendorListText, buttonColor, textColor, true, bannerData.styleData.acceptbuttonFocusColor, bannerData.styleData.acceptbuttonTextFocusColor, id, "vendorList")
        m.buttonContent.push(data)
    end if
    m.buttonList.content = getButtonList(m.buttonContent, "actionBtn")
    m.buttonList.rowHeights = m.buttonListWidth
    m.buttonList.setFocus(true)
end function

function setButtonText(textData as string, buttonColor as string, buttonTextColor as string, isBorder as boolean, focusButtonColor as string, focusButtonTextColor as string, groupRecId as string, id as string) as object
    data = {}
    data.textData = textData
    data.buttonColor = buttonColor
    data.buttonTextColor = buttonTextColor
    data.focusButtonColor = focusButtonColor
    data.focusButtonTextColor = focusButtonTextColor
    data.groupRecId = groupRecId
    data.isBorder = isBorder
    data.id = id
    return data
end function

function isAccept(bannerData as object) as string
    if bannerData.ShowBannerAcceptButton
        return bannerData.AlertAllowCookiesText
    end if
    return ""
end function

function isRefuse(bannerData as object) as string
    if bannerData.BannerShowRejectAllButton
        return bannerData.BannerRejectAllButtonText
    end if
    return ""
end function

function isSettings(bannerData as object) as string
    if bannerData.ShowBannerCookieSettings
        return bannerData.AlertMoreInfoText
    end if
    return ""
end function

function isVendorList(bannerData as object) as string
    return bannerData.banneriabpartnerslink
end function

function onKeyEvent(key as string, press as boolean) as boolean
    handled = false
    if press
        if key = "up"
            if m.descriptionScrollRec.hasFocus() and isScrollable("up")
                scroll("up")
            else if m.layout = "bottom" and m.buttonList.hasFocus() and m.scrollThumb.visible
                m.scrollThumb.opacity = "1"
                m.descriptionScrollRec.setFocus(true)
            else if (m.closetextList.visible or m.close.visible) and (m.buttonList.hasFocus() or m.descriptionScrollRec.hasFocus())
                m.scrollThumb.opacity = "0.3"
                setCloseButtonFocus()
            end if
            handled = true
        else if key = "down"
            if m.close.hasFocus() or m.closetextList.hasFocus()
                if m.layout = "bottom" and m.scrollThumb.visible
                    m.scrollThumb.opacity = "1"
                    m.descriptionScrollRec.setFocus(true)
                else
                    m.buttonList.setFocus(true)
                    m.close.font.size = 30
                end if
            else if m.descriptionScrollRec.hasFocus() and isScrollable("down")
                scroll("down")
            else if m.layout = "bottom"
                m.descriptionScrollRec.translation = [m.descriptionScrollRec.translation[0], 0]
                m.scrollThumb.translation = [m.scrollThumb.translation[0], 0]
                m.scrollThumb.opacity = "0.3"
                m.buttonList.setFocus(true)
            end if
            handled = true
        else if key = "OK"
            if m.close.hasFocus()
                m.top.hideInteractionType = m.constant.info.bannerClose
                m.top.onHideBanner = true
            end if
            handled = true
        else if key = "back"
            handled = true
        else if key = "left"
            if m.layout = "right" and m.buttonList.hasFocus() and m.scrollThumb.visible
                m.scrollThumb.opacity = "1"
                m.descriptionScrollRec.setFocus(true)
            end if
            handled = true
        else if key = "right"
            if m.layout = "right" and m.descriptionScrollRec.hasFocus()
                m.descriptionScrollRec.translation = [m.descriptionScrollRec.translation[0], 0]
                m.scrollThumb.translation = [m.scrollThumb.translation[0], 0]
                m.scrollThumb.opacity = "0.3"
                m.buttonList.setFocus(true)
            end if
            handled = true
        end if
    end if
    return handled
end function

function isScrollable(key)
    originalLayoutH = m.height - m.bottomPadding - m.headersection.boundingRect().height
    layoutH = m.descriptionScrollRec.boundingRect().height
    if key = "down"
        return layoutH > originalLayoutH and (-m.descriptionScrollRec.translation[1] + originalLayoutH) < layoutH
    else
        return layoutH > originalLayoutH and m.descriptionScrollRec.translation[1] <> 0
    end if
end function

function scroll(direction)
    if direction = "up"
        m.descriptionScrollRec.translation = [m.descriptionScrollRec.translation[0], m.descriptionScrollRec.translation[1] + 60]
        m.scrollThumb.translation = [m.scrollThumb.translation[0], m.scrollThumb.translation[1] - m.scrollJump]
    else
        m.descriptionScrollRec.translation = [m.descriptionScrollRec.translation[0], m.descriptionScrollRec.translation[1] - 60]
        m.scrollThumb.translation = [m.scrollThumb.translation[0], m.scrollThumb.translation[1] + m.scrollJump]
    end if
end function

function onButtonSelected()
    itemSelected = m.buttonList.itemSelected
    contentData = m.buttonList.content.getChild(itemSelected)
    bannerData = m.top.bannerData
    if contentData.name = isAccept(bannerData)
        m.top.onBannerClickedAcceptAll = true
    else if contentData.name = isRefuse(bannerData)
        m.top.onBannerClickedRejectAll = true
    else if contentData.name = isSettings(bannerData)
        m.top.onBannerClickedSettings = true
    else if contentData.name = isVendorList(bannerData)
        m.top.onBannerClickedVendorList = true
    end if
end function

function setViewFocus(message as object)
    if message <> invalid then m.buttonList.setFocus(true)
end function

function setCloseButtonFocus()
    if m.close.visible
        m.close.setFocus(true)
        m.close.font.size = 40
    else
        m.closetextList.setFocus(true)
    end if
end function

function onCloseButtonSelected()
    m.top.hideInteractionType = m.constant.info.bannerContinueWithoutAccepting
    m.top.onHideBanner = true
end function

function setDescription(props)
    bannerSummary = props.summary
    regx = createObject("roRegex", "\s(\s+)?", "")
    if bannerSummary.title <> invalid and bannerSummary.title.text <> invalid and bannerSummary.title.text.Trim() <> "" and bannerSummary.title.show 
        m.title.visible = true
        m.title.scale = [1,1]
        m.bannerHeading.itemSpacings = [10, 0, 0]
        m.title.text = regx.replaceAll(bannerSummary.title.text, " ") 
    end if
    if bannerSummary.dpdTitle <> invalid and bannerSummary.dpdTitle.text <> invalid and bannerSummary.dpdTitle.text.Trim() <> "" 
        m.dpdTitle.visible = true
        m.dpdTitle.scale = [1,1]
        m.dpdTitle.text = regx.replaceAll(bannerSummary.dpdTitle.text, " ")
    end if
    if bannerSummary.dpdDescription <> invalid and bannerSummary.dpdDescription.text <> invalid and bannerSummary.dpdDescription.text.Trim() <> "" 
        m.dpdDescription.visible = true
        m.dpdDescription.scale = [1,1]
        m.dpdDescription.text = regx.replaceAll(bannerSummary.dpdDescription.text, " ")
    end if
    if bannerSummary.description <> invalid and bannerSummary.description.text <> invalid and bannerSummary.description.text.Trim() <> "" and bannerSummary.description.show 
        m.description.visible = true
        m.description.scale = [1,1]
        description = bannerSummary.description.text
        Vcount = "{0}"
        if m.ismultiStyleLabel then Vcount = "<b>{0}</b>"
        if optionalChaining(m.global._OT_IABVendor_data, "iab.sortedVendorRecords") <> invalid and isIAB2V2() then description = description.replace("[VENDOR_NUMBER]",  Substitute(Vcount, m.global._OT_IABVendor_data.iab.sortedVendorRecords.count().toStr()))
        m.description.text = regx.replaceAll(description, " ")
    end if
    if bannerSummary.additionalDescription <> invalid and bannerSummary.additionalDescription.text <> invalid and bannerSummary.additionalDescription.text.Trim() <> "" and bannerSummary.additionalDescription.show 
         if props.BannerAdditionalDescPlacement = "AfterTitle"
            m.AfterTitle.visible = true
            m.AfterTitle.scale = [1,1]
            if m.description.visible then m.bannerHeading.itemSpacings = [10, 40, 0]
            m.AfterTitle.text = regx.replaceAll(bannerSummary.additionalDescription.text, " ")
        else if props.BannerAdditionalDescPlacement = "AfterDPD"
            m.AfterDPD.visible = true
            m.AfterDPD.scale = [1,1]
            m.dpdheading.itemSpacings = [10, 40]
            m.AfterDPD.text = regx.replaceAll(bannerSummary.additionalDescription.text, " ")
        else
            m.AfterDescription.visible = true
            m.AfterDescription.scale = [1,1]
            if m.description.visible then m.bannerHeading.itemSpacings = [10, 0, 40]
            m.AfterDescription.text = regx.replaceAll(bannerSummary.additionalDescription.text, " ")
        end if
    end if
end function

function onDisplayLogo()
    if(m.logo.loadStatus = "ready")
        m.logo.loadWidth = (m.logo.bitmapWidth/m.logo.bitmapHeight) * m.logo.height 
        m.logo.width = m.logo.loadWidth
    end if
end function

function setDescriptionColor(color) 
    m.title.color = color
    m.description.color = color
    if m.ismultiStyleLabel
        m.description.drawingStyles = {
            "b": {
                "fontUri": "font:SmallBoldSystemFont"
                "color": color
            },
            "default": {
                "fontUri": "font:SmallSystemFont"
                "color": color
            }
    }
    end if
    m.dpdTitle.color = color
    m.dpdDescription.color = color
    m.AfterTitle.color = color
    m.AfterDescription.color = color
    m.AfterDPD.color = color
end function

function setDescriptionWidth(width)
    m.title.width = width
    m.description.width = width
    m.dpdTitle.width = width
    m.dpdDescription.width = width
    m.AfterTitle.width = width
    m.AfterDescription.width = width
    m.AfterDPD.width = width
end function

function setMultistyleLabel()
    osVersion = getDeviceInfo("osVersion")
    m.ismultiStyleLabel = true
    if osVersion = invalid or osVersion < 10.5 then m.ismultiStyleLabel = false
    label = getNode().label("description", "", "font:SmallSystemFont")
    if m.ismultiStyleLabel then label = getNode().MultiStyleLabel("description")
    label.visible = false
    label.scale = [0, 0]
    m.description = label
    m.bannerHeading.insertChild(m.description,2)
end function