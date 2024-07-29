function init()
    screenSize = m.global.screenSize
    m.halfWidth = screenSize.w * 0.5
    m.height = screenSize.h
    m.titleLayout = m.top.findNode("titleLayout")
    m.heading = m.top.findNode("heading")
    m.normalDescription = m.top.findNode("normalDescription")
    m.descriptionLegal = m.top.findNode("descriptionLegal")
    m.sunGrpHeading = m.top.findNode("sunGrpHeading")
    m.privacyAnimation = m.top.findNode("privacyAnimation")
    m.privacyInterpolator = m.top.findNode("privacyInterpolator")
    m.mainRect = m.top.findNode("mainRect")
    m.actionRect = m.top.findNode("actionRect")
    m.mainGroup = m.top.findNode("mainGroup")
    m.leftArrow = m.top.findNode("leftArrow")
    m.buttonList = m.top.findNode("buttonList")
    m.subGrpListGrp = m.top.findNode("subGrpListGrp")
    m.vendorbuttonList = m.top.findNode("vendorbuttonList")
    m.buttonsListGrp = m.top.findNode("buttonsListGrp")
    m.qrCodeImg = m.top.findNode("qrCodeImg")
    m.policyLinkText = m.top.findNode("policyLinkText")
    m.policyLinkRec = m.top.findNode("policyLinkRec")
    m.IabIllustrationsRec = m.top.findNode("IabIllustrationsRec")
    m.buttonsListGrp.observeField("itemSelected", "onItemSelection")
    m.subGrpListGrp.observeField("itemSelected", "onItemSelection")
    m.vendorbuttonList.observeField("itemSelected", "onItemSelection")
    m.subGrpListGrp.observeField("itemFocused", "onItemsubGrpFocused")
    m.actionButtonList = m.top.findNode("actionButtonList")
    m.actionButtonList.observeField("itemSelected", "onItemSelection")
    m.buttonList.observeField("itemFocused", "onItemFocused")
    m.buttonInternalFocusSwitch = true
    m.subGrpItemFocused = 0
    m.buttonListPadding = 30
    m.getNode = getNode()
    m.previousviewData = []
end function

function setViewFocus(message as object)
    view = message.getRoSGNode()
    focus = view.isFocus
    if not focus
        m.buttonInternalFocusSwitch = false
    end if
    m.buttonList.setFocus(focus)
end function

