sub init()
    m.logo = m.top.findNode("logo")
    m.logo.observeField("loadStatus", "onDisplayLogo")
    m.divider = m.top.findNode("divider")
    m.groupRect = m.top.findNode("groupRect")
    m.groupHeadRect = m.top.findNode("groupHeadRect")
    m.overlayXRect = m.top.findNode("overlayXRect")
    m.overlayYRect = m.top.findNode("overlayYRect")
    m.menuListView = m.top.findNode("menuListView")
    m.menuListView.observeField("itemSelected", "onMenuItemSelection")
    m.filterListView = m.top.findNode("filterListView")
    m.filterListView.observeField("itemSelected", "onFilterItemSelection")
    m.buttonContent = []
    m.groupdetails = {}
    m.supFilterdetails = {}
    m.tempSupFilterdetails = {}
    m.screenSize = m.global.screenSize
    m.overlayYRect.translation = [0, m.screenSize.h]
    m.overlayxRect.translation = [m.screenSize.w, 0]
    m.vendorHeader = m.top.findNode("vendorHeader")
    m.btnSizetext = m.top.findNode("btnSizetext")
    m.poweredLogo = m.top.findNode("poweredLogo")
    m.poweredLogo.translation = [m.screenSize.w - m.poweredLogo.width - 50, m.screenSize.h - m.poweredLogo.height - 7]
    m.menuSection = m.top.findNode("menuSection")
    m.menuInnerSection = m.top.findNode("menuInnerSection")
    m.LifeSpanDuration = {
        minDays: 1
        maxSecToDays: 86400
    }
    m.filterKeys = initializeFilterKeys()
    m.charsize = 60
    if m.screenSize.h = 1080 then m.charsize = 75
    m.padding = 50
    m.innerPadding = 15
    m.actionButtonContentH = 0
    m.gridColumn = [0.4, 0.6]
    m.titleLayoutPadding = 30
end sub

function onPreferenceData(buttonType)
    m.preferenceData = m.top.pcData
    m.vendorType = m.top.filterType.vendorType
    m.menuListView.scale = [0, 0]
    if m.top.filterType.supFilterdetails <> invalid then m.supFilterdetails = m.top.filterType.supFilterdetails
    if buttonType <> invalid and type(buttonType) <> "roSGNodeEvent" and buttonType.vendorType <> invalid then m.vendorType = buttonType.vendorType
    if buttonType <> invalid and type(buttonType) <> "roSGNodeEvent" and buttonType.supFilterdetails <> invalid then m.supFilterdetails = buttonType.supFilterdetails
    if m.preferenceData.keys().count() > 0
        if m.vendorType = "sdk" and m.preferenceData.sdkLevelOptOutShow
            m.global.OTsdk.callFunc("updateSdkListConsentData", m.preferenceData.vendorData[m.vendorType].sortedVendorRecords)
        end if
        if m.groupdetails[m.vendorType] = invalid
            m.groupdetails[m.vendorType] = {}
        end if
        if (m.vendorType = "google" or not m.preferenceData.showFilterIcon) and m.filterKeys[5] <> invalid then m.filterKeys.pop()
        supFilterdetails = []
        for each fitem in m.supFilterdetails
            if m.supFilterdetails[fitem] = "active" then supFilterdetails.push(fitem)
        end for
        if m.filterKeys[5] <> invalid then m.filterKeys[5].active = supFilterdetails.count() > 0
        m.menuSection.translation = [0, m.groupHeadRect.boundingRect().height]
        m.menuSection.width = m.screenSize.w * m.gridColumn[0]
        m.menuInnerSection.translation = [m.padding, 0]
        m.menuInnerSection.width = m.menuSection.width - m.menuInnerSection.translation[0] - m.titleLayoutPadding - m.padding
        ' m.menuListView.translation = [0, 0]
        ' m.filterListView.translation = [0, 0]
        if m.vendorType <> "sdk"
            m.menuListView.visible = true
            m.menuListView.scale = [1, 1]
            m.menuListView.content = getVendorMenuList()
            mCount = m.menuListView.content.getChildCount()
            m.menuListView.itemSize = [((m.menuInnerSection.width) - ((mCount - 1) * m.menuListView.itemSpacing[0])) / mCount, m.charsize]
            m.filterListView.translation = [0, m.menuListView.translation[1] + m.charsize]
        end if
        m.filterListView.content = getVendorFilterList()
        backButtonW = 40
        m.filterListView.itemSpacing = [7.5, 0]
        if m.screenSize.h = 1080 
            backButtonW = 60
            m.filterListView.itemSpacing = [15, 0]
        end if
        filterButtonW = 30
        fcount = 6
        fWidth = ((m.menuInnerSection.width) - ((fcount - 1) * m.filterListView.itemSpacing[0]) - backButtonW - filterButtonW) / (fcount - 2)
        m.filterListView.itemSize = [fWidth, m.charsize]
        m.filterListView.columnWidths = [backButtonW, fWidth, fWidth, fWidth, fWidth, filterButtonW]
        styleData = m.preferenceData.styleData
        m.groupRect.color = styleData.backgroundColor
        m.groupHeadRect.color = styleData.backgroundColor
        m.groupRect.width = m.screenSize.w
        m.groupRect.height = m.screenSize.h
        m.groupHeadRect.width = m.screenSize.w
        m.focusedIndex = 0
        if m.preferenceData.PCenterVendorsListText <> invalid
            m.vendorHeader.visible = true
            m.vendorHeader.text = m.preferenceData.PCenterVendorsListText
            if m.vendorType = "sdk" then m.vendorHeader.text = m.preferenceData.sdkListText
            m.vendorHeader.color = styleData.textColor
        end if
        if m.preferenceData.doesExist("logoSize")
            if m.preferenceData.logoSize.doesExist("width")
                m.logo.loadWidth = m.preferenceData.logoSize.width
                m.logo.width = m.preferenceData.logoSize.width
            end if
            if m.preferenceData.logoSize.doesExist("height")
                height = m.preferenceData.logoSize.height
                m.logo.loadHeight = height
                m.logo.height = height
                bgRectHeight = height - 30
                if bgRectHeight >= 0
                    m.groupRect.translation = [0, bgRectHeight]
                end if
            end if
        end if
        if m.preferenceData.logo <> invalid and m.preferenceData.logo.show
            m.logo.visible = true
            m.divider.visible = true
            m.divider.scale = [1, 1]
            m.divider.color = styleData.textColor
            m.divider.font.size = m.divider.height
            m.logo.uri = getLogo(m.preferenceData.logo)
        end if
        m.buttonContent = []

        preference = isPreference(m.preferenceData)
        if preference <> ""
            preferenceStyle = {}
            preferenceStyle.buttonColor = styleData.pcbuttonColor
            preferenceStyle.textColor = styleData.pcbuttonTextColor
            preferenceStyle.focusButtonColor = styleData.pcbuttonFocusColor
            preferenceStyle.focusTextColor = styleData.pcbuttonTextFocusColor
            preferenceStyle.textData = preference
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
            m.buttonContent.push(refuseStyle)
        end if
        m.viewDataParams = {}
        buttonContent = getButtonList(m.buttonContent)
        m.viewDataParams.AddReplace("actionButtonContent", buttonContent)
        m.viewDataParams.AddReplace("actionButtonContentH", m.actionButtonContentH)
        setgroupListFeilds(supFilterdetails)
        m.top.onShowVendorList = true
    end if
