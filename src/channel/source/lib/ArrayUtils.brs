' @array: [], an array[] for the element to be inserted
' @item: string, the item to be inserted to particular index
' @index : integer, which index the item to be inserted. And it is 0 based index.
'
' return array[]
Function insertItemIntoArray(array, item, index)

  newArray = []

  for i = 0 to array.Count()-1

    if i = index
      newArray.push(item)
    end if

    newArray.push(array[i])
  end for

  return newArray

End Function