function onViewData(message as object)
    view = message.getRoSGNode()
    viewData = view.viewData
    styleData = viewData.styleData
    m.parent = m.top.getParent()
    m.charsize = 60
    if viewData.buttonListWidth <> invalid
        m.buttonListWidth = viewData.buttonListWidth
    end if
    if m.height = 1080 then m.charsize = 75
    if styleData <> invalid
        m.mainRect.color = styleData.backgroundColor
        m.mainRect.width = (m.halfWidth * 2) - 50
        m.mainRect.height = m.height - (m.charsize + 60)
        m.heading.color = styleData.textColor
        m.normalDescription.color = styleData.textColor
        m.descriptionLegal.color = styleData.textColor
        m.sunGrpHeading.color = styleData.textColor
        m.leftArrow.blendColor = styleData.buttonTextColor
        m.preferenceData = m.parent.pcData
    end if
    if viewData.actionList <> invalid and viewData.actionList
        acount = viewData.actionButtonContent.getChildCount()
        m.actionButtonList.itemSize = [((2 * (m.halfWidth - 60)) - ((acount - 1) * 30)) / acount, viewData.actionButtonContentH]
        m.actionButtonList.content = viewData.actionButtonContent
        m.actionRect.width = 2 * m.halfWidth
        m.actionRect.color = styleData.backgroundColor
        m.actionRect.translation = [0, m.height - (viewData.actionButtonContentH + 2 * m.buttonListPadding)]
        m.actionRect.height = viewData.actionButtonContentH + 2 * m.buttonListPadding
    end if
    m.subGrpListGrp.itemSize = [0, 0]
    m.buttonsListGrp.itemSize = [0, 0]
    m.subGrpListGrp.content = invalid
    m.buttonsListGrp.content = invalid
    m.buttonsListGrp.scale = [0.0, 0.0]
    m.subGrpListGrp.scale = [0.0, 0.0]
    m.sunGrpHeading.scale = [0.0, 0.0]
    m.vendorbuttonList.scale = [0.0, 0.0]
    m.heading.scale = [0.0, 0.0]
    m.normalDescription.scale = [0.0, 0.0]
    m.descriptionLegal.scale = [0.0, 0.0]
    m.IabIllustrationsRec.scale = [0.0, 0.0]
    m.normalDescription.font = "font:SmallSystemFont"
    if viewData.IABVendorButton <> invalid and viewData.IABVendorButton.getChildCount() > 0
        m.vendorbuttonList.scale = [1.0, 1.0]
        m.vendorbuttonList.content = viewData.IABVendorButton
        m.vendorbuttonList.translation = [m.halfWidth * 2 * 0.3 + 60, 0]
        m.vendorbuttonList.itemSize = [m.halfWidth * 2 * 0.7 - 200, m.charsize]
    end if
    if viewData.subGrpButtonContent <> invalid and viewData.subGrpButtonContent.getChildCount() > 0
        m.subGrpListGrp.scale = [1.0, 1.0]
        if viewData.sunGrpHeading <> invalid
            m.sunGrpHeading.scale = [1.0, 1.0]
            m.sunGrpHeading.translation = [m.sunGrpHeading.translation[0], m.sunGrpHeading.translation[1] + 10]
            m.sunGrpHeading.text = viewData.sunGrpHeading
        end if
        m.subGrpListGrp.content = viewData.subGrpButtonContent
        m.subGrpListGrp.translation = [m.halfWidth * 2 * 0.3 + 60, 0]
        m.subGrpListGrp.itemSize = [m.halfWidth * 2 * 0.7 - 200, m.charsize]
        if viewData.subgroubHeights <> invalid
            m.subGrpListGrp.rowHeights = viewData.subgroubHeights
        end if
    end if
    if (viewData.buttonsListGrp <> invalid and viewData.buttonsListGrp.getChildCount() > 0) or (viewData.buttonsListIABGrp <> invalid and viewData.buttonsListIABGrp.getChildCount() > 0)
        m.buttonsListGrp.scale = [1.0, 1.0]
        isIAB = viewData.buttonsListIABGrp <> invalid and viewData.buttonsListIABGrp.getChildCount() > 0
        width = m.halfWidth * 2 * 0.7 - 200
        if isIAB
            m.buttonsListGrp.content = viewData.buttonsListIABGrp
            width = width / 2
        else
            m.buttonsListGrp.content = viewData.buttonsListGrp
        end if
        m.buttonsListGrp.translation = [m.halfWidth * 2 * 0.3 + 60, 0]
        m.buttonsListGrp.itemSize = [width, m.charsize]
    end if
    if viewData.heading <> invalid and viewData.heading <> ""
        m.heading.text = viewData.heading
        m.heading.scale = [1, 1]
    end if
    if viewData.description <> invalid and viewData.description <> ""
        ' m.normalDescription.visible = true
        m.normalDescription.scale = [1.0, 1.0]
        m.normalDescription.text = viewData.description
        m.normalDescription.width = m.halfWidth * 2 * 0.7 - 100
    end if
    if viewData.descriptionLegal <> invalid and viewData.descriptionLegal.Trim() <> ""
        m.descriptionLegal.scale = [1.0, 1.0]
        m.descriptionLegal.text = viewData.descriptionLegal
    end if
    m.titleLayout.translation = [m.halfWidth * 2 * 0.3 + 60, 0]
    m.heading.width = m.titleLayout.boundingRect().width - 50
    m.normalDescription.width = m.titleLayout.boundingRect().width - 50
    m.sunGrpHeading.width = m.normalDescription.width
    m.descriptionLegal.width = m.normalDescription.width
    m.leftArrow.translation = [m.halfWidth * 2 * 0.3 + 20, 0]
    if viewData.buttonContent <> invalid
        m.buttonList.content = viewData.buttonContent
        m.buttonList.itemClippingRect = [0, 0, m.halfWidth * 2 * 0.3, m.height - 120 - m.actionRect.height]
        m.buttonList.translation = [0, 0]
        m.buttonList.itemSize = [m.halfWidth * 2 * 0.3, m.charsize]
    end if

    if m.buttonList.rowHeights.Count() <= 0
        m.buttonList.rowHeights = m.buttonListWidth
    end if
    itemSpacings = [0, 0, 0, 0, 0, 0]
    m.policyLinkText.scale = [0.0, 0.0]
    m.qrCodeImg.scale = [0.0, 0.0]
    if viewData <> invalid and viewData.groupData <> invalid and viewData.groupData.groupRecId = "viewIllustrationBtn" 
        itemSpacings = [15, 0, 15]
        m.IabIllustrationsRec.scale = [1.0, 1.0]
        m.normalDescription.font = "font:SmallBoldSystemFont"
        setCustomIllustrations(viewData.groupData.IabIllustrations)
    end if
    if m.buttonList.itemFocused = 0
        itemSpacings = [15, 0, 15, 0, 0, 0]
        if viewData.policyLink <> invalid and viewData.policyLink.show and viewData.policyLink.urlQRCode <> invalid and viewData.policyLink.urlQRCode <> ""
            m.policyLinkText.scale = [1.0, 1.0]
            m.policyLinkText.visible = true
            m.policyLinkText.text = viewData.policyLink.text
            m.policyLinkText.width = m.titleLayout.boundingRect().width - 50
            m.policyLinkText.color = m.heading.color
            m.qrCodeImg.scale = [1.0, 1.0]
            m.qrCodeImg.visible = true
            m.qrCodeImg.loadHeight = 250
            m.qrCodeImg.loadWidth = 250
            m.qrCodeImg.width = m.qrCodeImg.loadWidth
            m.qrCodeImg.height = m.qrCodeImg.loadHeight
            m.qrCodeImg.uri = viewData.policyLink.urlQRCode
            m.qrCodeImg.blendColor = m.heading.color
        end if
    else
        m.policyLinkText.visible = false
        m.qrCodeImg.visible = false
    end if
    m.titleLayout.itemSpacings = itemSpacings
    ' get rowHeights and numRows of category list to wrap text
    if m.buttonList.content <> invalid and m.buttonListWidth <> invalid and m.buttonListWidth.count() > 0 and m.buttonList.itemFocused <> -1
        buttonlistH = 0
        numRows = 0
        btncount = m.buttonList.content.getChildCount()
        if btncount <> invalid and btncount > 0
            c = btncount - 1
            for i = 0 to c
                if m.buttonList.itemFocused = 0 or m.buttonList.itemFocused = -1 or m.buttonList.numRows >= m.buttonList.itemFocused or m.buttonList.itemFocused - m.buttonList.numRows <= i
                    buttonlistH = buttonlistH + m.buttonList.rowHeights[i]
                    if (m.height - 120 - m.actionRect.height) > buttonlistH
                        numRows = numRows + 1
                    else
                        exit for
                    end if
                end if
            end for
        end if
        m.buttonList.numRows = numRows - 1
    end if
    m.currentviewData = viewData 
