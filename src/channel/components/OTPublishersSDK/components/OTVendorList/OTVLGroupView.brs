function init()
    screenSize = m.global.screenSize
    m.halfWidth = screenSize.w * 0.5
    m.height = screenSize.h
    m.getNode = getNode()
    m.titleLayout = m.top.findNode("titleLayout")
    m.rightSection = m.top.findNode("rightSection")
    m.innerRightSection = m.top.findNode("innerRightSection")
    m.horzLine = m.top.findNode("horzLine")
    m.leftSection = m.top.findNode("leftSection")
    m.innerLeftSection = m.top.findNode("innerLeftSection")
    m.VertLine = m.top.findNode("VertLine")
    m.heading = m.top.findNode("heading")
    m.description = m.top.findNode("description")
    m.mainRect = m.top.findNode("mainRect")
    m.actionRect = m.top.findNode("actionRect")
    m.mainGroup = m.top.findNode("mainGroup")
    m.buttonList = m.top.findNode("buttonList")
    m.subGrpListGrp = m.top.findNode("subGrpListGrp")
    m.buttonsListGrp = m.top.findNode("buttonsListGrp")
    m.descriptionRec = m.top.findNode("descriptionRec")
    m.scrollThumb = m.top.findNode("scrollThumb")
    m.buttonsListGrp.observeField("itemSelected", "onItemSelection")
    m.subGrpListGrp.observeField("itemSelected", "onItemSelection")
    m.subGrpListGrp.observeField("itemFocused", "onItemsubGrpFocused")
    m.actionButtonList = m.top.findNode("actionButtonList")
    m.actionButtonList.observeField("itemSelected", "onItemSelection")
    m.buttonList.observeField("itemFocused", "onItemFocused")
    m.buttonInternalFocusSwitch = true
    m.buttonListPadding = 30
    m.gridColumn = [0.4, 0.6]
    m.padding = 50
    m.innerPadding = 15
    m.titleLayoutPadding = 30
    m.LifeSpanDuration = {
        SECOND_DIVIDER: 2629746,
        MONTH_DIVIDER: 86400,
    }
    ScrollInitialize(m, m.descriptionRec, m.description)
    m.deviceStorageDisclosureData = {}
    m.dataCategories = invalid
end function

function setViewFocus(message as object)
    view = message.getRoSGNode()
    focus = view.isFocus
    m.buttonList.setFocus(focus)
end function