end function

function setgroupListFeilds(supFilterdetails)
    sortedRecords = []
    sortedRecords = m.preferenceData.vendorData[m.vendorType].sortedVendorRecords
    sortedNodeVendorRecords = m.preferenceData.vendorData[m.vendorType].sortedNodeVendorRecords
    response = filterByAlphaRange(sortedRecords, sortedNodeVendorRecords, m.filterKeys, supFilterdetails, m.vendorType)
    m.groupNode = response.data
    m.buttonListWidth = response.buttonListWidth
    m.vendorList = response.vendorList
    view = m.top.view
    viewChildCount = m.groupRect.getChildCount()
    bannerChild = m.groupRect.getChild(viewChildCount - 1)
    m.groupRect.removeChild(bannerChild)
    view.appendChild(m.top)
    m.viewDataParams.AddReplace("buttonListWidth", m.buttonListWidth)
    m.viewDataParams.AddReplace("actionList", true)
    setGroupsList(m.groupNode, m.viewDataParams)
    m.groupRect.getChild(m.focusedIndex).isFocus = true
end function

function filterByAlphaRange(array, nodes, filterKeys, supFilterdetails, vendorType)
    dataNode = CreateObject("roSGNode", "ContentNode")
    buttonListWidth = []
    filtered = []
    filterRange = ""
    label = getNode().label()
    label.width = (m.screenSize.w * m.gridColumn[0]) - 24 - m.titleLayoutPadding - m.padding - 14
    iabTypeversion = getIabTypeVersion()
    for each key in filterKeys
        if key.active and key["key"] <> "filterIcon" and key.active and key["key"] <> "backIcon"
            filterRange = filterRange + LCase(key["key"])
        end if
    end for

    if filterRange <> "" then regEx = createObject("roRegEx", "[" + filterRange + "]", "")

    for each item in array
        if filterRange = ""
            result = true
        else if regEx <> invalid
            firstChar = Left(LCase(item["name"]), 1)
            result = regEx.isMatch(firstChar)
        end if
        if result
            supResult = true
            if supFilterdetails.count() > 0
                supResult = false
                for each fItem in supFilterdetails
                    if havingVendorPurpose(item, fItem, vendorType, iabTypeversion)
                        supResult = true
                        exit for
                    end if
                end for
            end if
            if supResult
                item.groupRecId = "vendorButtonList"
                label.text = item.name
                buttonListWidth.push(label.boundingRect().height + 30)
                filtered.push(item)
                dataItem = createButtonChild(item, nodes[item.id.toStr()])
                dataNode.appendChild(dataItem)
            end if
        end if
    end for

    response = {
        "data": dataNode,
        "vendorList": filtered
        "buttonListWidth": buttonListWidth
    }
    return response
