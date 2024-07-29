sub init()
    m.logo = m.top.findNode("logo")
    m.logo.observeField("loadStatus", "onDisplayLogo")
    m.groupRect = m.top.findNode("groupRect")
    m.headersection = m.top.findNode("headersection")
    m.headerRect = m.top.findNode("headerRect")
    m.close = m.top.findNode("close")
    m.closetextList = m.top.findNode("closetextList")
    m.closetextList.observeField("itemSelected", "onCloseButtonSelected")
    m.btnSizetext = m.top.findNode("btnSizetext")
    m.overlayXRect = m.top.findNode("overlayXRect")
    m.overlayYRect = m.top.findNode("overlayYRect")
    m.fontSizeText = m.top.findNode("fontSizeText")
    m.buttonContent = []
    m.groupdetails = {}
    m.screenSize = m.global.screenSize
    m.overlayYRect.translation = [0, m.screenSize.h]
    m.overlayxRect.translation = [m.screenSize.w, 0]
    m.poweredLogo = m.top.findNode("poweredLogo")
    m.poweredLogo.translation = [m.screenSize.w - m.poweredLogo.width - 50, m.screenSize.h - m.poweredLogo.height - 7]
    m.padding = 50
    m.innerPadding = 15
    m.actionButtonContentH = 0
end sub

function onPreferenceData()
    m.preferenceData = m.top.pcData
    if m.preferenceData.keys().count() > 0
        styleData = m.preferenceData.styleData
        m.groupRect.color = styleData.backgroundColor
        m.groupRect.width = m.screenSize.w
        m.groupRect.height = m.screenSize.h
        m.headersection.color = m.groupRect.color
        m.headersection.width = m.screenSize.w
        m.headerRect.color = m.groupRect.color
        m.headerRect.translation = [m.padding, m.padding]
        m.headerRect.height = m.headersection.height - m.padding
        m.headerRect.width = m.headersection.width - 2 * m.headerRect.translation[0]

        m.focusedIndex = 0
        if m.preferenceData.doesExist("logoSize")
            if m.preferenceData.logoSize.doesExist("width")
                m.logo.loadWidth = m.preferenceData.logoSize.width
                m.logo.width = m.preferenceData.logoSize.width
            end if
            if m.preferenceData.logoSize.doesExist("height")
                height = m.preferenceData.logoSize.height
                m.logo.loadHeight = height
                m.logo.height = height
            end if
        end if
        if m.preferenceData.logo <> invalid and m.preferenceData.logo.show
            m.logo.visible = true
            m.logo.uri = getLogo(m.preferenceData.logo)
        end if
        m.buttonContent = []
        groupData = getParentGroups()
        if m.preferenceData.isIAB <> invalid and m.preferenceData.isIAB
            vendorData = getVendorList()
            groupData.Unshift(vendorData)
        end if
        privacyNode = getPrivacy()
        groupData.Unshift(privacyNode)
        m.fontSizeText.width = (m.screenSize.w * 0.3) - 24
        m.groupNode = getGroupListData(groupData)
        preference = isPreference(m.preferenceData)
        if preference <> ""
            preferenceStyle = {}
            preferenceStyle.buttonColor = styleData.pcbuttonColor
            preferenceStyle.textColor = styleData.pcbuttonTextColor
            preferenceStyle.focusButtonColor = styleData.pcbuttonFocusColor
            preferenceStyle.focusTextColor = styleData.pcbuttonTextFocusColor
            preferenceStyle.textData = preference
            preferenceStyle.id = "confirmMyChoice"
            m.buttonContent.push(preferenceStyle)
        end if
        accept = isAccept(m.preferenceData)
        if accept <> ""
            acceptStyle = {}
            acceptStyle.buttonColor = styleData.acceptbuttonColor
            acceptStyle.textColor = styleData.acceptbuttonTextColor
            acceptStyle.focusButtonColor = styleData.acceptbuttonFocusColor
            acceptStyle.focusTextColor = styleData.acceptbuttonTextFocusColor
            acceptStyle.textData = accept
            acceptStyle.id = "acceptAll"
            m.buttonContent.push(acceptStyle)
        end if
        refuse = isRefuse(m.preferenceData)
        if refuse <> ""
            refuseStyle = {}
            refuseStyle.buttonColor = styleData.rejectbuttonColor
            refuseStyle.textColor = styleData.rejectbuttonTextColor
            refuseStyle.focusButtonColor = styleData.rejectbuttonFocusColor
            refuseStyle.focusTextColor = styleData.rejectbuttonTextFocusColor
            refuseStyle.textData = refuse
            refuseStyle.id = "rejectAll"
            m.buttonContent.push(refuseStyle)
        end if
        m.viewDataParams = {}
        buttonContent = getButtonList(m.buttonContent, "actionBtn")
        m.viewDataParams.AddReplace("actionButtonContent", buttonContent)
        m.viewDataParams.AddReplace("actionButtonContentH", m.actionButtonContentH)
        addButtonlistFeilds()
        if m.preferenceData.buttons.closeButton.show
            closeButton = m.preferenceData.buttons.closeButton
            if closeButton.showText
                m.closetextList.visible = true
                closeBtn = []
                data = {}
                data.buttonColor = closeButton.color
                if closeButton.showAsLink then data.buttonColor = styleData.backgroundColor
                data.textColor = closeButton.textColor
                data.focusButtonColor = styleData.acceptbuttonFocusColor
                data.focusTextColor = styleData.acceptbuttonTextFocusColor
                data.textData = closeButton.text
                data.groupRecId = "closetextList"
                data.id = "closeText"
                closeBtn.push(data)
                paddingH = 12
                if m.screenSize.h = 1080 then paddingH = 15
                translationY = paddingH
                m.btnSizetext.maxLines = 2
                maxClosewidth = m.screenSize.w * 0.4
                m.btnSizetext.text = closeButton.text
                itemSize = m.btnSizetext.boundingRect()
                if itemSize.width > maxClosewidth
                    m.btnSizetext.width = maxClosewidth
                    itemSize = m.btnSizetext.boundingRect()
                    translationY += 2 * paddingH
                end if
                m.closetextList.itemSize = [itemSize.width + 2 * paddingH, itemSize.height + 2 * paddingH]
                m.closetextList.translation = [m.headerRect.width - m.closetextList.itemSize[0], -translationY]
                m.closetextList.content = getButtonList(closeBtn, "closeBtn")
            else
                m.close.font.size = 30
                m.close.color = styleData.textColor
                closeWidth = m.close.boundingRect().width
                m.close.translation = [m.headerRect.width - closeWidth, 0]
                m.close.visible = true
            end if
        end if
        m.top.onShowPreferenceCenter = true
    end if