function onViewData(message as object)
    view = message.getRoSGNode()
    viewData = view.viewData
    styleData = viewData.styleData
    m.parent = m.top.getParent()
    m.charsize = 60
    m.description.visible = false
    m.scrollThumb.visible = false
    if viewData.buttonListWidth <> invalid
        m.buttonListWidth = viewData.buttonListWidth
    end if
    if m.height = 1080 then m.charsize = 75
    if styleData <> invalid
        m.mainRect.color = styleData.backgroundColor
        m.leftSection.color = styleData.backgroundColor
        m.innerLeftSection.color = styleData.backgroundColor
        m.rightSection.color = styleData.backgroundColor
        m.innerRightSection.color = styleData.backgroundColor
        m.heading.color = styleData.textColor
        m.horzLine.color = styleData.textColor
        m.VertLine.color = styleData.textColor
        m.vendorType = viewData.vendorType
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
    m.mainRect.width = (m.halfWidth * 2)
    m.mainRect.height = m.height - 120 - m.actionRect.height
    m.rightSection.translation = [m.halfWidth * 2 * m.gridColumn[0], 0]
    m.rightSection.width = m.halfWidth * 2 * m.gridColumn[1]
    m.rightSection.height = m.mainRect.height
    m.innerRightSection.translation = [m.titleLayoutPadding, 0]
    m.innerRightSection.width = m.rightSection.width - m.innerRightSection.translation[0] - m.padding
    m.leftSection.width = m.halfWidth * 2 * m.gridColumn[0]
    m.leftSection.height = m.mainRect.height
    m.innerLeftSection.translation = [m.padding, 0]
    m.innerLeftSection.width = m.leftSection.width - m.titleLayoutPadding - m.innerLeftSection.translation[0]
    m.innerLeftSection.height = m.leftSection.height
    m.subGrpListGrp.itemSize = [0, 0]
    m.buttonsListGrp.itemSize = [0, 0]
    m.horzLine.scale = [0, 0]
    m.horzLine.visible = false
    m.subGrpListGrp.content = invalid
    m.buttonsListGrp.content = invalid
    m.buttonsListGrp.scale = [0.0, 0.0]
    isIAB = viewData.buttonsListIABGrp <> invalid and viewData.buttonsListIABGrp.getChildCount() > 0
    isSupFilter = viewData.buttonsListSupFilter <> invalid and viewData.buttonsListSupFilter.getChildCount() > 0
    m.titleLayout.itemSpacings = [0]
    if (viewData.buttonsListGrp <> invalid and viewData.buttonsListGrp.getChildCount() > 0) or isIAB or isSupFilter
        m.titleLayout.itemSpacings = [0, 0, 20]
        m.buttonsListGrp.scale = [1.0, 1.0]
        width = m.innerRightSection.width - (2 * m.innerPadding)
        itemSpacing = 0
        mCount = 0
        content = viewData.buttonsListGrp
        if isSupFilter
            content = viewData.buttonsListSupFilter
            mCount = content.getChildCount()
            itemSpacing = 60
            width = ((width) - ((mCount - 1) * itemSpacing)) / mCount
        else if isIAB
            content = viewData.buttonsListIABGrp
            width = width / 2
        end if
        m.buttonsListGrp.itemSpacing = [itemSpacing, 15]
        m.buttonsListGrp.numColumns = mCount
        m.buttonsListGrp.translation = [m.innerRightSection.translation[0], 0]
        m.buttonsListGrp.itemSize = [width, m.charsize]
        m.buttonsListGrp.content = content
    end if
    m.subGrpListGrp.scale = [0.0, 0.0]
    if viewData.heading <> invalid and viewData.heading <> ""
        m.heading.text = viewData.heading
        m.heading.scale = [1, 1]
        m.heading.translation = [m.innerPadding, 0]
        if viewData.subGrpButtonContent <> invalid and viewData.subGrpButtonContent.getChildCount() > 0
            m.titleLayout.itemSpacings = [20, 0, 0, 0]
            m.subGrpListGrp.scale = [1.0, 1.0]
            m.subGrpListGrp.content = viewData.subGrpButtonContent
            m.subGrpListGrp.translation = [m.innerRightSection.translation[0], 0]
            m.subGrpListGrp.itemSize = [m.innerRightSection.width - (2 * m.innerPadding), m.charsize]
            m.subGrpListGrp.itemClippingRect = [0, 0, m.subGrpListGrp.itemSize[0], m.rightsection.height - m.innerRightSection.height + 20]
            if optionalChaining(viewData, "subgroubHeights") <> invalid and viewData.subgroubHeights.count() > 0
                m.subGrpListGrp.rowHeights = viewData.subgroubHeights
                m.subGrpListGrp.numRows = 6
                m.subGrpListGrp.itemFocused = 0
                setlistNumrows(m.subGrpListGrp, m.subGrpListGrp.rowHeights, m.subGrpListGrp.itemClippingRect.height)
            end if
        else
            m.description.translation = [m.innerPadding, 0]
            m.description.visible = true
            getVendorDescriptions(viewData, m.heading.color, m.innerRightSection.width, m.description)
            dchild = m.description.getChild(0)
            if dchild <> invalid and dchild.getChildCount() > 0 and not isSupFilter and not m.vendorType = "sdk"
                m.horzLine.scale = [1, 1]
                m.horzLine.visible = true
                m.horzLine.width = m.innerRightSection.width
                m.horzLine.translation = [m.innerPadding, 0]
            end if
            m.scrollThumb.translation = [m.innerRightSection.width, 0]
            m.scrollThumb.color = m.heading.color
            m.innerRightSection.height = m.titleLayout.boundingRect().height
            m.descriptionRec.translation = [m.innerPadding, m.innerRightSection.height + 20]
            m.descriptionRec.height = m.mainRect.height - m.descriptionRec.translation[1]
            m.scrollThumb.height = scrollHeight()
        end if
    end if
    m.titleLayout.translation = [-m.innerPadding, 0]
    m.heading.width = m.innerRightSection.width
    if viewData.buttonContent <> invalid
        m.buttonList.content = viewData.buttonContent
        tranButtonListH = m.charsize + m.charsize
        if m.parent <> invalid and m.parent.filterType <> invalid and m.parent.filterType.vendorType = "sdk"
            tranButtonListH = m.charsize
        end if
        m.buttonList.itemSize = [m.innerLeftSection.width - m.innerPadding, m.charsize]
        m.buttonList.itemClippingRect = [0, 0, m.buttonList.itemSize[0], m.innerLeftSection.height - tranButtonListH]
        m.buttonList.translation = [0, tranButtonListH]
        m.VertLine.translation = [m.buttonList.itemSize[0], 0]
        m.VertLine.height = m.innerLeftSection.height
    end if

    if m.buttonList.rowHeights.Count() <= 0
        m.buttonList.rowHeights = m.buttonListWidth
    end if
    setlistNumrows(m.buttonList, m.buttonListWidth, m.buttonList.itemClippingRect.height)