end function

function createButtonChild(b, dataItem) as object
    description = ""
    if b.description <> invalid then description = b.description
    dataItem.name = b.name
    dataItem.description = description
    dataItem.status = b.status
    dataItem.CustomGroupId = b.id
    dataItem.purposeId = b.id
    dataItem.OptanonGroupId = b.id
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
    'dataItem.groupRecId = b.groupRecId
    dataItem.isunFocused = false
    'dataItem.isBorder = false
    return dataItem
end function

function havingVendorPurpose(item, id, vendorType, iabTypeversion)
    supResult = false
    if id.Instr("ISP" + iabTypeversion +"_") <> -1 'Special purpose
        id = id.replace("ISP" + iabTypeversion +"_", "")
        result = findArrayID(optionalChaining(item, "specialPurposes"), id)
        if result <> invalid
            supResult = true
        end if
    else if id.Instr("IAB" + iabTypeversion +"_") <> -1 ' Purpose
        id = id.replace("IAB" + iabTypeversion +"_", "")
        result = findArrayID(optionalChaining(item, "purposes"), id)
        if result <> invalid
            supResult = true
        else
            result = findArrayID(optionalChaining(item, "legIntPurposes"), id)
            if result <> invalid then supResult = true
        end if
    else if id.Instr("IFE" + iabTypeversion +"_") <> -1 ' Feature
        id = id.replace("IFE" + iabTypeversion +"_", "")
        result = findArrayID(optionalChaining(item, "features"), id)
        if result <> invalid
            supResult = true
        end if
    else if id.Instr("ISF" + iabTypeversion +"_") <> -1 ' Spcieal feature
        id = id.replace("ISF" + iabTypeversion +"_", "")
        result = findArrayID(optionalChaining(item, "specialFeatures"), id)
        if result <> invalid
            supResult = true
        end if
    else if optionalChaining(item, "CustomGroupId") = id and vendorType = "sdk"
        supResult = true
    end if
    return supResult
end function

function findArrayID(array, id)
    result = invalid
    if array <> invalid and array.count() > 0
        for each item in array
            if id.toStr() = item.toStr()
                result = item
                exit for
            end if
        end for
    end if
    return result
end function

function setGroupsList(groupNode as dynamic, params = {} as object) as object
    viewData = {}
    if params.keys().count() > 0
        viewData.append(params)
    end if
    view = CreateObject("roSGNode", "OTVLGroupView")
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
    viewData.vendorType = m.vendorType
    view.viewData = viewData
    view.id = "group" + Str(m.groupRect.getChildCount())
    m.groupRect.appendChild(view)
end function

function isAccept(data as object) as string
    if data.buttons <> invalid and data.buttons.acceptAll <> invalid and data.buttons.acceptAll.show
        return data.buttons.acceptAll.text
    else
        return ""
    end if
end function

function isRefuse(data as object) as string
    if data.buttons <> invalid and data.buttons.rejectAll <> invalid and data.buttons.rejectAll.show
        return data.buttons.rejectAll.text
    else
        return ""
    end if
end function

function isPreference(data as object) as string
    if data.buttons <> invalid and data.buttons.savePreferencesButton <> invalid
        return data.buttons.savePreferencesButton.text
    else
        return ""
    end if
end function

function getLogo(data as object) as string
    logoString = data.url
    if logoString <> "" and Instr(1, logoString, ".svg") = 0
        return data.url
    end if
    return ""
end function

function getButtonList(buttonList as object) as object
    data = CreateObject("roSGNode", "ContentNode")
    m.actionButtonContentH = 0
    acount = buttonList.count()
    paddingBtnButtons = 2 * m.innerPadding
    width = ((m.screenSize.w - (2 * m.padding)) - ((acount - 1) * paddingBtnButtons)) / acount
    m.btnSizetext.width = width
    m.btnSizetext.maxLines = 2
    for each b in buttonList
        dataItem = data.CreateChild("OTGroupListData")
        dataItem.name = b.textData
        dataItem.buttonColor = b.buttonColor
        dataItem.buttonTextColor = b.textColor
        dataItem.focusButtonColor = b.focusButtonColor
        dataItem.focusButtonTextColor = b.focusTextColor
        'dataItem.isBorder = false
        m.btnSizetext.text = dataItem.name
        height = m.btnSizetext.boundingRect().height + 30
        if m.actionButtonContentH < height then
            m.actionButtonContentH = height
        end if
    end for
    return data
end function

