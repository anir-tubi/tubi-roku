' OneTrust SDK Header
sub init()
  try
    m.registry = RegistryUtil()
    m.style = style()
    m.headersection = m.top.findNode("headersection")
    m.headersection.translation = [0, m.style.containerPaddingTop]
    m.logo = m.top.findNode("logo")
    m.logo.height = m.style.logo.height
    m.logo.loadHeight = m.style.logo.height
    m.logo.width = m.style.logo.width
    m.logo.loadWidth = m.style.logo.width
    m.logo.observeField("loadStatus", "onDisplayLogo")
    m.headerText = m.top.findNode("headerText")
    m.closetextList = m.top.findNode("closetextList")
    m.closetextList.observeField("itemSelected", "onItemSelected")
    m.closeBtnVoiceOverText = m.top.findNode("closeBtnVoiceOverText")
    m.constant = applicationConstants()
    m.WCAGRoles = CreateObject("roSGNode", "OTWCAGInterface")
    m.closetextList.observeField("itemFocused", "onItemFocused")
    m.backButton = m.top.findNode("backButton")
    m.textToSpeech = CreateObject("roTextToSpeech")
    m.roAudioGuide = CreateObject("roAudioGuide")
    m.width = 0
    m.headeritemSpacings = [0, 0, 0, 0]
    m.buttonAdjustment = 0
  catch e
    ? "ERROR in OTHeader init(): "; e.message
  end try

end sub

sub onItemFocused(data as Object)
  try
    data = data.getRoSGNode()
    if isValid(data)
      itemFocused = data.itemFocused
      if isValid(itemFocused) AND isValid(data.content)
        item = data.content.getChild(itemFocused)
        if isValid(item)
          text = item.text
          if m.closeBtnVoiceOverText.visible then text = m.closeBtnVoiceOverText.text
          say(text, m.WCAGRoles.button, m.WCAGRoles.selectedAriaLabel, true)
        end if
      end if
    end if
  catch e
    ? "ERROR in onItemFocused(): "; e.message
  end try

end sub

sub onContentChange()
  try
    data = m.top.data
    if isValid(data)
      m.OTinitialize = m.top.OTinitialize
      if isValid(m.global.OT_Data) AND isValid(m.global.OT_Data["WCAGRoles"]) then m.WCAGRoles = m.global.OT_Data["WCAGRoles"]
      m.width = data.Hwidth
      m.headeritemSpacings = [0, 0, 0, 0]
      setBackButton(data)
      setLogo(data)
      setCloseButton(data)
      setHeaderText(data)
      m.headersection.itemSpacings = m.headeritemSpacings
      setlayout()
    end if
  catch e
    ? "ERROR in onContentChange(): "; e.message
  end try
end sub

Function setHeaderText(data)
  try
    m.headerText.width = getHeaderTextwidth()
    if isValid(data) AND isValid(data.pageHeaderTitle)
      Headertext = data.pageHeaderTitle.text
      if isValid(data.menuListNode) AND isValid(m.top.viewType) AND m.top.viewType <> "sdkList"
        if isValid(data.menuListNode.iabBtnNode) AND isString(data.menuListNode.iabBtnNode.id) AND m.top.viewType = data.menuListNode.iabBtnNode.id
          Headertext += " - " + data.menuListNode.iabBtnNode.text
        end if
        if isValid(data.menuListNode.googleBtnNode) AND isValid(data.menuListNode.googleBtnNode.id) AND m.top.viewType = data.menuListNode.googleBtnNode.id
          Headertext += " - " + data.menuListNode.googleBtnNode.text
        end if
      end if
      m.headeritemSpacings[2] = m.style.OTHeader.padding
      m.headerText.width = getHeaderTextwidth()
      m.headerText.visible = true
      m.headerText.font = data.fonts.title
      m.headerText.text = Headertext
      'if m.headerText.boundingRect().height < m.style.logo.height then m.headerText.height = m.style.logo.height
      m.headerText.color = data.pageHeaderTitle.textColor
    end if
  catch e
    ? "ERROR in setHeaderText(): "; e.message
  end try

End Function

sub setlayout()
  try
    m.top.height = m.headersection.boundingRect().height + m.style.headerBottomPadding - m.buttonAdjustment
  catch e
    ? "ERROR in setlayout(): "; e.message
  end try

end sub

