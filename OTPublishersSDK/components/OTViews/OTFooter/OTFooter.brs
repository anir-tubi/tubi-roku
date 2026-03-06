' OneTrust SDK Footer
sub init()
  try
    m.registry = RegistryUtil()
    m.actionRect = m.top.findNode("actionRect")
    m.buttonList = m.top.findNode("buttonList")
    m.buttonList.observeField("itemSelected", "onItemSelected")
    m.style = style()
    m.constant = applicationConstants()
    m.errortype = getErrorType()
    m.errorTags = getErrorTags()
    m.logger = logUtil()
    m.WCAGRoles = CreateObject("roSGNode", "OTWCAGInterface")
    m.buttonList.observeField("itemFocused", "onItemFocused")
    m.textToSpeech = CreateObject("roTextToSpeech")
    m.roAudioGuide = CreateObject("roAudioGuide")
  catch e
    ? "ERROR in OTFooter init(): "; e.message
  end try
end sub

sub onItemFocused(data as Object)
  try
    data = data.getRoSGNode()
    if isValid(data)
      itemFocused = data.itemFocused
      if isValid(itemFocused)
        item = data.content.getChild(itemFocused)
        if isValid(m.WCAGRoles) AND isValid(item)
          say(item.text, m.WCAGRoles.button, m.WCAGRoles.selectedAriaLabel, true)
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
      if data.layout = "right" then data.width = data.width - m.style.containerPaddingTop
      m.actionRect.color = data.backgroundColor
      m.actionRect.width = data.width
      setButtonList(data)
      m.top.height = m.actionRect.boundingRect().height
      m.top.translation = [0, data.height - m.top.height + m.style.footerTopPadding]
    end if
  catch e
    ? "ERROR in onContentChange(): "; e.message
  end try
end sub

sub setButtonList(data)
  try
    content = getFooterContentNode(data)
    if isValid(content)
      itemSpacing = [m.style.buttonspacing, m.style.buttonspacing / 2]
      if data.layout = "right"
        grid = [5, 1]
        rowHeights = content.rowHeights
        translation = [m.style.containerPaddingTop, 0]
      else
        grid = [1, 4]
        rowHeights = []
        translation = [0, 0]
      end if
      m.buttonList.numRows = grid[0]
      m.buttonList.numColumns = grid[1]
      m.buttonList.translation = [0, 0]
      m.buttonList.itemSpacing = itemSpacing
      m.buttonList.rowSpacings = content.rowSpacings
      m.buttonList.itemSize = [content.width, content.height]
      m.buttonList.rowHeights = rowHeights
      m.buttonList.content = content.contentNode
      m.actionRect.translation = translation
    end if
  catch e
    ? "ERROR in setButtonList(): "; e.message
  end try

end sub

sub onItemSelected(data as Object)
  try
    data = data.getRoSGNode()
    if isValid(data) AND isValid(m.OTinitialize) then itemSelectedHandler(data, m.OTinitialize)
  catch e
    ? "ERROR in onItemSelected(): "; e.message
  end try

end sub

sub onViewTypeChange()
  try
    if isValid(m.top.data) then setButtonList(m.top.data)
  catch e
    ? "ERROR in onItemSelected(): "; e.message
  end try
end sub