end function

function addButtonlistFeilds()
    m.viewDataParams.AddReplace("buttonListWidth", m.buttonListWidth)
    m.viewDataParams.AddReplace("actionList", true)
    setGroupsList(m.groupNode, m.viewDataParams)
    m.groupRect.getChild(m.focusedIndex).isFocus = true
end function

function setGroupsList(groupNode as dynamic, params = {} as object) as object
    viewData = {}
    if params.keys().count() > 0
        viewData.append(params)
    end if
    view = CreateObject("roSGNode", "OTPCGroupView")
    if groupNode <> invalid
        view.observeField("itemSelected", "onItemSelection")
        view.observeField("itemFocused", "onItemFocused")
    end if
    view.childIndex = m.groupRect.getChildCount()
    item = groupNode.getChild(view.childIndex)
    if item <> invalid
        viewData.heading = item.name
        viewData.description = item.description
    end if
    viewData.buttonContent = groupNode
    viewData.styleData = m.preferenceData.styleData
    view.viewData = viewData
    view.id = "group" + Str(m.groupRect.getChildCount())
    m.groupRect.appendChild(view)
end function

function onRightPress(view as object)
    viewNode = view.getRoSGNode()
    groupDetail = viewNode.groupDetail
    if groupDetail <> invalid
        params = {}
        params.heading = groupDetail.GroupName
        if groupDetail.showDescription
            params.description = getGroupDescription(groupDetail)
        end if
        groupData = getSubGroups(groupDetail.OptanonGroupId)
        groupNode = getGroupListData(groupData)
        setGroupsList(groupNode, params)
    end if
    for fChild = m.focusedIndex to 0 step -1
        groupItem = m.groupRect.getChild(fChild)
        groupItem.rightPress = true
    end for
end function

function onLeftPress()
    childCount = m.groupRect.getChildCount() - 1
    for rChild = childCount to m.focusedIndex + 1 step -1
        view = m.groupRect.getChild(rChild)
        if view.buttonContent <> invalid
            view.unObserveField("itemSelected")
            view.unObserveField("itemFocused")
        end if
        view.unObserveField("isRightPressed")
        view.unObserveField("isLeftPressed")
        m.groupRect.removeChildIndex(rChild)
    end for
    for fChild = m.focusedIndex to 0 step -1
        groupItem = m.groupRect.getChild(fChild)
        groupItem.leftPress = true
    end for