end function

function onKeyEvent(key as string, press as boolean) as boolean
    handled = false
    if press
        if key = "up"
            handled = true
            itemUnfocused = m.buttonList.content.getChild(m.buttonList.itemFocused)
            if m.actionButtonList.hasFocus()
                if not itemUnfocused.isunFocused
                    m.leftArrow.visible = false
                    m.leftArrow.width = 30
                    m.leftArrow.height = 30
                    m.buttonList.setFocus(true)
                else
                    if checkButtonExists(m.buttonsListGrp)
                        m.buttonsListGrp.jumpToItem = 0
                        m.buttonsListGrp.setFocus(true)
                    else if checkButtonExists(m.vendorbuttonList)
                        m.vendorbuttonList.jumpToItem = 0
                        m.vendorbuttonList.setFocus(true)
                    else if checkButtonExists(m.subGrpListGrp)
                        m.subGrpListGrp.jumpToItem = 0
                        m.subGrpListGrp.setFocus(true)
                    else
                        m.titleLayout.setFocus(true)
                    end if
                end if
            else if isScrollable("up")
                m.titleLayout.translation = [m.titleLayout.translation[0], m.titleLayout.translation[1] + 60]
            else if m.subGrpListGrp.hasFocus() or m.vendorbuttonList.hasFocus()
                if checkButtonExists(m.vendorbuttonList) and not m.vendorbuttonList.hasFocus()
                    m.vendorbuttonList.setFocus(true)
                else if checkButtonExists(m.buttonsListGrp)
                    m.buttonsListGrp.setFocus(true)
                else 
                    handled = false
                end if
            else if not m.leftArrow.hasFocus()
                if m.buttonList.hasFocus()
                    m.buttonList.jumpToItem = 0
                    itemUnfocused = m.buttonList.content.getChild(0)
                end if
                handled = false
            end if
        else if key = "down"
            itemUnfocused = m.buttonList.content.getChild(m.buttonList.itemFocused)
            if m.buttonList.hasFocus() and m.actionButtonList.visible
                lastItem = m.buttonList.content.getChildCount() - 1
                m.buttonList.jumpToItem = lastItem
                m.actionButtonList.setFocus(true)
            else if (m.buttonsListGrp.hasFocus() or m.vendorbuttonList.hasFocus()) and m.vendorbuttonList.content <> invalid and m.vendorbuttonList.content.getChildCount() > 0 and not m.vendorbuttonList.hasFocus() and (m.vendorbuttonList.translation[1] + m.titleLayout.translation[1]) < (m.height - 300)
                m.vendorbuttonList.setFocus(true)
            else if (m.buttonsListGrp.hasFocus() or m.vendorbuttonList.hasFocus()) and m.subGrpListGrp.content <> invalid and m.subGrpListGrp.content.getChildCount() > 0 and (m.subGrpListGrp.translation[1] + m.titleLayout.translation[1]) < (m.height - 300)
                m.subGrpItemFocused = 0
                m.subGrpListGrp.jumpToItem = 0
                m.subGrpListGrp.setFocus(true)
            else if isScrollable("down") and not m.actionButtonList.hasFocus()
                m.titleLayout.translation = [m.titleLayout.translation[0], m.titleLayout.translation[1] - 60]
            else if not m.leftArrow.hasFocus()
                m.titleLayout.translation = [m.titleLayout.translation[0], 0]
                m.actionButtonList.setFocus(true)
            end if
            handled = true
        else if key = "right"
            if m.leftArrow.hasFocus()
                'm.buttonsListGrp.setFocus(true)
                m.leftArrow.width = 30
                m.leftArrow.height = 30
            end if
            if m.buttonList.hasFocus() or m.leftArrow.hasFocus()
                if checkButtonExists(m.buttonsListGrp)
                    itemUnfocused = m.buttonList.content.getChild(m.buttonList.itemFocused)
                    itemUnfocused.isunFocused = true
                    m.buttonsListGrp.setFocus(true)
                else if checkButtonExists(m.vendorbuttonList)
                    itemUnfocused = m.buttonList.content.getChild(m.buttonList.itemFocused)
                    itemUnfocused.isunFocused = true
                    m.vendorbuttonList.setFocus(true)
                else if checkButtonExists(m.subGrpListGrp)
                    itemUnfocused = m.buttonList.content.getChild(m.buttonList.itemFocused)
                    itemUnfocused.isunFocused = true
                    m.subGrpListGrp.setFocus(true)
                else if isScrollable("down")
                    itemUnfocused = m.buttonList.content.getChild(m.buttonList.itemFocused)
                    itemUnfocused.isunFocused = true
                    m.titleLayout.setFocus(true)
                end if
            end if
            handled = true
        else if key = "left"
            if m.buttonsListGrp.hasFocus() or m.subGrpListGrp.hasFocus() or m.titleLayout.hasFocus() or m.vendorbuttonList.hasFocus()
                if m.leftArrow.visible
                    m.leftArrow.setFocus(true)
                    m.leftArrow.width = 40
                    m.leftArrow.height = 40
                else
                    itemUnfocused = m.buttonList.content.getChild(m.buttonList.itemFocused)
                    itemUnfocused.isunFocused = false
                    m.buttonList.setFocus(true)
                end if
            end if
            handled = true
        else if key = "OK"
            if m.leftArrow.hasFocus()
                currentviewData = m.currentviewData
                if m.previousviewData <> invalid and m.previousviewData.count() > 0
                    m.currentviewData = invalid
                    viewdata = m.previousviewData[m.previousviewData.count() - 1]
                    m.leftArrow.visible = m.previousviewData.count() > 0
                    m.previousviewData.pop()
                end if
                if viewdata <> invalid and m.previousviewData <> invalid and m.previousviewData.count() > 0
                    m.vendorbuttonList.setFocus(true)
                    m.top.viewData = viewdata
                    m.vendorbuttonList.jumpToItem = 1
                else
                    onItemFocused()
                    m.leftArrow.visible = false
                    if currentviewData <> invalid and currentviewData.groupData <> invalid and currentviewData.groupData.groupRecId = "viewIllustrationBtn" 
                        m.vendorbuttonList.setFocus(true)
                        m.vendorbuttonList.jumpToItem = 1
                    else 
                        m.buttonsListGrp.setFocus(true)
                    end if
                end if
                m.leftArrow.width = 30
                m.leftArrow.height = 30
            end if
        end if
    end if
    return handled
