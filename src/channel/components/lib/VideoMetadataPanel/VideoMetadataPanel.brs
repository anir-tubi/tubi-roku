' Initializes the VideoMetadataPanel component
' Caches node references and sets up field observers for content changes
Function init()
  topRef = m.top
  m.nodeHelpers = TubiNodeHelpers()

  m.additionalInfoItemsContainer = topRef.findNode("additionalInfoItemsContainer")
  m.metadataGroup = topRef.findNode("metadataGroup")

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("currentEpisode", "onCurrentEpisodeChange")
  topRef.observeFieldScoped("layoutChanged", "onLayoutChanged")
End Function


' Handles changes to itemContent field
' Renders metadata panel with new content and aligns the layout
' @param msg - roSGNodeEvent containing the new item content
Function onItemContentChange(msg)
  itemContent = msg.getData()

  renderInfoPanel(itemContent)
End Function


' Handles changes to currentEpisode field
' Updates metadata panel with episode information and aligns the layout
' @param msg - roSGNodeEvent containing the current episode content
Function onCurrentEpisodeChange(msg)
  currentEpisode = msg.getData()
  if currentEpisode <> invalid
    renderInfoPanel(currentEpisode)
  end if
End Function


' Renders the info panel with metadata items (starring, directors)
' Clears existing items and creates new InfoItem nodes for available metadata
' @param itemContent - Content node containing actors and directors arrays
Function renderInfoPanel(itemContent)
  ' Individually deleting the actors and directors to handle a use case where in certain cases series level we have actors and not at episode.
  ' If we receive actors or directors at episode level, we need to delete the existing items and create new ones.
  if isNonEmptyArray(itemContent.actors)
    if m.starringItem <> invalid
      m.additionalInfoItemsContainer.removeChild(m.starringItem)
    end if
    m.starringItem = createInfoItem(getTranslation("metadata_starring"), itemContent.actors.join(", "))
    m.additionalInfoItemsContainer.appendChild(m.starringItem)
  end if

  if isNonEmptyArray(itemContent.directors)
    if m.directorItem <> invalid
      m.additionalInfoItemsContainer.removeChild(m.directorItem)
    end if
    m.directorItem = createInfoItem(getTranslation("metadata_directed"), itemContent.directors.join(", "))
    m.additionalInfoItemsContainer.appendChild(m.directorItem)
  end if

  alignMetadataGroup()
End Function


' Recalculates metadataGroup vertical alignment when child layout changes
Function onLayoutChanged(msg) as Void
  alignMetadataGroup()
End Function


' Aligns metadataGroup vertically so it fills at least minHeight
Function alignMetadataGroup() as Void
  height = m.metadataGroup.boundingRect().height
  minHeight = m.top.minHeight
  if height < minHeight
    m.metadataGroup.translation = [0, minHeight - height]
  else
    m.metadataGroup.translation = [0, 0]
  end if
End Function


' Creates an InfoItem node with label and value
' @param label - Label text for the info item
' @param value - Value text for the info item
' @return InfoItem node with label and value set
Function createInfoItem(label as String, value as String)
  infoItem = CreateObject("roSGNode", "InfoItem")
  infoItem.label = label
  infoItem.value = value
  return infoItem
End Function