end function

function isAccept(data as object) as string
    return data.ConfirmText
end function

function isRefuse(data as object) as string
    if data.PCenterShowRejectAllButton
        return data.PCenterRejectAllButtonText
    end if
    return ""
end function

function isPreference(data as object) as string
    return data.PreferenceCenterConfirmText
end function

function getLogo(data as object) as string
    logoString = data.url
    if logoString <> "" and Instr(1, logoString, ".svg") = 0
        return data.url
    end if
    return "pkg:/components/OTPublishersSDK/images/ic_ot.png"
end function

function getButtonList(buttonList as object, btnName as string) as object
    data = CreateObject("roSGNode", "ContentNode")
    m.actionButtonContentH = 0
    if btnName = "actionBtn"
        acount = buttonList.count()
        paddingBtnButtons = 2 * m.innerPadding
        width = ((m.screenSize.w - (2 * m.padding)) - ((acount - 1) * paddingBtnButtons)) / acount
        m.fontSizeText.width = width
        m.fontSizeText.maxLines = 2
    end if
    for each b in buttonList
        dataItem = data.CreateChild("OTGroupListData")
        dataItem.name = b.textData
        dataItem.buttonColor = b.buttonColor
        dataItem.buttonTextColor = b.textColor
        dataItem.focusButtonColor = b.focusButtonColor
        dataItem.focusButtonTextColor = b.focusTextColor
        dataItem.id = b.id
        if b.groupRecId <> invalid then dataItem.groupRecId = b.groupRecId
        if btnName = "actionBtn"
            m.fontSizeText.text = dataItem.name
            height = m.fontSizeText.boundingRect().height + 30
            if m.actionButtonContentH < height then
                m.actionButtonContentH = height
            end if
        end if
    end for
    return data
end function

function getGroupListData(groups as object) as object
    data = CreateObject("roSGNode", "ContentNode")
    m.buttonListWidth = []
    filteredSupportPurposes = optionalChaining(m.global._OT_IABVendor_data, "iab.filteredSupportPurposes")
    mainLabel = getNode().label("mainLabel", "")
    mainLabel.width = m.fontSizeText.width
    mainLabel.font.size = 20
    mainLabel.font = "font:MediumSystemFont"
    if isIAB2V2() then mainLabel.font = "font:MediumBoldSystemFont"
    subLabel = getNode().label("subLabel", "", "font:SmallSystemFont")
    subLabel.width = m.fontSizeText.width
    for each b in groups
    additionalText = getVendorCountText(b, filteredSupportPurposes)
    if isSubGroup(b)
        parentGroup = getParent(b.Parent)
        if parentGroup.ShowSubgroup
            dataItem = createChild(b)
            dataItem.additionalText = additionalText
            dataItem.isToggleOption = parentGroup.ShowSubgroupToggle
            dataItem.showDescription = parentGroup.ShowSubGroupDescription
            mainLabel.text = b.GroupName
            textH = mainLabel.boundingRect().height
            if dataItem.additionalText <> invalid and dataItem.additionalText <> "" 
                subLabel.text = dataItem.additionalText
                textH = textH + subLabel.boundingRect().height + 10
            end if
            m.buttonListWidth.push(textH + 30)
            data.appendChild(dataItem)
        end if
    else
        GroupName = b.GroupName
        dataItem = createChild(b)
        dataItem.additionalText = additionalText
        mainLabel.text = GroupName
        textH = mainLabel.boundingRect().height
        if dataItem.additionalText <> invalid and dataItem.additionalText <> "" 
            subLabel.text = dataItem.additionalText
            textH = textH + subLabel.boundingRect().height + 10
        end if
        m.buttonListWidth.push(textH + 30)
        data.appendChild(dataItem)
        end if
    end for
    return data
end function

function getVendorCountText(params, filteredSupportPurposes)
    countText = ""
    if isIAB2V2() and m.preferenceData.PCVendorsCountText <> invalid and (params.groupRecId = "pcGroupList" or params.groupRecId = "subGrpListGrp")
    subGroups = getSubGroups(params.OptanonGroupId, true)
    if params.OptanonGroupId <> invalid and ((params.IsIabPurpose <> invalid and params.IsIabPurpose) or (subGroups <> invalid and subGroups.count() > 0))
        vFilterList = {}
        if optionalChaining(filteredSupportPurposes, params.OptanonGroupId.toStr()) <> invalid then vFilterList.append(filteredSupportPurposes[params.OptanonGroupId])
        for each sg in subGroups
            if optionalChaining(filteredSupportPurposes, sg.OptanonGroupId.toStr()) <> invalid then vFilterList.append(filteredSupportPurposes[sg.OptanonGroupId])
        end for
        vcount = vFilterList.keys().count()
        if vcount <> invalid and vcount > 0 then countText = m.preferenceData.PCVendorsCountText.replace("[VENDOR_NUMBER]",vcount.toStr()) 
    end if