function getGroupListData(groups as object) as object
    data = CreateObject("roSGNode", "ContentNode")
    m.buttonListWidth = []
    for each b in groups
        if b.type <> "qrCode" and isSubGroup(b) and m.vendorType <> "sdk"
            parentGroup = getParent(b.Parent)
            if parentGroup.ShowSubgroup
                dataItem = createChild(b)
                dataItem.isToggleOption = parentGroup.ShowSubgroupToggle
                dataItem.showDescription = parentGroup.ShowSubGroupDescription
                data.appendChild(dataItem)
            end if
        else
            dataItem = createChild(b)
            data.appendChild(dataItem)
        end if
    end for
    return data
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
    dataItem = {}
    dataItem.GroupName = m.preferenceData.MainText
    dataItem.GroupDescription = m.preferenceData.MainInfoText
    dataItem.Type = "privacy"
    dataItem.Parent = ""
    return dataItem
end function

function getVendorList()
    vendorData = {}
    vendorData.GroupName = m.preferenceData.MenuVendorListText
    vendorData.GroupDescription = ""
    vendorData.Type = "vendor"
    vendorData.Parent = ""
    vendorData.HasListofpartners = true
    vendorData.OptanonGroupId = "vendorsGrpList"
    return vendorData
end function

function createChild(b as object) as object
    dataItem = CreateObject("roSGNode", "OTGroupListData")
    if m.top.id = "OTVendorList"
        dataItem.name = b.name
        dataItem.description = ""
        if b.type = "qrCode" then dataItem.description = b.description
        dataItem.status = b.status
        dataItem.CustomGroupId = b.id
        dataItem.purposeId = b.id
        dataItem.OptanonGroupId = b.id
    else
        dataItem.name = b.GroupName
        dataItem.description = getGroupDescription(b)
        dataItem.status = b.status
        if b.CustomGroupId <> invalid and b.status <> invalid
            if b.grouprecid <> "buttonsListLIGrp" then m.groupdetails[m.vendorType].AddReplace(b.CustomGroupId, b.status)
            if b.li_status = invalid
                m.groupdetails[m.vendorType].AddReplace("Li_" + b.CustomGroupId, "active")
            else
                m.groupdetails[m.vendorType].AddReplace("Li_" + b.CustomGroupId, b.li_status)
            end if
        end if
        dataItem.CustomGroupId = b.CustomGroupId
        dataItem.purposeId = b.PurposeId
        dataItem.OptanonGroupId = b.OptanonGroupId
    end if
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
    'dataItem.isBorder = false
    return dataItem
end function

function isSubGroup(groupData as object) as boolean
    return groupData.Parent <> invalid and groupData.Parent <> ""
end function


function getSubGroups(groupId as string) as object
    groups = getItems()
    subGroups = []
    for each grp in groups
        if grp.Parent <> invalid and grp.Parent = groupId and grp.Parent <> ""
            if m.groupdetails[m.vendorType].doesExist(grp.OptanonGroupId)
                grp.status = m.groupdetails[m.vendorType][grp.OptanonGroupId]
            end if
            if m.groupdetails[m.vendorType].doesExist("Li_" + grp.OptanonGroupId)
                grp.li_status = m.groupdetails[m.vendorType]["Li_" + grp.OptanonGroupId]
            end if
            grp.groupRecId = "subGrpListGrp"
            subGroups.push(grp)
        end if
    end for
    return subGroups
end function

function getParent(parentId as string) as object
    groups = getItems()
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
            m.top.filterType = { vendorType: m.vendorType }
            m.top.onHidePreferenceCenter = true
            handled = true
        else if key = "right"
            if m.filterListView.hasFocus() or m.menuListView.hasFocus()
                nextView = m.groupRect.getChild(m.focusedIndex)
                nextView.callFunc("onKeyDownClose", key)
            end if
            handled = true
        else if key = "left"
            handled = true
        else if key = "up"
            if not m.filterListView.hasFocus() and m.filterListView.visible and not m.menuListView.hasFocus()
                m.filterListView.setFocus(true)
            else if m.filterListView.hasFocus() and m.menuListView.visible
                m.menuListView.setFocus(true)
            end if
            handled = true
        else if key = "down"
            handled = true
            if m.menuListView.hasFocus()
                m.filterListView.setFocus(true)
            else if m.filterListView.hasFocus()
                nextView = m.groupRect.getChild(m.focusedIndex)
                nextView.callFunc("onKeyDownClose", key)
            end if
        else if key = "OK"
            handled = true
        end if
    end if
    return handled
end function