end function

function setlistNumrows(buttonList, buttonHeightList, height)
    ' get rowHeights and numRows of category list to wrap text
    if buttonList.content <> invalid and buttonHeightList <> invalid and buttonHeightList.count() > 0 and buttonList.itemFocused <> -1
        buttonlistH = 0
        numRows = 0
        btncount = buttonList.content.getChildCount()
        if btncount <> invalid and btncount > 0
            c = btncount - 1
            for i = 0 to c
                if buttonList.itemFocused = 0 or buttonList.itemFocused = -1 or buttonList.numRows >= buttonList.itemFocused or buttonList.itemFocused - buttonList.numRows <= i
                    buttonlistH = buttonlistH + buttonList.rowHeights[i] + buttonList.itemSpacing[1]
                    if height > buttonlistH
                        numRows = numRows + 1
                    else
                        exit for
                    end if
                end if
            end for
        end if
        buttonList.numRows = numRows - 1
    end if
end function

function onKeyEvent(key as string, press as boolean) as boolean
    handled = false
    if press
        if key = "up"
            handled = true
            if m.actionButtonList.hasFocus()
                if m.buttonList.content <> invalid and m.buttonList.content.getChildCount() > 0
                    itemUnfocused = m.buttonList.content.getChild(m.buttonList.itemFocused)
                    if not itemUnfocused.isunFocused
                        itemUnfocused.isunFocused = true
                        itemUnfocused.isunFocused = false
                        m.buttonList.setFocus(true)
                    else
                        if m.buttonsListGrp.content <> invalid and m.buttonsListGrp.content.getChildCount() > 0
                            m.buttonsListGrp.jumpToItem = 0
                            m.buttonsListGrp.setFocus(true)
                        else if m.scrollThumb.visible
                            setScrollFocus()
                        else
                            itemUnfocused.isunFocused = true
                            m.buttonList.setFocus(true)
                        end if
                    end if
                else
                    handled = false
                end if
            else if m.subGrpListGrp.hasFocus() and m.buttonsListGrp.content <> invalid and m.buttonsListGrp.content.getChildCount() > 0
                m.buttonsListGrp.setFocus(true)
            else if m.buttonList.hasFocus()
                m.buttonList.jumpToItem = 0
                handled = false
            else if m.scrollThumb.visible and isScrollable("up")
                scroll("up")
            else if m.buttonsListGrp.content <> invalid and m.buttonsListGrp.content.getChildCount() > 0
                resetScroll()
                m.buttonsListGrp.setFocus(true)
            end if
        else if key = "down"
            if m.buttonList.hasFocus() and m.actionButtonList.visible and m.buttonList.content <> invalid and m.buttonList.content.getChildCount() > 0
                lastItem = m.buttonList.content.getChildCount() - 1
                m.buttonList.jumpToItem = lastItem
                m.actionButtonList.setFocus(true)
            else if m.buttonsListGrp.hasFocus() and m.subGrpListGrp.content <> invalid and m.subGrpListGrp.content.getChildCount() > 0
                m.subGrpListGrp.setFocus(true)
            else if m.scrollThumb.visible and isScrollable("down") and not m.actionButtonList.hasFocus()
                setScrollFocus()
                scroll("down")
            else
                m.subGrpListGrp.jumpToItem = 0
                resetScroll()
                m.actionButtonList.setFocus(true)
            end if
            handled = true
        else if key = "right"
            if m.buttonList.hasFocus() and m.buttonList.content <> invalid and m.buttonList.content.getChildCount() > 0
                itemUnfocused = m.buttonList.content.getChild(m.buttonList.itemFocused)
                itemUnfocused.isunFocused = true
                if m.buttonsListGrp.content <> invalid and m.buttonsListGrp.content.getChildCount() > 0
                    m.buttonsListGrp.setFocus(true)
                else if m.scrollThumb.visible
                    setScrollFocus()
                else
                    m.actionButtonList.setFocus(true)
                end if
            end if
            handled = true
        else if key = "left"
            handled = true
            if m.buttonsListGrp.hasFocus() or m.subGrpListGrp.hasFocus() or m.description.hasFocus()
                itemUnfocused = m.buttonList.content.getChild(m.buttonList.itemFocused)
                resetScroll()
                if itemUnfocused <> invalid
                    itemUnfocused.isunFocused = true
                    itemUnfocused.isunFocused = false
                    m.buttonList.setFocus(true)
                else
                    handled = false
                end if
            end if
        end if
    end if
    return handled