end if
    return countText
end function

function getvendorListData(groups as object) as object
    data = CreateObject("roSGNode", "ContentNode")
    for each b in groups
        dataItem = createChild(b)
        data.appendChild(dataItem)
    end for
    return data
end function

function getPrivacy()
    title = ""
    if optionalChaining(m.preferenceData, "summary.title.text") <> invalid and optionalChaining(m.preferenceData, "summary.title.show") and m.preferenceData.summary.title.text <> ""
        title = m.preferenceData.summary.title.text
    else
        title = m.preferenceData.MainText
    end if
    dataItem = {}
    dataItem.GroupName = title
    dataItem.GroupDescription = m.preferenceData.MainInfoText
    dataItem.policyLink = m.preferenceData.policyLink
    dataItem.groupRecId = "pcGroupList"
    dataItem.Type = "privacy"
    dataItem.Parent = ""
    return dataItem
end function

function getVendorList()
    vendorData = {}
    vendorData.GroupName = m.preferenceData.MenuVendorListText
    vendorData.GroupDescription = ""
    vendorData.groupRecId = "pcGroupList"
    vendorData.Type = "vendor"
    vendorData.Parent = ""
    vendorData.HasListofpartners = true
    vendorData.OptanonGroupId = "vendorsGrpList"
    return vendorData
end function

function createChild(b as object) as object
    dataItem = CreateObject("roSGNode", "OTGroupListData")
    dataItem.name = b.GroupName
    dataItem.description = getGroupDescription(b)
    dataItem.descriptionLegal = getGroupDescriptionLegal(b)
    dataItem.status = b.status
    dataItem.additionalText = b.additionalText
    if b.CustomGroupId <> invalid and b.status <> invalid
        if b.grouprecid <> "buttonsListLIGrp" then m.groupdetails.AddReplace(b.CustomGroupId, b.status)
        if b.li_status = invalid
            m.groupdetails.AddReplace("Li_" + b.CustomGroupId, "active")
        else
            m.groupdetails.AddReplace("Li_" + b.CustomGroupId, b.li_status)
        end if
    end if
    dataItem.CustomGroupId = b.CustomGroupId
    dataItem.purposeId = b.PurposeId
    dataItem.OptanonGroupId = b.OptanonGroupId
    dataItem.groupData = b
    dataItem.buttonColor = m.preferenceData.styleData.buttonColor
    dataItem.buttonTextColor = m.preferenceData.styleData.buttonTextColor
    dataItem.focusButtonColor = m.preferenceData.styleData.buttonFocusColor
    dataItem.focusButtonTextColor = m.preferenceData.styleData.buttonTextFocusColor
    dataItem.activeTextColor = m.preferenceData.styleData.activeTextColor
    dataItem.activeColor = m.preferenceData.styleData.activeColor
    dataItem.alwaysActiveText = m.preferenceData.AlwaysActiveText
    dataItem.activeText = m.preferenceData.activeText
    dataItem.inactiveText = m.preferenceData.inactiveText
    dataItem.BConsentText = m.preferenceData.BConsentText
    dataItem.BLegitInterestText = m.preferenceData.BLegitInterestText
    dataItem.groupRecId = b.groupRecId
    dataItem.isunFocused = false
    return dataItem
end function

function isSubGroup(groupData as object) as boolean
    return groupData.Parent <> ""
end function

function getParentGroups() as object
    groups = ParseJson(FormatJson(m.preferenceData.Groups))
    parentGroups = []
    for each grp in groups
        if not isSubGroup(grp)
            if m.groupdetails.doesExist(grp.OptanonGroupId)
                grp.status = m.groupdetails[grp.OptanonGroupId]
            end if
            if m.groupdetails.doesExist("Li_" + grp.OptanonGroupId)
                grp.li_status = m.groupdetails["Li_" + grp.OptanonGroupId]
            end if
            grp.groupRecId = "pcGroupList"
            parentGroups.push(grp)
        end if
    end for
    return parentGroups
end function

