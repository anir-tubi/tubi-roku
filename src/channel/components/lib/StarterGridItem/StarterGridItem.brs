Function init()
  m.poster = m.top.findNode("poster")

  m.top.observeFieldScoped("itemContent", "onItemContentChange")

  ' List of fields that will only be observed if we have a child grid item component with that field
  m.conditionallyObservedFields = [
    "itemHasFocus"
    "rowListHasFocus"
    "focusPercent"
    "width"
    "height"
  ]
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  gridItemType = itemContent.gridItemType

  childGridItemComponent = invalid
  if gridItemType = "emptyContainer" then
    childGridItemComponent = "CategoryGridPoster"
  else if gridItemType = "landscapeInnerMetadata" then
    childGridItemComponent = "CategoryGridPoster"
  else if gridItemType = "continue_watching_signed_out_user" then
    childGridItemComponent = "CategoryGridPoster"
  else if itemContent.type = "linear" then
    row = itemContent.getParent()
    if row <> invalid AND row.gridItemType = "landscapeNoTitle" OR row.gridItemType = "landscape" then
      childGridItemComponent = "CategoryGridPoster"
    end if
  end if

  if childGridItemComponent = invalid then
    ' If we're only using the starter component then we want to unobserve all of the conditionally observed fields
    if m.childGridItem <> invalid then
      removeConditionalFieldObservers()
      m.top.removeChild(m.childGridItem)
      m.delete("childGridItem")
    end if

    m.poster.uri = itemContent.HDGRIDPOSTERURL
    m.poster.visible = true
  else
    m.poster.visible = false
    if m.childGridItem = invalid then
      ' Create the child grid item component and setup observers to pass along data to it
      m.childGridItem = m.top.createChild(childGridItemComponent)
      removeConditionalFieldObservers()
      addConditionalFieldObservers(m.childGridItem)
    else if m.childGridItem.subtype() <> childGridItemComponent then
      ' If our childGridItemComponent doesn't match then we need to throw it out and build the new component
      m.top.removeChild(m.childGridItem)
      m.childGridItem = m.top.createChild(childGridItemComponent)
      removeConditionalFieldObservers()
      addConditionalFieldObservers(m.childGridItem)
    end if

    if m.childGridItem <> invalid then
      ' Go ahead and pass along the itemContent to the child
      m.childGridItem.itemContent = itemContent
    end if
  end if
End Function


Function addConditionalFieldObservers(childGridItem)
  if childGridItem <> invalid then
    for each field in m.conditionallyObservedFields
      ' We only observe the field if the child grid item has that field
      if childGridItem.hasField(field) = true then
        m.top.observeFieldScoped(field, "conditionallyObservedFieldCallback")

        ' Set the initial value for each field
        childGridItem[field] = m.top[field]
      end if
    end for
  end if
End Function


Function removeConditionalFieldObservers()
  for each field in m.conditionallyObservedFields
    m.top.unobserveFieldScoped(field)
  end for
End Function


' set as the function callback for each field in m.conditionallyObservedFields
Function conditionallyObservedFieldCallback(msg)
  childGridItem = m.childGridItem
  if childGridItem = invalid then
    tubiLog("m.childGridItem was invalid. Cannot pass along field to child", "warn")
  else
    childGridItem[msg.getField()] = msg.getData()
  end if
End Function