function onItemSelection(message as object)
    view = message.getRoSGNode()
    item = view.itemSelected
    pcData = m.top.pcData
    if item <> invalid
        if item.groupRecId = "supportFilterList"
            updatedStatus = getUpdatedStatus(item.status)
            m.tempSupFilterdetails.AddReplace(item.CustomGroupId, updatedStatus)
            groupItem = m.groupRect.getChild(m.focusedIndex)
            groupItem.updateGroups = m.tempSupFilterdetails
        else if item.groupRecId = "supportFilterButton"
            m.supFilterdetails = {}
            if item.name = m.preferenceData.PCenterApplyFiltersText then m.supFilterdetails = ParseJson(FormatJson(m.tempSupFilterdetails))
            onPreferenceData({ "vendorType": m.vendorType, "supFilterdetails": m.supFilterdetails })
        else if item.groupData = invalid
            if item.name = isAccept(pcData)
                m.top.onPreferenceCenterAcceptAll = true
            else if item.name = isRefuse(pcData)
                m.top.onPreferenceCenterRejectAll = true
            else if item.name = isPreference(pcData)
                m.top.onPreferenceCenterConfirmChoices = true
            end if
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
                g.AddReplace("id", getid(item.groupData))
                g.AddReplace("status", Bstatus)
                if item.groupRecId <> "subGrpListGrp" and item.groupRecId <> "IABVendorButton"
                    if m.vendorType = "sdk" then g.AddReplace("groupId", item.groupData.OptanonGroupId)
                    m.global.OTsdk.callFunc("updateVendorPurposeConsent", g, item.groupRecId, m.vendorType)
                    if not isSubGroup(item.groupData)
                        if item.groupRecId = "buttonsListGrp"
                            subGroups = getSubGroups(getid(item.groupData))
                            for each sg in subGroups
                                m.groupdetails[m.vendorType].AddReplace(getGroupId(item, sg.CustomGroupId), updatedStatus)
                            end for
                        end if
                        m.groupdetails[m.vendorType].AddReplace(getGroupId(item, item.CustomGroupId), updatedStatus)
                    else
                        if item.groupRecId = "buttonsListGrp" or item.groupRecId = "buttonsListLIGrp"
                            m.groupdetails[m.vendorType].AddReplace(getGroupId(item, item.CustomGroupId), updatedStatus)
                            if item.groupRecId = "buttonsListGrp" and m.vendorType <> "sdk"
                                parentData = getParent(item.groupData["Parent"])
                                subGroups = getSubGroups(parentData["OptanonGroupId"])
                                parentStatus = "active"
                                for each sGroups in subGroups
                                    substatus = sGroups.status
                                    if m.groupdetails[m.vendorType].doesExist(getGroupId(item, sGroups.CustomGroupId))
                                        substatus = m.groupdetails[m.vendorType][getGroupId(item, sGroups.CustomGroupId)]
                                    end if
                                    if substatus <> "always active" and substatus <> "active"
                                        parentStatus = "inactive"
                                        exit for
                                    end if
                                end for
                                m.groupdetails[m.vendorType].AddReplace(getGroupId(item, parentData.CustomGroupId), parentStatus)
                            end if
                        end if
                    end if
                end if
                for fChild = 0 to m.groupRect.getChildCount() - 1
                    groupItem = m.groupRect.getChild(fChild)
                    groupItem.updateGroups = m.groupdetails[m.vendorType]
                end for
            end if
            if item.groupRecId = "subGrpListGrp" then updateGroupItem(item)
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

function onItemFocused(message as object) as void
    view = message.getRoSGNode()
    if m.item = invalid or optionalChaining(view, "itemFocused.OptanonGroupId") <> m.item.OptanonGroupId
        m.item = view.itemFocused
        updateGroupItem(m.item)
    end if
end function