function getSubGroups(groupId as dynamic, isiabPurpose = false as boolean) as object
    groups = m.preferenceData.Groups
    subGroups = []
    if groupId = invalid return subGroups
    for each grp in groups
        if grp.Parent = groupId and grp.Parent <> "" and (not isiabPurpose or (isiabPurpose and grp.IsIabPurpose <> invalid and grp.IsIabPurpose))
            if m.groupdetails.doesExist(grp.OptanonGroupId)
                grp.status = m.groupdetails[grp.OptanonGroupId]
            end if
            if m.groupdetails.doesExist("Li_" + grp.OptanonGroupId)
                grp.li_status = m.groupdetails["Li_" + grp.OptanonGroupId]
            end if
            grp.groupRecId = "subGrpListGrp"
            subGroups.push(grp)
        end if
    end for
    return subGroups
end function

function getParent(parentId as string) as object
    groups = m.preferenceData.Groups
    for each grp in groups
        if grp.OptanonGroupId = parentId
            return grp
        end if
    end for
end function

function onKeyEvent(key as string, press as boolean) as boolean
    handled = false
    if press
        if key = "back"
            m.top.onHidePreferenceCenter = true
            handled = true
        else if key = "right"
            '  nextChildFocus = m.focusedIndex + 1
            '  if nextChildFocus < m.groupRect.getChildCount()
            '      nextView = m.groupRect.getChild(nextChildFocus)
            '     isFocusChild = nextView.callFunc("isFocusChild",{})
            '     if isFocusChild
            '         m.groupRect.getChild(m.focusedIndex).isFocus = false
            '         m.focusedIndex = nextChildFocus
            '         m.groupRect.getChild(nextChildFocus).isFocus = true
            '    end if
            'end if
            handled = true
        else if key = "left"
            if not m.close.hasFocus()
                '  nextChildFocus = m.focusedIndex - 1
                '  if nextChildFocus >= 0
                '      nextView = m.groupRect.getChild(nextChildFocus)
                '      isFocusChild = nextView.callFunc("isFocusChild",{})
                '      if isFocusChild
                '          m.groupRect.getChild(m.focusedIndex).isFocus = false
                '         m.focusedIndex = nextChildFocus
                '          m.groupRect.getChild(nextChildFocus).isFocus = true
                '     end if
                ' end if
            end if
            handled = true
        else if key = "up"
            '  m.groupRect.getChild(m.focusedIndex).isFocus = false
            ' (m.closetextList.visible or m.close.visible)
            setCloseButtonFocus()
            handled = true
        else if key = "down"
            handled = true
            if m.close.hasFocus() or m.closetextList.hasFocus()
                nextView = m.groupRect.getChild(m.focusedIndex)
                nextView.callFunc("onKeyDownClose")
                m.close.font.size = 30
            end if
        else if key = "OK"
            if m.close.hasFocus()
                m.top.onHidePreferenceCenter = true
            end if
            handled = true
        end if
    end if
    return handled
end function

function setCloseButtonFocus()
    if m.close.visible
        m.close.setFocus(true)
        m.close.font.size = 40
    else if m.closetextList.visible
        m.closetextList.setFocus(true)
    end if
end function

function onCloseButtonSelected()
    m.top.onHidePreferenceCenter = true
end function