end function

function onKeyDownClose(key)
    if key = "right"
        if m.buttonsListGrp.content <> invalid and m.buttonsListGrp.content.getChildCount() > 0
            m.buttonsListGrp.setFocus(true)
        else if m.scrollThumb.visible
            setScrollFocus()
        end if
    else if key = "down"
        if m.buttonList.content <> invalid and m.buttonList.content.getChildCount() > 0
            itemUnfocused = m.buttonList.content.getChild(m.buttonList.itemFocused)
            itemUnfocused.isunFocused = true
            itemUnfocused.isunFocused = false
            m.buttonList.setFocus(true)
        else
            m.actionButtonList.setFocus(true)
        end if
    end if
end function

function getListChildCount() as integer
    return m.buttonList.content.getChildCount()
end function

function onItemSelection(node as object)
    list = node.getRoSGNode()
    selectedItem = list.itemSelected
    item = list.content.getChild(selectedItem)
    if item.groupRecId <> "buttonsListIABGrp"
        if item.groupRecId = "subGrpListGrp"
            m.buttonsListGrp.setFocus(true)
        end if
        if optionalChaining(item, "groupdata.type") <> invalid and item.groupdata.type = "qrCode"
            qrCodeDialog(item)
        else
            m.top.itemSelected = item
        end if
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
    itemFocused = m.buttonList.itemFocused
    item = m.buttonList.content.getChild(itemFocused)
    if m.top.itemFocused = invalid or m.top.itemFocused.OptanonGroupId <> item.OptanonGroupId 'OR m.leftArrow.visible
        m.top.itemFocused = item
    end if
end function

function onItemsubGrpFocused() as void
    setlistNumrows(m.subGrpListGrp, m.subGrpListGrp.rowHeights, m.subGrpListGrp.itemClippingRect.height)
end function