function updateGroupItem(item)
    child = m.groupRect.getChild(m.focusedIndex)
    params = {}
    isvendorList = false
    params.heading = ""
    params.description = ""
    params.deviceStorageDisclosureUrl = ""
    if item <> invalid
        params.heading = item.name
        params.description = item.description
        params.groupData = item.groupData
    end if
    if optionalChaining(item, "groupData.deviceStorageDisclosureUrl") <> invalid and item.groupData.deviceStorageDisclosureUrl <> "" then params.deviceStorageDisclosureUrl = item.groupData.deviceStorageDisclosureUrl
    if item <> invalid and item.groupData.type <> "privacy"
        buttonData = []
        if item.groupData.type <> "vendor"
            parentData = invalid
            if item.groupRecId = "subGrpListGrp" then parentData = getParent(item.groupData["Parent"])
            if parentData <> invalid and not parentData.ShowSubGroupDescription and item.groupRecId = "subGrpListGrp" then params.description = ""
            if item.groupRecId <> "subGrpListGrp" and m.top.id <> "OTVendorList"
                groupData = getSubGroups(item.OptanonGroupId)
                if groupData.count() > 0
                    groupNode = getGroupListData(groupData)
                    params.subGrpButtonContent = groupNode
                    params.sunGrpHeading = m.preferenceData.subCategoryHeaderText
                end if
            end if
            if m.vendorType <> "sdk"
                policyURLBtn = getPolicyURLBtn(item)
                if policyURLBtn.name <> invalid and policyURLBtn.description <> invalid and policyURLBtn.name <> "" and policyURLBtn.description <> "" then buttonData.push(policyURLBtn)
                legIntClaimBtn = getlegIntClaimBtn(item)
                if m.vendorType = "iab" and legIntClaimBtn.name <> invalid and legIntClaimBtn.description <> invalid and legIntClaimBtn.name <> "" and legIntClaimBtn.description <> "" then buttonData.push(legIntClaimBtn)
            end if
            if (m.top.id = "OTVendorList" and ((m.vendorType <> "sdk" and item.groupData.shouldShowConsentToggleForVendor) or (m.vendorType = "sdk" and m.preferenceData.sdkLevelOptOutShow))) or (m.top.id <> "OTVendorList" and ((item.groupData.HasConsentOptOut = true or item.groupData.status = "always active") and item.groupRecId = "") or (item.groupData.HasConsentOptOut = true and parentData <> invalid and parentData.ShowSubgroupToggle and item.groupRecId = "subGrpListGrp"))
                buttonData.Push(getConsentData(item))
            end if
            if isVendorLegitimateInterest(item.groupData, m.preferenceData.LegIntSettings) and m.vendorType <> "sdk"
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
        if item.groupData.HasListofpartners <> invalid and item.groupRecId = ""
            partners = getListOfPartners(item)
            buttonData.Push(partners)
            if m.preferenceData.UseGoogleVendors
                googlePartners = getListOfGooglePartners(item)
                buttonData.Push(googlePartners)
            end if
            isvendorList = true
        end if
        if item.groupData.IsIabPurpose <> invalid and item.groupData.IsIabPurpose
            partners = getListOfIABButton(item)
            params.IABVendorButton = getvendorListData([partners])
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
    if groupDetail.Type.Instr("IAB") > -1
        return groupDetail.DescriptionLegal
    else if groupDetail.doesExist("GroupDescriptionOTT") and groupDetail.GroupDescriptionOTT <> invalid and groupDetail.GroupDescriptionOTT <> ""
        return groupDetail.GroupDescriptionOTT
    else
        return groupDetail.GroupDescription
    end if
end function

function getConsentData(data)
    groups = ParseJson(FormatJson(m.preferenceData.vendorData[m.vendorType].filteredVendorRecords))
   ' consentData = []
    consentItem = groups[data.OptanonGroupId]
    if consentItem <> invalid
        consentItem.status = m.global.OTsdk.callFunc("getVendorStatus", consentItem.id.toStr(), m.vendorType, true, invalid)
        if m.groupdetails[m.vendorType].doesExist(consentItem.id.toStr())
            consentItem.status = m.groupdetails[m.vendorType][consentItem.id.toStr()]
        end if
        consentItem.FirstParent = data.Parent
        consentItem.groupRecId = "buttonsListGrp"
        consentItem.isConsentToggle = true
        'consentData.push(consentItem)
    end if
    return consentItem'consentData
end function

function getListOfPartners(data)
    partnerData = data.groupData
    partnerData.GroupName = m.preferenceData.PCIABVendorsText
    partnerData.Parent = "vendorsGrpList"
    partnerData.type = "iabvendor"
    partnerData.OptanonGroupId = "list_of_partners"
    partnerData.groupRecId = "buttonsListIABGrp"
    return partnerData
end function

function getListOfIABButton(data)
    partnerData = data.groupData
    partnerData.GroupName = "List of IAB Vendors"'m.preferenceData.PCIABVendorsText
    partnerData.Parent = "vendorListButton"
    partnerData.type = "iabVendorButton"
    partnerData.OptanonGroupId = "IAB_Vendor_Button"
    partnerData.groupRecId = "IABVendorButton"
    return partnerData
end function

function getListOfGooglePartners(data)
    partnerData = data.groupData
    partnerData.GroupName = m.preferenceData.PCGoogleVendorsText
    partnerData.Parent = "vendorsGrpList"
    partnerData.type = "googlevendor"
    partnerData.OptanonGroupId = "list_of_partners"
    partnerData.groupRecId = "buttonsListIABGrp"
    return partnerData
end function

function getLIdata(data)
    groups = ParseJson(FormatJson(m.preferenceData.vendorData[m.vendorType].filteredVendorRecords))
    liData = {}
    liItem = groups[data.OptanonGroupId]
    if liItem <> invalid
        liItem.status = m.global.OTsdk.callFunc("getVendorStatus", "Li_" + liItem.id.toStr(), m.vendorType, false, invalid)
        liItem.li_status = liItem.status
        if m.groupdetails[m.vendorType].doesExist("Li_" + liItem.id.toStr())
            liItem.status = m.groupdetails[m.vendorType]["Li_" + liItem.id.toStr()]
            liItem.li_status = m.groupdetails[m.vendorType]["Li_" + liItem.id.toStr()]
        end if
        liItem.FirstParent = data.Parent
        liItem.groupRecId = "buttonsListLIGrp"
        liItem.isConsentToggle = true
        liItem.isLIToggle = true
        liData = liItem
    end if
    return liData
end function