function onItemSelection(message as object)
    view = message.getRoSGNode()
    item = view.itemSelected
    pcData = m.top.pcData
    if item <> invalid
        if item.groupData = invalid
            if item.name = isAccept(pcData)
                m.top.onPreferenceCenterAcceptAll = true
            else if item.name = isRefuse(pcData)
                m.top.onPreferenceCenterRejectAll = true
            else if item.name = isPreference(pcData)
                m.top.onPreferenceCenterConfirmChoices = true
            end if
        else if item.groupRecId = "IABVendorButton" or item.groupRecId = "buttonsListIABGrp" or item.groupRecId = "sdkListButton"
            filterType = { "vendorType": item.groupData.type, supFilterdetails: {} }
            if item.groupRecId = "IABVendorButton" or item.groupRecId = "sdkListButton"
                if not isIab_STACK(optionalChaining(item, "groupData.grouptype"))
                    filterType.supFilterdetails.AddReplace(item.CustomGroupId, "active")
                end if
                if isIab_STACK(optionalChaining(item, "groupData.grouptype")) or item.groupRecId = "sdkListButton"
                    subGroups = getSubGroups(item.groupData["CustomGroupId"])
                    for each sg in subGroups
                        filterType.supFilterdetails.AddReplace(sg.CustomGroupId, "active")
                    end for
                end if
            end if
            m.global.OTsdk.callFunc("showVendorListUI", filterType)
        else
            status = item.status
            if status <> "always active"
                updatedStatus = getUpdatedStatus(status)
                if updatedStatus = "active"
                    Bstatus = true
                else
                    Bstatus = false
                end if
                g = {}
                g.AddReplace("id", item.groupData["OptanonGroupId"])
                g.AddReplace("status", Bstatus)
                if item.groupRecId <> "subGrpListGrp"
                    m.global.OTsdk.callFunc("updatePurposeConsent", g, item.groupRecId)
                    if not isSubGroup(item.groupData)
                        if item.groupRecId = "buttonsListGrp"
                            subGroups = getSubGroups(item.groupData["OptanonGroupId"])
                            for each sg in subGroups
                                if sg.Status <> "always active"
                                    m.groupdetails.AddReplace(getGroupId(item, sg.CustomGroupId), updatedStatus)
                                end if
                            end for
                        end if
                        m.groupdetails.AddReplace(getGroupId(item, item.CustomGroupId), updatedStatus)
                    else
                        if item.groupRecId = "buttonsListGrp" or item.groupRecId = "buttonsListLIGrp"
                            m.groupdetails.AddReplace(getGroupId(item, item.CustomGroupId), updatedStatus)
                            if item.groupRecId = "buttonsListGrp"
                                parentData = getParent(item.groupData["Parent"])
                                subGroups = getSubGroups(parentData["OptanonGroupId"])
                                parentStatus = "active"
                                for each sGroups in subGroups
                                    substatus = sGroups.status
                                    if m.groupdetails.doesExist(getGroupId(item, sGroups.CustomGroupId))
                                        substatus = m.groupdetails[getGroupId(item, sGroups.CustomGroupId)]
                                    end if
                                    if substatus <> "always active" and substatus <> "active"
                                        parentStatus = "inactive"
                                        exit for
                                    end if
                                end for
                                m.groupdetails.AddReplace(getGroupId(item, parentData.CustomGroupId), parentStatus)
                            end if
                        end if
                    end if
                end if
                for fChild = 0 to m.groupRect.getChildCount() - 1
                    groupItem = m.groupRect.getChild(fChild)
                    groupItem.updateGroups = m.groupdetails
                end for
            end if
            if item.groupRecId = "subGrpListGrp" or item.groupRecId = "viewIllustrationBtn" then updateGroupItem(item)
        end if
    end if
    view.itemSelected = invalid
end function

function getGroupId(item, id)
    if item.groupRecId <> invalid and item.groupRecId = "buttonsListLIGrp"
        return "Li_" + id
    else
        return id
    end if
end function

function getUpdatedStatus(status as string) as string
    if status = "active"
        return "inactive"
    else if status.Instr("inactive") <> -1
        return "active"
    end if
end function

function updateLocalGroupData(uGroups as object)
    groups = m.preferenceData.Groups
    g = []
    for each grp in groups
        if uGroups.doesExist(grp["CustomGroupId"])
            grp.status = uGroups[grp["CustomGroupId"]]
        end if
        g.push(grp)
    end for
    m.preferenceData.Groups = g
end function

function onItemFocused(message as object) as void
    m.itemFocusedView = message
    view = message.getRoSGNode()
    item = view.itemFocused
    updateGroupItem(item)
end function

