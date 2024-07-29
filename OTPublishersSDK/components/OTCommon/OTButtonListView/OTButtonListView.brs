function itemContentChanged() as void
	screenSize = m.global.screenSize
	m.paddingH = 10
	m.onFocusWidth = 0
	if screenSize.h = 1080 then m.paddingH = 15
	m.itemData = m.top.itemContent
	m.itemText.text = m.itemData.name
	m.additionalText.text = m.itemData.additionalText
	m.top.id = m.itemData.id
	m.parent = m.top.getParent()
	m.buttonColor = "0xEEEEEE"
	m.buttonTextColor = "0x14191f"
	m.rightArrow.visible = false
	m.leftArrow.visible = false
	m.statusImage.visible = false
	if m.itemData.buttonColor <> invalid and m.itemData.buttonColor <> ""
		m.buttonColor = m.itemData.buttonColor
	end if
	if m.itemData.buttonTextColor <> invalid and m.itemData.buttonTextColor <> ""
		m.buttonTextColor = m.itemData.buttonTextColor
	end if
	if m.itemData.groupData <> invalid and m.itemData.groupRecId = "subGrpListGrp"
		m.rightArrow.visible = true
	end if
	m.itemTextWidth = m.top.width - 24
	m.itemText.horizAlign = "left"
	m.itemText.height = m.top.height - (m.paddingH * 2)
	m.statusText.height = m.top.height
	m.statusImage.translation= [80,m.top.height/2 - (m.statusImage.height - 1)/2]
	m.rightArrow.translation= [90,m.top.height/2 - m.rightArrow.height/2]
	if m.itemData.status <> invalid and m.itemData.status <> "" and (m.itemData.groupRecId = "supportFilterList" or m.itemData.groupRecId = "buttonsListGrp" or m.itemData.groupRecId = "subGrpListGrp" OR m.itemData.groupRecId = "buttonsListLIGrp")
		'if m.itemData.isToggleOption
			setStatus(m.itemData.status)
		'end if
	else 'if not m.itemData.groupRecId = "vendorButtonList"
		m.itemText.horizAlign = "center"
	end if
	if m.itemData.groupRecId = "vendorFilterList"
		m.btnImg.visible = true
		m.btnImg.height = m.top.height - 22
		m.btnImg.width = m.top.width - 4
		m.btnImg.uri = "pkg:/components/OTPublishersSDK/images/button.png"
		m.itemBg.visible = false
		m.border.visible = false
		m.itemText.visible = true
		m.filterImg.visible = false
		if m.itemData.name = "filterIcon"
			m.btnImg.visible = false
			m.itemText.visible = false
			m.filterImg.visible = true
		else if m.itemData.name = "backIcon"
			m.leftArrow.visible = true
			m.btnImg.width = m.btnImg.height
			m.leftArrow.translation= [m.top.width/2 - m.rightArrow.width/2 + 4,m.top.height/2 - m.rightArrow.height/2]
			m.btnImg.uri = "pkg:/components/OTPublishersSDK/images/circle.png"
			m.itemText.visible = false
		end if
	end if
	if m.itemData.groupRecId = "closetextList"
		m.border.visible = false
	end if
	if m.itemData.groupRecId = "bannerRightButtons"
		m.onFocusWidth = 40
	end if
	m.itemText.width = m.itemTextWidth
	m.havingAdditionaltext = false
	if isIAB2V2() and m.itemData.groupData <> invalid and (m.itemData.groupRecId = "subGrpListGrp" or m.itemData.groupRecId = "pcGroupList")
		m.havingAdditionaltext = true
		m.itemText.horizAlign = "left"
		if m.itemData.additionalText <> invalid and m.itemData.additionalText <> ""
			m.additionalText.font = "font:SmallSystemFont"
			m.additionalText.width = m.itemTextWidth
			additionalTextWH = m.additionalText.boundingRect()
			m.itemText.height = m.itemText.height - additionalTextWH.height
			m.additionalText.horizAlign = m.itemText.horizAlign
			m.additionalText.visible = m.itemText.visible
		end if
	end if