function getVendorDescriptions(viewData, color, width, node)
    child = node.getChild(0)
    if child <> invalid then node.removeChild(child)
    fragment = m.getNode.layoutGroup("fragment", "vert", [30])
    node.appendChild(fragment)
    vendor = optionalChaining(viewData, "groupData")
    url = optionalChaining(viewData, "deviceStorageDisclosureUrl")
    dataRetentionPurpose = {}
    dataRetentionSP = {}
    if m.dataCategories = invalid and optionalChaining(m.preferenceData, "IABDataCategories") <> invalid and  m.preferenceData.IABDataCategories.count() > 0
        m.dataCategories = {dataCategories:{}}
        for each item in m.preferenceData.IABDataCategories
            m.dataCategories["dataCategories"][item["Id"].toStr()] = item
        end for
    end if
    ' sdk description
    if vendor <> invalid and m.vendorType = "sdk" and vendor.description <> invalid and vendor.description <> "" then fragment.appendChild(m.getNode.label("description", vendor.description, "font:SmallSystemFont", color, width))

    ' iab description
    if vendor <> invalid and (vendor.cookieMaxAgeSeconds <> invalid or m.vendorType = "iab") then fragment = setDisclosuresLayout(fragment, "cookieMaxAgeSeconds", m.preferenceData.VendorListLifespan + ": ", calculateCookieLifespan(vendor.cookieMaxAgeSeconds), color, width * 0.3, width * 0.7, "font:MediumBoldSystemFont")

    if vendor <> invalid and m.vendorType = "iab" and optionalChaining(m.preferenceData, "VendorListNonCookieUsage") <> invalid and m.preferenceData.VendorListNonCookieUsage <> "" then fragment.appendChild(m.getNode.label("usesNonCookieAccess", m.preferenceData.VendorListNonCookieUsage, "font:SmallSystemFont", color, width))

    if vendor <> invalid and vendor.dataDeclaration <> invalid and isIAB2V2() and vendor.dataDeclaration.count() > 0 then fragment = setDisclosuresLayout(fragment, "dataCategories", m.preferenceData.PCVListDataDeclarationText, vendor.dataDeclaration, color, width, width, "font:MediumBoldSystemFont", "vert")

    if vendor <> invalid and vendor.dataRetention <> invalid and isIAB2V2() then fragment = setDisclosuresLayout(fragment, "dataRetention", m.preferenceData.PCVListDataRetentionText, vendor.dataRetention, color, width, width, "font:MediumBoldSystemFont", "vert")

    if vendor <> invalid and optionalChaining(vendor.dataRetention, "purposes") <> invalid and isIAB2V2() then dataRetentionPurpose = vendor.dataRetention.purposes
    if vendor <> invalid and vendor.purposes <> invalid and isConsent(vendor) and vendor.purposes.count() > 0 then fragment = setDisclosuresLayout(fragment, "purpose", m.preferenceData.ConsentPurposesText, vendor.purposes, color, width, width, "font:MediumBoldSystemFont", "vert", dataRetentionPurpose)

    if vendor <> invalid and optionalChaining(vendor.dataRetention, "specialPurposes") <> invalid and isIAB2V2() then dataRetentionSP = vendor.dataRetention.specialPurposes
    if vendor <> invalid and vendor.specialPurposes <> invalid and vendor.specialPurposes.count() > 0 then fragment = setDisclosuresLayout(fragment, "sp", m.preferenceData.SpecialPurposesText, vendor.specialPurposes, color, width, width, "font:MediumBoldSystemFont", "vert", dataRetentionSP)

    if vendor <> invalid and vendor.legIntPurposes <> invalid and isVendorLegitimateInterest(vendor, m.preferenceData.LegIntSettings) and vendor.legIntPurposes.count() > 0 then fragment = setDisclosuresLayout(fragment, "purpose", m.preferenceData.LIPurposesText, vendor.legIntPurposes, color, width, width, "font:MediumBoldSystemFont", "vert", dataRetentionPurpose)

    if vendor <> invalid and vendor.features <> invalid and vendor.features.count() > 0 then fragment = setDisclosuresLayout(fragment, "feature", m.preferenceData.FeaturesText, vendor.features, color, width, width, "font:MediumBoldSystemFont", "vert")

    if vendor <> invalid and vendor.specialFeatures <> invalid and vendor.specialFeatures.count() > 0 then fragment = setDisclosuresLayout(fragment, "sf", m.preferenceData.SpecialFeaturesText, vendor.specialFeatures, color, width, width, "font:MediumBoldSystemFont", "vert")

    if url <> invalid and url <> ""
        url = url.Trim()
        m.disclosureIndex = fragment.getChildCount()
        m.disclosureUrl = url
        if m.deviceStorageDisclosureData.doesExist(url)
            parseDeviceStorageDisclosureData({ url: url, response: m.deviceStorageDisclosureData[url] })
        else
            getDeviceStorageDisclosureData(url)
        end if
    end if

    return fragment