end function

function checkButtonExists(buttonnode)
 return buttonnode <> invalid and buttonnode.scale[0] = 1 and buttonnode.scale[1] = 1 and buttonnode.content <> invalid and buttonnode.content.getChildCount() > 0
end function

function onKeyDownClose()
    itemUnfocused = m.buttonList.content.getChild(m.buttonList.itemFocused)
    if not itemUnfocused.isunFocused
        m.buttonList.setFocus(true)
    else
        if checkButtonExists(m.buttonsListGrp)
            m.buttonsListGrp.setFocus(true)
        else if checkButtonExists(m.vendorbuttonList)
            m.vendorbuttonList.setFocus(true)
        else if checkButtonExists(m.subGrpListGrp)
            m.subGrpListGrp.setFocus(true)
        else
            m.titleLayout.setFocus(true)
        end if
    end if
end function

function isScrollable(key)
    originalLayoutH = m.height - 120 - m.actionRect.height
    layoutH = m.heading.boundingRect().height + m.normalDescription.boundingRect().height + m.IabIllustrationsRec.boundingRect().height + m.policyLinkRec.boundingRect().height + m.descriptionLegal.boundingRect().height
    if m.buttonsListGrp.content <> invalid and m.buttonsListGrp.content.getChildCount() > 0
        layoutH = layoutH + m.buttonsListGrp.boundingRect().height
    end if
    if m.vendorbuttonList.content <> invalid and m.vendorbuttonList.content.getChildCount() > 0
        layoutH = layoutH + m.vendorbuttonList.boundingRect().height
    end if
    if m.subGrpListGrp.content <> invalid and m.subGrpListGrp.content.getChildCount() > 0
        layoutH = layoutH + m.subGrpListGrp.boundingRect().height + m.sunGrpHeading.boundingRect().height
    end if
    if key = "down"
        return layoutH > originalLayoutH and (-m.titleLayout.translation[1] + originalLayoutH) < layoutH
    else
        return layoutH > originalLayoutH and m.titleLayout.translation[1] <> 0
    end if
