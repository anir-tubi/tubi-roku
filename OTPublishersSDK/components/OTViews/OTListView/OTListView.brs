' OneTrust SDK listView
sub init()
  try
    m.listViewContainer = m.top.findNode("listViewContainer")
    m.listViewSection = m.top.findNode("listViewSection")
    m.OTListGridview = m.top.findNode("OTListGridview")
    m.OTListGridview.observeField("itemFocused", "onItemSelected")
    m.searchNoResultsFoundText = m.top.findNode("searchNoResultsFoundText")
    'm.OTListGridview.observeField("itemSelected", "onItemSelected")
    m.lastScrollIndex = 1
    m.itemFocused = 0
    m.style = style()
  catch e
    ? "ERROR in OTListView init: "; e.message
  end try
end sub

sub onItemSelected(data as Object)
  try
    data = data.getRoSGNode()
    if isValid(data)
      itemFocused = data.itemFocused
      if isValid(itemFocused) AND isValid(data.content)
        m.top.itemFocusedPosition = itemFocused
        item = data.content.getChild(itemFocused)
        if isValid(item) then m.top.itemFocused = item
      end if
    end if
  catch e
    ? "ERROR in onItemSelected: "; e.message
  end try

end sub

sub onContentChange()
  try
    data = m.top.data
    m.OTListGridview.visible = false
    m.searchNoResultsFoundText.visible = false
    m.searchNoResultsFoundText.scale = [0, 0]
    if isValid(data) AND data.keys().count() > 0
      m.listViewSection.width = data.width
      m.listViewSection.translation = [0, 0]
      m.listViewSection.height = data.height
      m.listViewSection.color = data.backgroundColor

      if isValid(data.listContentNode) AND data.listContentNode.getChildCount() > 0
        m.OTListGridview.visible = true
        m.OTListGridview.height = m.listViewSection.height
        m.OTListGridview.width = m.listViewSection.width
        m.OTListGridview.isScrollable = true
        m.OTListGridview.content = data.listContentNode
        m.OTListGridview.clippingRect = [0, 0, m.OTListGridview.width, m.OTListGridview.height]
      else
        m.searchNoResultsFoundText.translation = [0, m.style.buttonspacing]
        m.searchNoResultsFoundText.font = data.fonts.description
        m.searchNoResultsFoundText.color = data.textColor
        m.searchNoResultsFoundText.width = data.width
        m.searchNoResultsFoundText.horizAlign = "center"
        m.searchNoResultsFoundText.visible = true
        m.searchNoResultsFoundText.scale = [1, 1]
        m.searchNoResultsFoundText.text = data.searchNoResultsFoundText
      end if
    end if
  catch e
    ? "ERROR in onItemSelected: "; e.message
  end try
end sub