end function

function setStatus(status = "" as string)
	if status = ""
		status = m.top.status
	end if
	m.itemTextWidth = m.itemTextWidth - 120
	m.statusRec.translation = [m.itemTextWidth, 0]
	m.statusText.translation = [0, 0]
	if status = "always active"
		m.statusText.text = m.itemData.alwaysActiveText
		if m.itemData.groupRecId = "buttonsListGrp"
			m.itemText.text = m.itemData.alwaysActiveText
			m.statusText.visible = false
		else
			m.statusText.visible = true
		end if
		m.statusText.scale = [1.0, 1.0]
		m.statusImage.visible = false
		m.rightArrow.visible = false
		m.statusImage.scale = [0.0, 0.0]
	else
		if m.itemData.groupRecId = "subGrpListGrp"
			if status = "active"
				m.statusText.text = m.itemData.activeText
			else if status.Instr("inactive") <> -1
				m.statusText.text = m.itemData.inactiveText
			end if
			m.statusText.visible = true
			m.statusText.scale = [1.0, 1.0]
			m.statusImage.visible = false
			m.rightArrow.visible = true
			m.statusImage.scale = [0.0, 0.0]
			m.statusText.translation = [-40, 0]
		else
			uri = ""
			if status = "active"
				uri = "pkg:/components/OTPublishersSDK/images/checkbox-selected.png"
			else if status.Instr("inactive") <> -1
				uri = "pkg:/components/OTPublishersSDK/images/checkbox-unselected.png"
			end if
			if m.itemData.groupRecId = "buttonsListLIGrp" 
				m.itemText.text = m.itemData.BLegitInterestText
			else if m.itemData.groupRecId = "buttonsListGrp"
				m.itemText.text = m.itemData.BConsentText
			end if
			m.statusImage.uri = uri
			m.statusImage.visible = true
			m.statusImage.scale = [1.0, 1.0]
			m.statusText.visible = false
			m.statusText.scale = [0.0, 0.0]
		end if
	end if
	m.top.status = status
end function