function getid(item)
    if m.top.id = "OTVendorList"
        return item.id.toStr()
    else
        return item.OptanonGroupId
    end if
end function

function getItems()
    if m.top.id = "OTVendorList"
        return ParseJson(FormatJson(m.vendorList))
    else
        return ParseJson(FormatJson(m.preferenceData.Groups))
    end if
end function

function getVendorMenuList()
    buttonContent = []
    styleData = m.preferenceData.styleData
    PCIABVendorsText = m.preferenceData.PCIABVendorsText
    PCGoogleVendorsText = m.preferenceData.PCGoogleVendorsText
    style = {}
    style.buttonColor = styleData.pcbuttonColor
    style.textColor = styleData.pcbuttonTextColor
    style.focusButtonColor = styleData.pcbuttonFocusColor
    style.focusButtonTextColor = styleData.pcbuttonTextFocusColor
    style.activeTextColor = styleData.activeTextColor
    style.activeColor = styleData.activeColor
    if m.global._OT_IABVendor_data["iab"] <> invalid
        style.textData = PCIABVendorsText
        style.isunFocused = m.vendorType = "iab"
        buttonContent.push(ParseJson(FormatJson(style)))
    end if

    if m.global._OT_IABVendor_data["google"] <> invalid
        style.textData = PCGoogleVendorsText
        style.isunFocused = m.vendorType = "google"
        buttonContent.push(ParseJson(FormatJson(style)))
    end if

    data = CreateObject("roSGNode", "ContentNode")
    for each b in buttonContent
        dataItem = data.CreateChild("OTGroupListData")
        dataItem.name = b.textData
        dataItem.buttonColor = b.buttonColor
        dataItem.buttonTextColor = b.textColor
        dataItem.focusButtonColor = b.focusButtonColor
        dataItem.focusButtonTextColor = b.focusButtonTextColor
        dataItem.activeTextColor = b.activeTextColor
        dataItem.activeColor = b.activeColor
        dataItem.isunFocused = b.isunFocused
        'dataItem.isBorder = false
        dataItem.groupRecId = "vendorMenuList"
    end for
    return data
end function

function getVendorFilterList()
    styleData = m.preferenceData.styleData
    data = CreateObject("roSGNode", "ContentNode")
    for each key in m.filterKeys
        dataItem = data.CreateChild("OTGroupListData")
        dataItem.name = key.key
        if key.key = "filterIcon"
            dataItem.buttonColor = styleData.textColor
            dataItem.buttonTextColor = styleData.pcbuttonColor
            dataItem.focusButtonColor = styleData.textColor
            dataItem.focusButtonTextColor = styleData.pcbuttonColor
            dataItem.activeTextColor = styleData.pcbuttonColor
            dataItem.activeColor = styleData.textColor
            if key.active
                dataItem.buttonColor = styleData.pcbuttonColor
                dataItem.focusButtonColor = styleData.pcbuttonColor
                dataItem.activeColor = styleData.pcbuttonColor
            end if
        else
            dataItem.buttonColor = styleData.pcbuttonColor
            dataItem.buttonTextColor = styleData.pcbuttonTextColor
            dataItem.focusButtonColor = styleData.pcbuttonFocusColor
            dataItem.focusButtonTextColor = styleData.pcbuttonTextFocusColor
            dataItem.activeTextColor = styleData.activeTextColor
            dataItem.activeColor = styleData.activeColor
        end if
        dataItem.isunFocused = key.active
        dataItem.groupRecId = "vendorFilterList"
    end for
    return data
end function

function onMenuItemSelection(message as object)
    view = message.getRoSGNode()
    item = view.itemSelected
    vendorType = "iab"
    if item = 1 then vendorType = "google"
    if m.vendorType <> vendorType
        m.filterKeys = initializeFilterKeys()
        m.supFilterdetails = {}
        onPreferenceData({ "vendorType": vendorType, "supFilterdetails": m.supFilterdetails })
    end if
end function

function onFilterItemSelection(message as object)
    view = message.getRoSGNode()
    item = view.itemSelected
    if m.filterKeys[item].key = "filterIcon"
        setSupportFilter()
    else if m.filterKeys[item].key = "backIcon"
        m.top.filterType = { vendorType: m.vendorType }
        m.top.onHidePreferenceCenter = true
    else
        m.filterKeys[item].active = not m.filterKeys[item].active
        onPreferenceData({ "vendorType": m.vendorType, "supFilterdetails": m.supFilterdetails })
    end if
end function