end function

function getDeviceStorageDisclosureData(url as dynamic)
    if m.initializeNetwork <> invalid then m.initializeNetwork.control = "STOP"
    m.initializeNetwork = CreateObject("roSGNode", "OTNetworkTask")
    m.initializeNetwork.functionName = "OTgetContent"
    m.initializeNetwork.url = url
    m.initializeNetwork.unobserveField("response")
    m.initializeNetwork.unobserveField("taskCompleted")
    m.initializeNetwork.observeField("taskCompleted", "taskCompleted")
    m.initializeNetwork.observeField("response", "parseDeviceStorageDisclosureData")
    m.initializeNetwork.control = "RUN"
end function

function taskCompleted() 
    if m.initializeNetwork <> invalid 
        m.initializeNetwork.unobserveField("taskCompleted")
        m.initializeNetwork.unobserveField("response")
        m.initializeNetwork.control = "STOP"
        m.initializeNetwork = invalid
    end if
end function

function parseDeviceStorageDisclosureData(data as object)
    if type(data) = "roSGNodeEvent" then data = data.getData()
    if m.disclosureUrl = data.url
        m.deviceStorageDisclosureData[data.url] = data.response
        data = data.response
    else
        data = invalid
    end if
    if data <> invalid and ((data.disclosures <> invalid and data.disclosures.count() > 0) or (data.domains <> invalid and data.domains.count() > 0))
        deviceStorageDisclosure = getNode().layoutGroup("deviceStorageDisclosure", "vert", [20, 30, 20])
        fragment = m.description.getChild(0)
        if fragment <> invalid and fragment.getChildCount() > 0
            for i = 0 to fragment.getChildCount() - 1
                child = fragment.getChild(i)
                if child.id <> invalid and child.id = "deviceStorageDisclosure"
                    fragment.removeChild(child)
                    exit for
                end if
            end for
            fragment.insertChild(deviceStorageDisclosure, m.disclosureIndex)
        end if
    end if
    color = m.heading.color
    width = m.innerRightSection.width
    if data <> invalid and data.disclosures <> invalid and data.disclosures.count() > 0
        VendorListDisclosureLabel = getNode().label("VendorListDisclosureLabel", m.preferenceData.VendorListDisclosure, "font:MediumBoldSystemFont", color, width)
        deviceStorageDisclosure.appendChild(VendorListDisclosureLabel)
        VendorListDisclosureLayoutGroup = getNode().layoutGroup("VendorListDisclosureLayoutGroup", "vert", [20])

        for each disclosure in data.disclosures
            VendorListDisclosureinnerLayoutGroup = getNode().layoutGroup("VendorListDisclosureinnerLayoutGroup")
            identifier = ""
            if disclosure <> invalid and disclosure.identifier <> invalid then identifier = disclosure.identifier
            if disclosure <> invalid and disclosure.name <> invalid then identifier = disclosure.name
            if identifier <> invalid then VendorListDisclosureinnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureinnerLayoutGroup, "identifier", m.preferenceData.VendorListStorageIdentifier + ": ", identifier, color, width * 0.3, width * 0.7)
            if disclosure <> invalid and disclosure.type <> invalid then VendorListDisclosureinnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureinnerLayoutGroup, "storageType", m.preferenceData.VendorListStorageType + ": ", disclosure.type, color, width * 0.3, width * 0.7)
            if disclosure <> invalid then VendorListDisclosureinnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureinnerLayoutGroup, "lifeSpan", m.preferenceData.VendorListLifespan + ": ", calculateCookieLifespan(disclosure.maxAgeSeconds), color, width * 0.3, width * 0.7)
            if disclosure <> invalid and disclosure.domain <> invalid and (type(disclosure.domain) = "roString" or type(disclosure.domain) = "String") then VendorListDisclosureinnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureinnerLayoutGroup, "domain", m.preferenceData.VendorListStorageDomain + ": ", disclosure.domain, color, width * 0.3, width * 0.7)
            if disclosure <> invalid and disclosure.purposes <> invalid and type(disclosure.purposes) = "roArray" and disclosure.purposes.count() > 0 then VendorListDisclosureinnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureinnerLayoutGroup, "purpose", m.preferenceData.VendorListStoragePurposes + ": ", disclosure.purposes, color, width * 0.3, width * 0.7)
            VendorListDisclosureLayoutGroup.appendChild(VendorListDisclosureinnerLayoutGroup)
        end for
        deviceStorageDisclosure.scale = [1, 1]
        deviceStorageDisclosure.appendChild(VendorListDisclosureLayoutGroup)
    end if
    parseDeviceStorageDisclosureDomainData(data, deviceStorageDisclosure)
    m.scrollThumb.height = scrollHeight()