function updateFocus() as void
	m.itemBg.height = m.top.height - 4
	m.itemBg.width = m.top.width - 4
	m.border.height = m.top.height
	m.itemText.width = m.itemTextWidth
	m.itemText.translation = [10, m.paddingH]
	'updateOnTextEllipsized()
	if m.top.focusPercent > 0.5 and m.top.gridHasFocus
		m.itemBg.Color = m.itemData.focusButtonColor
		m.btnImg.blendColor = m.itemData.focusButtonColor
		m.filterImg.blendColor = m.itemData.focusButtonColor
		m.statusImage.blendColor = m.itemData.focusButtonTextColor
		m.itemText.color = m.itemData.focusButtonTextColor
		m.statusText.color = m.itemData.focusButtonTextColor
		m.border.color = m.itemData.focusButtonTextColor
		m.rightArrow.blendColor = m.itemData.focusButtonTextColor
		m.leftArrow.blendColor = m.itemData.focusButtonTextColor
		m.border.width = m.top.width
		m.itemText.width = m.itemTextWidth + 8
		m.itemText.translation = [6,m.paddingH]
		m.itemBg.translation = [2, 2]
		m.border.translation = [0, 0]
		if not m.havingAdditionaltext then m.itemText.font = "font:MediumBoldSystemFont"
		if m.itemData.groupRecId = "vendorFilterList" or m.itemData.groupRecId = "vendorMenuList"
			m.itemText.font = "font:SmallBoldSystemFont"
		end if
		m.filterImg.height = 34 + m.paddingH
		m.filterImg.width = 34 + m.paddingH
		m.filterImg.translation = [-7, 3 + m.paddingH/2]
		if m.itemData.isBorder <> invalid AND not m.itemData.isBorder then m.border.Color = m.itemData.focusButtonColor
		if m.itemData.groupRecId = "bannerRightButtons" or m.itemData.groupRecId = "bannerbottomButtons" then m.border.Color = m.itemData.focusButtonColor
		if m.itemData.groupRecId = "bannerRightButtons"
			m.itemText.width = m.itemTextWidth + 8 - m.onFocusWidth
			m.itemText.translation = [6 + m.onFocusWidth/2,m.paddingH]
		end if
	else
		m.rightArrow.blendColor = m.itemData.buttonTextColor
		m.leftArrow.blendColor = m.itemData.buttonTextColor
		m.statusImage.blendColor = m.itemData.buttonTextColor
		m.itemBg.Color = m.itemData.buttonColor
		m.btnImg.blendColor = m.itemData.buttonColor
		m.filterImg.blendColor = m.itemData.buttonColor
		m.itemText.color = m.itemData.buttonTextColor
		m.statusText.color = m.itemData.buttonTextColor
		m.border.color = m.itemData.buttonTextColor
		if m.itemData.isBorder <> invalid AND not m.itemData.isBorder then m.border.Color = m.itemData.buttonColor
		if m.itemData.isunFocused <> invalid and m.itemData.isunFocused
			m.itemBg.Color = m.itemData.activeColor
			m.btnImg.blendColor = m.itemData.activeColor
			m.filterImg.blendColor = m.itemData.activeColor
			m.itemText.color = m.itemData.activeTextColor
			m.border.color = m.itemData.activeTextColor
			if m.itemData.isBorder <> invalid AND not m.itemData.isBorder then m.border.Color = m.itemData.activeColor
		end if
		m.border.width = m.top.width
		m.border.translation = [0, 0]
		m.itemBg.translation = [2, 2]
		if not m.havingAdditionaltext then m.itemText.font = "font:MediumSystemFont"
		if m.itemData.groupRecId = "vendorFilterList" or m.itemData.groupRecId = "vendorMenuList"
			m.itemText.font = "font:SmallSystemFont"
		end if
		m.filterImg.height = 26 + m.paddingH
		m.filterImg.width = 26 + m.paddingH
		m.filterImg.translation = [-3, 7 + m.paddingH/2]
		if m.itemData.groupRecId = "bannerRightButtons"
			m.itemBg.width = m.top.width - 4 - m.onFocusWidth
			m.border.width = m.top.width - m.onFocusWidth
			m.itemText.width = m.itemTextWidth + 8 - m.onFocusWidth 
			m.border.translation = [0 + m.onFocusWidth/2, 0]
			m.itemBg.translation = [2 + m.onFocusWidth/2, 2]
			m.itemText.translation = [6 + m.onFocusWidth/2,m.paddingH]
		end if
	end if
	if m.havingAdditionaltext
		m.itemText.font = "font:MediumBoldSystemFont"
		m.itemText.width = m.itemTextWidth
		m.itemText.translation = [10, m.paddingH]
		m.additionalText.width = m.itemText.width
		m.additionalText.translation = [m.itemText.translation[0], m.itemText.translation[1] + m.itemText.height + 10]
		m.additionalText.color = m.itemText.color
	end if
end function

function init() as void
	m.itemText = m.top.findNode("itemText")
	m.itemText.font.size = 20
	m.itemBg = m.top.findNode("seletedBg")
	m.statusText = m.top.findNode("statusText")
	m.statusText.font.size = 16
	m.statusImage = m.top.findNode("statusImage")
	m.rightArrow = m.top.findNode("rightArrow")
	m.leftArrow = m.top.findNode("leftArrow")
	m.border = m.top.findNode("border")
	m.statusRec = m.top.findNode("statusRec")
	m.btnImg = m.top.findNode("btnImg")
	m.filterImg = m.top.findNode("filterImg")
	m.additionalText = m.top.findNode("additionalText")
end function