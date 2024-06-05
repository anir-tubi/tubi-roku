function setColor(list, color) as object
    for each item in list
        item.color = color
    end for
end function

function setWidth(list, width) as object
    for each item in list
        item.width = width
    end for
end function

function getNode()
    node = {
        label: function(id = "label" as string, text = "" as string, font = "font:MediumSystemFont" as string, color = "0x000000" as dynamic, width = 0 as float) as dynamic
            label = CreateObject("roSGNode", "Label")
            label.id = id
            label.text = text
            label.font = font
            label.color = color
            label.width = width
            label.wrap = true
            return label
            end function,
        MultiStyleLabel: function(id = "MultiStyleLabel" as string, text = "" as string, width = 0 as float) as dynamic
            label = CreateObject("roSGNode", "MultiStyleLabel")
            label.id = id
            label.text = text
            label.width = width
            label.wrap = true
            return label
            end function,
        layoutGroup: function(id = "layoutGroup" as string, layoutDirection = "vert" as string, itemSpacings = [10] as dynamic,vertAlignment = "top" as string, horizAlignment = "left" as string)
            layoutGroup = CreateObject("roSGNode", "LayoutGroup")
            layoutGroup.id = id
            layoutGroup.layoutDirection = layoutDirection
            layoutGroup.vertAlignment = vertAlignment
            layoutGroup.horizAlignment = horizAlignment
            layoutGroup.itemSpacings = itemSpacings
            return layoutGroup
            end function,
        rectangle: function(id = "rectangle" as string, color = "0x000000" as dynamic, width = 0 as float, height = 0 as float)
            rectangle = CreateObject("roSGNode", "Rectangle")
            rectangle.id = id
            rectangle.color = color
            rectangle.width = width
            rectangle.height = height
            return rectangle
            end function
    }

    return node
end function