end function

function parseDeviceStorageDisclosureDomainData(data, deviceStorageDisclosure)
    if data <> invalid and data.domains <> invalid and data.domains.count() > 0
        color = m.heading.color
        width = m.innerRightSection.width
        VendorListDisclosureDomainLabel = getNode().label("VendorListDisclosureDomainLabel", m.preferenceData.VendorTitleDomainUsed, "font:MediumBoldSystemFont", color, width)
        deviceStorageDisclosure.appendChild(VendorListDisclosureDomainLabel)
        VendorListDisclosureDomainLayoutGroup = getNode().layoutGroup("VendorListDisclosureDomainLayoutGroup", "vert", [20])

        for each disclosure in data.domains
            VendorListDisclosureDomaininnerLayoutGroup = getNode().layoutGroup("VendorListDisclosureDomaininnerLayoutGroup")
            if disclosure <> invalid and type(disclosure) = "roAssociativeArray" and disclosure.domain <> invalid then VendorListDisclosureDomaininnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureDomaininnerLayoutGroup, "domain", m.preferenceData.VendorListStorageDomain + ": ", disclosure.domain, color, width * 0.3, width * 0.7)
            if disclosure <> invalid and type(disclosure) = "roAssociativeArray" and disclosure.use <> invalid then VendorListDisclosureDomaininnerLayoutGroup = setDisclosuresLayout(VendorListDisclosureDomaininnerLayoutGroup, "use", m.preferenceData.VendorDomainUsed + ": ", disclosure.use, color, width * 0.3, width * 0.7)
            VendorListDisclosureDomainLayoutGroup.appendChild(VendorListDisclosureDomaininnerLayoutGroup)
        end for

        deviceStorageDisclosure.appendChild(VendorListDisclosureDomainLayoutGroup)
    end if
end function

function calculateCookieLifespan(maxSeconds, inDays = false as boolean)
    if maxSeconds <> invalid and (type(maxSeconds) = "roString" or type(maxSeconds) = "String") then maxSeconds = maxSeconds.ToInt()
    VendorListLifespanDay = m.preferenceData.VendorListLifespanDay
    VendorListLifespanDays = m.preferenceData.VendorListLifespanDays
    VendorListLifespanMonth = m.preferenceData.VendorListLifespanMonth
    VendorListLifespanMonths = m.preferenceData.VendorListLifespanMonths

    if maxSeconds = invalid or maxSeconds <= 0 then return "0" + " " + VendorListLifespanDays
    finalString = ""
    if inDays
        days = maxSeconds
        if days >= 2 then finalString = days.toStr() + " " + VendorListLifespanDays
        if days = 1 then finalString = days.toStr() + " " + VendorListLifespanDay
    else
        months = Fix(maxSeconds / m.LifeSpanDuration.SECOND_DIVIDER)
        remainderMonths = maxSeconds mod m.LifeSpanDuration.SECOND_DIVIDER
        days = Fix(remainderMonths / m.LifeSpanDuration.MONTH_DIVIDER)
        if days = 30
            months = months + 1
            days = 0
        end if
        if months >= 2 then finalString = months.toStr() + " " + VendorListLifespanMonths
        if months = 1 then finalString = months.toStr() + " " + VendorListLifespanMonth
        if days >= 2 then finalString += " " + days.toStr() + " " + VendorListLifespanDays
        if days = 1 then finalString += " " + days.toStr() + " " + VendorListLifespanDay
        if months = 0 and days = 0 then finalString = days.toStr() + " " + VendorListLifespanDays
    end if

    return finalString