function updateGroupItem(item)
    child = m.groupRect.getChild(m.focusedIndex)
    params = {}
    isvendorList = false
    params.heading = item.name
    if optionalChaining(item, "groupData.GroupName") <> invalid then params.heading = item.groupData.GroupName
    params.description = item.description
    params.descriptionLegal = item.descriptionLegal
    if item.groupData.policyLink <> invalid then params.policyLink = item.groupData.policyLink
    if item.groupRecId = "viewIllustrationBtn"
        params.heading = item.groupData.GroupHeading
        params.description = item.groupData.GroupSubHeading
        params.groupRecId = item.groupRecId
        params.groupData = item.groupData
    end if
    if item.groupData.type <> "privacy" and item.groupRecId <> "viewIllustrationBtn"
        buttonData = []
        buttonFilterData = []
        if item.groupData.type <> "vendor"
            parentData = invalid
            if item.groupRecId = "subGrpListGrp" then parentData = getParent(item.groupData["Parent"])
            if parentData <> invalid and not parentData.ShowSubGroupDescription and item.groupRecId = "subGrpListGrp"
                params.description = ""
                params.descriptionLegal = ""
            end if
            if item.groupRecId <> "subGrpListGrp"
                groupData = getSubGroups(item.OptanonGroupId)
                if groupData.count() > 0
                    subgrpRecMargin = 100
                    subgrpTextLMargin = 120
                    subgrpTextPadding = 16
                    m.fontSizeText.width = m.screenSize.w * 0.7 - (2 * subgrpRecMargin) - subgrpTextLMargin - subgrpTextPadding
                    groupNode = getGroupListData(groupData)
                    params.subgroubHeights = m.buttonListWidth
                    params.subGrpButtonContent = groupNode
                    params.sunGrpHeading = m.preferenceData.subCategoryHeaderText
                end if
            end if
            if (((item.groupData.HasConsentOptOut = true and item.groupData.status <> "always active") or (item.groupData.status = "always active" and m.preferenceData.AlwaysActiveText <> "")) and item.groupRecId = "pcGroupList") or (item.groupData.HasConsentOptOut = true and parentData <> invalid and parentData.ShowSubgroupToggle and item.groupRecId = "subGrpListGrp")
                buttonData = getConsentData(item)
            end if
            if isLegitimateInterest(item.groupData, m.preferenceData.LegIntSettings)
                liData = getLIdata(item)
                buttonData.Push(liData)
            end if
        end if
        if item.groupData.showPartnersIAB <> invalid and item.groupData.IsIabPurpose <> invalid and item.groupData.showPartnersIAB and item.groupData.IsIabPurpose and not isIab_STACK(optionalChaining(item, "groupData.Type"))
            vendorData = getVendorList()
            partners = getListOfPartners(vendorData)
            partners.GroupName = m.preferenceData.BannerIABPartnersLink
            partners.Parent = item.groupData.OptanonGroupId
            buttonData.Push(partners)
            isvendorList = true
        end if
        if item.groupData.HasListofpartners <> invalid and item.groupRecId = "pcGroupList"
            partners = getListOfPartners(item)
            buttonData.Push(partners)
            if m.preferenceData.UseGoogleVendors
                googlePartners = getListOfGooglePartners(item)
                buttonData.Push(googlePartners)
            end if
            isvendorList = true
        end if
        if optionalChaining(item, "groupData.IsIabPurpose") <> invalid and item.groupData.IsIabPurpose
            partners = getListOfIABButton(item)
            buttonFilterData.push(partners)
        end if
        if m.preferenceData.ShowCookieList <> invalid and m.preferenceData.ShowCookieList and item.groupData.ShowSDKListLink <> invalid and item.groupData.ShowSDKListLink and item.groupData.FirstPartyCookies <> invalid and item.groupData.FirstPartyCookies.count() > 0
            sdkButton = getsdkButton(item)
            buttonFilterData.push(sdkButton)
        end if
        if isIAB2V2() and optionalChaining(m.preferenceData, "fullLegalText") <> invalid and m.preferenceData.fullLegalText <> "" and optionalChaining(item, "groupData.IsIabPurpose") <> invalid and item.groupData.IsIabPurpose
            if optionalChaining(item, "groupData.IabIllustrations") <> invalid and item.groupData.IabIllustrations.count() > 0
                illustrationButton = getViewIllustrationBtn(item, "customIllustrations")
                buttonFilterData.push(illustrationButton)
            end if
        else if optionalChaining(item, "groupData.IsIabPurpose") <> invalid and item.groupData.IsIabPurpose and m.preferenceData.PCGrpDescType <> invalid and m.preferenceData.PCGrpDescType = "user_friendly" and optionalChaining(m.preferenceData, "fullLegalText") <> invalid and optionalChaining(m.preferenceData, "IabLegalTextUrl") <> invalid and m.preferenceData.fullLegalText <> "" and m.preferenceData.IabLegalTextUrl <> ""
            illustrationButton = getViewIllustrationBtn(item, "qrCodeIllustrations")
            buttonFilterData.push(illustrationButton)
        end if
        if buttonFilterData.count() > 0
            params.IABVendorButton = getvendorListData(buttonFilterData)
        end if
        if buttonData.count() > 0
            if isvendorList = true
                buttonNode = getvendorListData(buttonData)
                params.buttonsListIABGrp = buttonNode
            else
                buttonNode = getGroupListData(buttonData)
                params.buttonsListGrp = buttonNode
            end if
        end if
    end if
    if child <> invalid
        child.viewData = params
    end if