function setSupportFilter()
    groups = m.preferenceData.Groups
    initGroups = m.preferenceData.initGroups
    styleData = m.preferenceData.styleData
    m.tempSupFilterdetails = ParseJson(FormatJson(m.supFilterdetails))
    m.item = invalid
    rowHeights = []
    label = getNode().label()
    label.width = (m.screenSize.w * m.gridColumn[1]) - 128 - 50 - 30 - 30
    supportdata = CreateObject("roSGNode", "ContentNode")
    for each item in groups
        if (item.IsIabPurpose <> invalid and item.IsIabPurpose and not isIab_STACK(item.Type) and m.vendorType <> "sdk") or (m.preferenceData.ShowCookieList <> invalid and m.preferenceData.ShowCookieList and item.ShowSDKListLink <> invalid and item.ShowSDKListLink and item.FirstPartyCookies <> invalid and item.FirstPartyCookies.count() > 0 and m.vendorType = "sdk" and ((item.Parent <> "" and initGroups[item.Parent] <> invalid and initGroups[item.Parent].ShowSubgroup) or item.Parent = ""))
            dataItem = supportdata.CreateChild("OTGroupListData")
            dataItem.name = item.GroupName
            label.text = item.GroupName
            rowHeights.push(label.boundingRect().height + 30)
            dataItem.buttonColor = styleData.buttonColor
            dataItem.buttonTextColor = styleData.buttonTextColor
            dataItem.focusButtonColor = styleData.buttonFocusColor
            dataItem.focusButtonTextColor = styleData.buttonTextFocusColor
            dataItem.status = "inactive"
            if m.supFilterdetails.doesExist(item.CustomGroupId) then dataItem.status = m.supFilterdetails[item.CustomGroupId]
            dataItem.CustomGroupId = item.CustomGroupId
            'dataItem.activeTextColor = styleData.activeTextColor
            'dataItem.activeColor = styleData.activeColor
            'dataItem.isBorder = false
            dataItem.groupRecId = "supportFilterList"
        end if
    end for
    buttondata = CreateObject("roSGNode", "ContentNode")
    buttonContent = [m.preferenceData.PCenterApplyFiltersText, m.preferenceData.PCenterClearFiltersText]
    for each button in buttonContent
        dataItem = buttondata.CreateChild("OTGroupListData")
        dataItem.name = button
        dataItem.buttonColor = styleData.pcbuttonColor
        dataItem.buttonTextColor = styleData.pcbuttonTextColor
        dataItem.focusButtonColor = styleData.pcbuttonFocusColor
        dataItem.focusButtonTextColor = styleData.pcbuttonTextFocusColor
        dataItem.groupRecId = "supportFilterButton"
    end for
    params = {}
    heading = "Filter Vendor List"
    if m.vendorType = "sdk" then heading = "Filter SDK List"
    params.heading = heading
    params.buttonsListSupFilter = buttondata
    params.subGrpButtonContent = supportdata
    params.subgroubHeights = rowHeights
    child = m.groupRect.getChild(m.focusedIndex)
    if child <> invalid
        child.viewData = params
    end if
end function

function initializeFilterKeys()
    return [
        { "key": "backIcon", "active": false }
        { "key": "A-F", "active": false },
        { "key": "G-L", "active": false },
        { "key": "M-R", "active": false },
        { "key": "S-Z", "active": false },
        { "key": "filterIcon", "active": false }
    ]
end function

function onDisplayLogo()
    if(m.logo.loadStatus = "ready")
        m.logo.loadWidth = (m.logo.bitmapWidth / m.logo.bitmapHeight) * m.logo.height
        m.logo.width = m.logo.loadWidth
    end if
end function

function getPolicyURLBtn(data)
    partnerData = data.groupData
    partnerData.name = m.preferenceData.PCenterViewPrivacyPolicyText
    partnerData.description = getPolicyURL(optionalChaining(data, "groupData"), true)
    partnerData.Parent = "policyURLBtn"
    partnerData.type = "qrCode"
    partnerData.OptanonGroupId = "policyURLBtn"
    partnerData.groupRecId = "policyURLBtn"
    return partnerData
end function

function getlegIntClaimBtn(data)
    partnerData = data.groupData
    partnerData.name = m.preferenceData.PCIABVendorLegIntClaimText
    partnerData.description = getPolicyURL(optionalChaining(data, "groupData"), false)
    partnerData.Parent = "legIntClaimBtn"
    partnerData.type = "qrCode"
    partnerData.OptanonGroupId = "legIntClaimBtn"
    partnerData.groupRecId = "legIntClaimBtn"
    return partnerData
end function

function getPolicyURL(vendor, isPolicyUrl)
    policyUrl = ""
    language = m.preferenceData.language
    if isIAB2V2() and optionalChaining(vendor, "urls") <> invalid and vendor.urls.count() > 0
        for each url in vendor.urls
            if optionalChaining(url, "langId") <> invalid and url.langId = language
                if optionalChaining(url, "privacy") <> invalid and isPolicyUrl then policyUrl = url.privacy
                if optionalChaining(url, "legIntClaim") <> invalid and not isPolicyUrl then policyUrl = url.legIntClaim
                exit for
            end if
        end for
    else if optionalChaining(vendor, "policyUrl") <> invalid and isPolicyUrl
      policyUrl = vendor.policyUrl
    end if
    return policyUrl
end function