end function

function isConsent(props)
    return props.shouldShowConsentToggleForVendor
end function

function setDisclosuresLayout(node, id, header, value, color, headerW, valueW, font = "font:SmallSystemFont", direction = "horiz", dataRetention = invalid)
    disclosuresLayoutGroup = m.getNode.layoutGroup(id + "LayoutGroup", direction)
    disclosuresHeader = m.getNode.label(id + "Header", header, font, color, headerW)
    if id = "purpose" or id = "feature" or id = "sp" or id = "sf" or id = "dataCategories" or id = "dataRetention"
        disclosuresValue = setlistLayout(id, value, color, valueW, dataRetention)
    else
        disclosuresValue = m.getNode.label(id, value, "font:SmallSystemFont", color, valueW)
    end if
    disclosuresLayoutGroup.appendChild(disclosuresHeader)
    disclosuresLayoutGroup.appendChild(disclosuresValue)
    node.appendChild(disclosuresLayoutGroup)
    return node
end function

function setlistLayout(id, list, color, width, dataRetention)
    innerLayoutGroup = m.getNode.layoutGroup(id + "InnerLayoutGroup")
    iabGrps = m.preferenceData.iabGroups
    if id = "dataCategories"
        if m.dataCategories <> invalid 
            iabGrps = m.dataCategories
        else 
            iabGrps = {dataCategories:{}}
        end if
    end if
    if id = "dataRetention"
        if list <> invalid and list.stdRetention <> invalid and optionalChaining(m.preferenceData, "PCVListStdRetentionText") <> invalid
            text = m.preferenceData.PCVListStdRetentionText + " (" + calculateCookieLifespan(list.stdRetention, true) + ")"
            listNode = m.getNode.label(id + "_" + "stdRetention", text, "font:SmallSystemFont", color, width)
            innerLayoutGroup.appendChild(listNode)
        end if
    else if list <> invalid and list.count() > 0
        for each l in list
            text = iabGrps[id][l.toStr()]
            if id = "dataCategories" and optionalChaining(text, "Name") <> invalid then text = text["Name"]
            if text <> invalid and text <> ""
                if (id = "purpose" or id = "sp") and dataRetention <> invalid and dataRetention[l.toStr()] <> invalid
            text += " (" + calculateCookieLifespan(dataRetention[l.toStr()], true) + ")"
        end if
        listNode = m.getNode.label(id + "_" + l.toStr(), Chr(8226) + " " + text, "font:SmallSystemFont", color, width)
        innerLayoutGroup.appendChild(listNode)
    end if
end for
end if
return innerLayoutGroup
end function

function qrCodeDialog(item)
    if item.name <> invalid and item.description <> invalid and item.name <> "" and item.description <> ""
        currDialog = createObject("roSGNode", "qrCodeDialog")
        currDialog.id = "qrCode_" + item.groupRecId
        currDialog.show = true
        currDialog.qrCodeLightColor = item.focusButtonColor
        currDialog.qrCodeDarkColor = item.focusButtonTextColor
        currDialog.headerColor = item.focusButtonTextColor
        currDialog.headerText = item.name
        currDialog.uri = item.description
        if currDialog <> invalid
            m.top.getScene().dialog = currDialog
        end if
    end if
end function