end function
function getGroupDescription(groupDetail as object) as string
    description = ""
    if groupDetail.doesExist("GroupDescriptionOTT") and groupDetail.GroupDescriptionOTT <> invalid and groupDetail.GroupDescriptionOTT <> ""
        description = groupDetail.GroupDescriptionOTT
    else
        description = groupDetail.GroupDescription
    end if
    return StringRemoveHTMLTags(description)
end function

function getGroupDescriptionLegal(groupDetail as object) as string
    description = ""
    if groupDetail.doesExist("DescriptionLegal") and groupDetail.DescriptionLegal <> invalid and groupDetail.DescriptionLegal.Trim() <> ""
        description = groupDetail.DescriptionLegal
    end if
    return StringRemoveHTMLTags(description)
end function

function StringRemoveHTMLTags(baseStr as string) as string
    r = createObject("roRegex", "<[^<]+?>", "i")
    return r.replaceAll(baseStr, "")
end function

function getConsentData(data)
    groups = ParseJson(FormatJson(m.preferenceData.Groups))
    consentData = []
    for each grp in groups
        if grp.OptanonGroupId = data.OptanonGroupId and data.Type <> "privacy"
            if m.groupdetails.doesExist(grp.OptanonGroupId)
                grp.status = m.groupdetails[grp.OptanonGroupId]
            end if
            grp.FirstParent = data.Parent
            grp.groupRecId = "buttonsListGrp"
            grp.isConsentToggle = true
            consentData.push(grp)
        end if
    end for
    return consentData
end function

function getListOfPartners(data)
    partnerData = data.groupData
    partnerData.GroupName = m.preferenceData.PCIABVendorsText
    partnerData.Parent = "vendorsGrpList"
    partnerData.type = "iab"
    partnerData.OptanonGroupId = "list_of_partners"
    partnerData.groupRecId = "buttonsListIABGrp"
    return partnerData
end function

function getListOfIABButton(data)
    partnerData = data.groupData
    partnerData.GroupName = m.preferenceData.VendorListText
    partnerData.Parent = "vendorListButton"
    partnerData.type = "iab"
    partnerData.groupType = data.groupData.type
    partnerData.groupRecId = "IABVendorButton"
    return partnerData
end function

function getsdkButton(data)
    partnerData = data.groupData
    partnerData.GroupName = m.preferenceData.sdkListText
    partnerData.Parent = "sdkListButton"
    partnerData.type = "sdk"
    partnerData.groupType = data.groupData.type
    partnerData.groupRecId = "sdkListButton"
    return partnerData
end function


function getViewIllustrationBtn(data, viewType)
    partnerData = data.groupData
    partnerData.GroupSubHeading = partnerData.GroupName
    partnerData.GroupName = m.preferenceData.fullLegalText
    partnerData.GroupHeading = m.preferenceData.PCIllusText
    partnerData.Parent = "viewIllustrationBtn"
    partnerData.type = viewType
    partnerData.groupType = data.groupData.type
    partnerData.groupRecId = "viewIllustrationBtn"
    return partnerData
end function

function getListOfGooglePartners(data)
    partnerData = data.groupData
    partnerData.GroupName = m.preferenceData.PCGoogleVendorsText
    partnerData.Parent = "vendorsGrpList"
    partnerData.type = "google"
    partnerData.OptanonGroupId = "list_of_partners"
    partnerData.groupRecId = "buttonsListIABGrp"
    return partnerData
end function

function getLIdata(data)
    groups = ParseJson(FormatJson(m.preferenceData.Groups))
    liData = {}
    for each grp in groups
        if grp.OptanonGroupId = data.OptanonGroupId and data.Type <> "privacy"
            OptanonGroupId = "Li_" + grp.OptanonGroupId
            if m.groupdetails.doesExist(OptanonGroupId)
                grp.status = m.groupdetails[OptanonGroupId]
                grp.li_status = m.groupdetails[OptanonGroupId]
            else
                grp.status = "active"
                grp.li_status = "active"
            end if
            grp.groupRecId = "buttonsListLIGrp"
            grp.isConsentToggle = true
            grp.isLIToggle = true
            liData = grp
        end if
    end for
    return liData
end function

function setViewFocus(message as object)
    m.groupdetails = message.saveGroupqueue
    onItemFocused(m.itemFocusedView)
    m.groupRect.getChild(0).isVendorFocus = message.vendorType
end function

function onDisplayLogo()
    if(m.logo.loadStatus = "ready")
        m.logo.loadWidth = (m.logo.bitmapWidth / m.logo.bitmapHeight) * m.logo.height
        m.logo.width = m.logo.loadWidth
    end if
end function