sub setLogo(data)
  try
    m.logo.visible = false
    if isValid(data) AND isString(data.logo)
      m.logo.visible = true
      m.headeritemSpacings[1] = m.style.OTHeader.padding
      if isString(data.logoVoiceOverText) then m.logo["audioGuideText"] = data.logoVoiceOverText
      m.logo.uri = data.logo
    else
      m.logo.height = 0
      m.logo.loadHeight = 0
      m.logo.width = 0
      m.logo.loadWidth = 0
    end if
  catch e
    ? "ERROR in setLogo(): "; e.message
  end try

end sub

Function onDisplayLogo()
  try
    if(m.logo.loadStatus = "ready" AND isString(m.logo.uri))
      width = (m.logo.bitmapWidth / m.logo.bitmapHeight) * m.logo.height
      height = (m.logo.bitmapHeight / m.logo.bitmapWidth) * m.logo.width
      if width < m.style.logo.width
        m.logo.loadWidth = width
        m.logo.width = width
      end if
      if height < m.style.logo.height
        m.logo.loadHeight = height
        m.logo.height = height
      end if
      '  m.logo.loadWidth = (m.logo.bitmapWidth / m.logo.bitmapHeight) * m.logo.height
      '  m.logo.width = m.logo.loadWidth
      m.headerText.width = getHeaderTextwidth()
    end if
  catch e
    ? "ERROR in onDisplayLogo(): "; e.message
  end try
End Function

sub setCloseButton(data)
  try
    m.closetextList.itemSize = [0, 0]
    m.closeBtnVoiceOverText.width = 0
    if isValid(data) AND isValid(data.closeButton)
      m.closetextList.visible = true
      m.buttonAdjustment = 2 * m.style.gridButtonAdjustment
      content = getCloseContentNode(data)
      if isValid(content) AND content.isclose AND isString(data.closeBtnVoiceOverText)
        m.buttonAdjustment -= m.style.gridButtonAdjustment
        m.closeBtnVoiceOverText.visible = true
        label = getNode().label("temp", data.closeBtnVoiceOverText, data.fonts.description)
        m.closeBtnVoiceOverText.width = label.boundingRect().width
        m.closeBtnVoiceOverText.font = data.fonts.description
        'if m.closeBtnVoiceOverText.boundingRect().height < m.style.logo.height then m.closeBtnVoiceOverText.height = m.style.logo.height
        m.closeBtnVoiceOverText.color = data.closeButton.textColor
        m.closeBtnVoiceOverText.text = data.closeBtnVoiceOverText
        'm.closeBtnVoiceOverText.translation = [20, 0]
      end if
      itemSize = [content.width, content.height]
      if content.isclose then itemSize = [m.style.backbutton.size, m.style.backbutton.size]
      m.closetextList.itemSize = itemSize
      'm.closetextList.translation = [0, 0]
      m.closetextList.content = content.contentNode
    end if
  catch e
    ? "ERROR in setCloseButton(): "; e.message
  end try
end sub

sub setBackButton(data)
  try
    m.backButton.width = 0
    m.backButton.visible = false
    m.backButton.scale = [0, 0]
    if isValid(data) AND isValid(data.backButton) AND m.top.isMainback
      m.headeritemSpacings[0] = m.style.OTHeader.padding
      m.backButton.visible = true
      m.backButton.scale = [1, 1]
      contentNode = CreateObject("roSGNode", "ContentNode")
      contentNode.appendChild(data.backButton)
      m.backButton.width = m.style.backbutton.size
      m.backButton.height = m.style.backbutton.size
      m.backButton.content = contentNode
    end if
  catch e
    ? "ERROR in setBackButton(): "; e.message
  end try

end sub

sub onItemSelected(data as Object)
  try
    data = data.getRoSGNode()
    if isValid(data) then itemSelectedHandler(data)
  catch e
    ? "ERROR in onItemSelected(): "; e.message
  end try
end sub

Function getHeaderTextwidth()
  width = 0
  try
    if isValid(m.width) then width = m.width - m.closetextList.itemSize[0] - m.backButton.width - m.logo.width - m.headeritemSpacings[0] - m.headeritemSpacings[1] - m.headeritemSpacings[2] - m.headeritemSpacings[3] - m.closeBtnVoiceOverText.width - m.style.gridButtonAdjustment
  catch e
    ? "ERROR in getHeaderTextwidth(): "; e.message
  end try
  return width
End Function

sub onViewTypeChange()
  try
    if isValid(m.top.data) then setHeaderText(m.top.data)
  catch e
    ? "ERROR in onViewTypeChange(): "; e.message
  end try
end sub