end function

function getListChildCount() as integer
    return m.buttonList.content.getChildCount()
end function

function onItemSelection(node as object)
    list = node.getRoSGNode()
    selectedItem = list.itemSelected
    item = list.content.getChild(selectedItem)
    if item.groupRecId = "subGrpListGrp"
        'onRightPress()
        m.previousviewData.push(m.currentviewData)
        m.leftArrow.visible = true
        if checkButtonExists(m.buttonsListGrp)
            m.buttonsListGrp.setFocus(true)
        else if checkButtonExists(m.vendorbuttonList)
            m.vendorbuttonList.setFocus(true)
        end if
    end if
    if item.groupRecId = "viewIllustrationBtn" and item.groupData <> invalid and item.groupData.type = "qrCodeIllustrations"
        qrCodeDialog(item)
    else
        if item.groupRecId = "viewIllustrationBtn" and item.groupData <> invalid and item.groupData.type = "customIllustrations"
            m.previousviewData.push(m.currentviewData)
            m.leftArrow.visible = true
        end if
        m.top.itemSelected = item
    end if
end function

function onGroupUpdate(message as object)
    view = message.getRoSGNode()
    groups = view.updateGroups
    btncount = m.buttonsListGrp.content.getChildCount()
    if btncount > 0
        c = btncount - 1
        for i = 0 to c
            item = m.buttonsListGrp.content.getChild(i)
            if groups.doesExist(getGroupId(item, item.CustomGroupId))
                item.status = groups[getGroupId(item, item.CustomGroupId)]
            end if
        end for
    end if
    if m.subGrpListGrp.content <> invalid
        subBtncount = m.subGrpListGrp.content.getChildCount()
        if subBtncount <> invalid and subBtncount > 0
            c = subBtncount - 1
            for i = 0 to c
                item = m.subGrpListGrp.content.getChild(i)
                if groups.doesExist(getGroupId(item, item.CustomGroupId))
                    item.status = groups[getGroupId(item, item.CustomGroupId)]
                end if
            end for
        end if
    end if
