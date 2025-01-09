Function init()
    m.constants = getConstantsFromGlobal()

    m.panelGroup = m.top.findNode("PanelGroup")
    m.description = m.top.findNode("Description")
    m.subDescription = m.top.findNode("SubDescription")
    m.titleGroup = m.top.findNode("TitleGroup")
    m.title = m.top.findNode("Title")
    m.titleImage = m.top.findNode("TitleImage")
    m.QRCodeImage = m.top.findNode("QRCodeImage")
    m.QRParentGroup = m.top.findNode("QRParentGroup")
    m.QRContentParentGroup = m.top.findNode("QRContentParentGroup")
    m.QRBackground = m.top.findNode("QRBackground")
    m.QRBackgroundSpacing = m.top.findNode("QRBackgroundSpacing")
    m.descriptionTextGroup = m.top.findNode("DescriptionTextGroup")

    m.top.observeFieldScoped("content", "onContentChange")

    m.typographyConstants = getTypographyConstants()
    setTypographyOfLabel(m.description, m.typographyConstants.ids.bodySmallStrong)
    setTypographyOfLabel(m.subDescription, m.typographyConstants.ids.bodyExtraSmall)
    setTypographyOfLabel(m.title, m.typographyConstants.ids.bodyMediumStrong)

    if m.global <> invalid
        m.global.observeFieldScoped("theme", "onThemeChange")
    end if
    onThemeChange()
End Function


Function onThemeChange(msg = invalid)
    if msg <> invalid
        theme = msg.getData()
    else
        theme = getThemeFromGlobal()
    end if

    if theme <> invalid
        m.title.color = theme.primaryTextColor
        m.description.color = theme.primaryTextColor
        m.subDescription.color = theme.primaryTextColor
        m.QRBackground.blendColor = theme.shadeColor2
    end if
End Function


Function onContentChange(msg)
    content = msg.getData()

    sTitle = content.title
    sTitleImage = content.titleImageUrl
    sDescription = content.description
    sSubDescription = content.subDescription
    sQRCodeUri = content.qrCodeUrl

    '//Reset the labels
    m.title.width = 0
    m.description.width = 0
    m.subDescription.width = 0
    m.title.text = ""
    m.description.text = ""
    m.subDescription.text = ""
    m.descriptionTextGroup.itemSpacings = [12]

    bTitleAvailable = (isNonEmptyString(sTitle) = true or isNonEmptyString(sTitleImage) = true)
    if bTitleAvailable = false
        '//title not present so do not show
        m.descriptionTextGroup.removeChild(m.titleGroup)
    else
        m.descriptionTextGroup.appendChild(m.titleGroup)
        m.title.text = sTitle
        setTitleImage(sTitleImage)
    end if

    if isNonEmptyString(sDescription) = true
        m.descriptionTextGroup.appendChild(m.description)
        m.description.text = sDescription
    else
        m.descriptionTextGroup.removeChild(m.description)
    end if

    if isNonEmptyString(sSubDescription) = true
        m.descriptionTextGroup.appendChild(m.subDescription)
        m.subDescription.text = sSubDescription
    else
        m.descriptionTextGroup.removeChild(m.subDescription)
    end if

    '//Determine the widest heading and use that in part to determine the width of the QR background if the QR code is visible
    nWidestHeading = m.description.boundingRect().width
    if m.subDescription.boundingRect().width > nWidestHeading
        nWidestHeading = m.subDescription.boundingRect().width
    end if
    if bTitleAvailable = true
        if m.titleImage.getParent() <> invalid
            if m.titleImage.boundingRect().width > nWidestHeading
                nWidestHeading = m.titleImage.boundingRect().width
            end if
        else
            if m.title.boundingRect().width > nWidestHeading
                nWidestHeading = m.title.boundingRect().width
            end if
        end if
    end if

    m.description.width = nWidestHeading
    m.subDescription.width = nWidestHeading
    m.title.width = nWidestHeading
    nPaddingTop = m.QRBackgroundSpacing.translation[1]
    nPaddingLeft = m.QRBackgroundSpacing.translation[0]

    if isNonEmptyString(sQRCodeUri) = true
        m.QRCodeImage.uri = sQRCodeUri
        m.QRContentParentGroup.appendChild(m.QRCodeImage)
        m.QRContentParentGroup.appendChild(m.descriptionTextGroup)
        m.panelGroup.appendChild(m.QRParentGroup)

        nPaddingInside = m.QRContentParentGroup.itemSpacings[0]

        if nWidestHeading > 0
            nHeaderWidth = (nPaddingInside * 2) + nWidestHeading
        else
            '//if there are no headers visible, then set the right padding of the QR background to be the same as the left padding
            nHeaderWidth = nPaddingLeft
        end if

        nHeightOfVisibleAssets = m.QRContentParentGroup.boundingRect().height

        m.QRBackground.height = nPaddingTop + nHeightOfVisibleAssets + nPaddingTop 'Add padding to the top and bottom of the height of the visible assets
        m.QRBackground.width = nPaddingLeft + m.QRCodeImage.width + nHeaderWidth

    else
        if bTitleAvailable = true
            '//if the title is available, then display the contents within a background box
            m.QRContentParentGroup.appendChild(m.descriptionTextGroup)
            m.QRContentParentGroup.removeChild(m.QRCodeImage)

            nHeightOfVisibleAssets = m.QRContentParentGroup.boundingRect().height
            m.QRBackground.height = nPaddingTop + nHeightOfVisibleAssets + nPaddingTop 'Add padding to the top and bottom of the height of the visible assets
            m.QRBackground.width = nPaddingLeft + nWidestHeading + nPaddingLeft
        else
            m.panelGroup.appendChild(m.descriptionTextGroup)
            m.panelGroup.removeChild(m.QRParentGroup)
        end if
    end if
End Function


Function setTitleImage(titleImageUri)
    if isNonEmptyString(titleImageUri) = true
        m.titleGroup.appendChild(m.titleImage)
        m.titleGroup.removeChild(m.title)
        m.titleImage.uri = replaceURLParameter(titleImageUri, "h", m.titleImage.height.toStr(), true)
        m.descriptionTextGroup.itemSpacings = [0, 12]
    else
        m.titleGroup.appendChild(m.title)
        m.titleGroup.removeChild(m.titleImage)

        m.titleImage.uri = ""
    end if
End Function