end function

function getGroupId(item, id)
    if item.groupRecId <> invalid and item.groupRecId = "buttonsListLIGrp"
        return "Li_" + id
    else
        return id
    end if
end function

function onItemFocused() as void
    if not m.buttonInternalFocusSwitch
        m.buttonInternalFocusSwitch = true
        return
    end if
    itemFocused = m.buttonList.itemFocused
    item = m.buttonList.content.getChild(itemFocused)
    if m.top.itemFocused = invalid or m.top.itemFocused.OptanonGroupId <> item.OptanonGroupId or m.leftArrow.visible
        m.top.itemFocused = item
    end if
end function

function onItemsubGrpFocused() as void
    subGrpItemFocused = m.subGrpListGrp.itemFocused
    if m.subGrpItemFocused <> subGrpItemFocused
        if m.subGrpItemFocused > subGrpItemFocused and isScrollable("up")
            m.titleLayout.translation = [m.titleLayout.translation[0], m.titleLayout.translation[1] + m.subGrpListGrp.rowHeights[subGrpItemFocused] + 10]
        else if m.subGrpItemFocused < subGrpItemFocused and isScrollable("down")
            m.titleLayout.translation = [m.titleLayout.translation[0], m.titleLayout.translation[1] - m.subGrpListGrp.rowHeights[subGrpItemFocused] - 10]
        end if
    end if
    m.subGrpItemFocused = subGrpItemFocused
end function

function setVendorViewFocus()
    if m.vendorbuttonList.scale[0] = 1
        m.vendorbuttonList.setFocus(true)
    else
        vendortype = 0
        if m.top.isVendorFocus = "google" then vendortype = 1
        m.buttonsListGrp.setFocus(true)
        m.buttonsListGrp.jumpToItem = vendortype
    end if
end function

function qrCodeDialog(item)
    currDialog = createObject("roSGNode", "qrCodeDialog")
    currDialog.id = "qrCodeIllustrations"
    currDialog.show = true
    currDialog.qrCodeLightColor = item.focusButtonColor
    currDialog.qrCodeDarkColor = item.focusButtonTextColor
    currDialog.headerColor = item.focusButtonTextColor
    currDialog.headerText = m.preferenceData.fullLegalText
    currDialog.uri = m.preferenceData.IabLegalTextUrl
    if currDialog <> invalid
        m.top.getScene().dialog = currDialog
    end if
end function

function setCustomIllustrations(IabIllustrations)
    child = m.IabIllustrationsRec.getChild(0)
    if child <> invalid then m.IabIllustrationsRec.removeChild(child)
    fragment = m.getNode.layoutGroup("fragment", "vert", [15])
    m.IabIllustrationsRec.appendChild(fragment)
    if IabIllustrations <> invalid and IabIllustrations.count() > 0
        Illsutrationcount = IabIllustrations.count() - 1
        for item = 0 to Illsutrationcount step 1
            label = m.getNode.label("IabIllustration_" + item.ToStr(), IabIllustrations[item], "font:SmallSystemFont", m.normalDescription.color, m.normalDescription.width)
            fragment.appendChild(label)
            if Illsutrationcount <> item
                horzLine = m.getNode.rectangle("horzLine", m.normalDescription.color, m.normalDescription.width, 1)
                horzLine.opacity = "0.5"
                fragment.appendChild(horzLine)
            end if
        end for
    end if
end function
