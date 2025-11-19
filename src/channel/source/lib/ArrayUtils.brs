' @array: [], an array[] for the element to be inserted
' @item: string, the item to be inserted to particular index
' @index : integer, which index the item to be inserted. And it is 0 based index.
'
' return array[]
Function insertItemIntoArray(array, item, index)

  newArray = []

  'if the index is greater than the count, then push the item at the end of the array.
  if index > array.Count() - 1
    newArray.append(array)
    newArray.push(item)
  else if index = 0
    newArray.push(item)
    newArray.append(array)
  else
    for i = 0 to array.Count() - 1

      if i = index
        newArray.push(item)
      end if

      newArray.push(array[i])
    end for

  end if

  return newArray

End Function

' Finds if the element is present in the array.
' Loops through the array and checks if the element is present in the array.
' @haystack: Object, the array to be searched in.
' @needle: Dynamic, the element to be searched for.
'
' return Boolean, true if the element is present in the array, false otherwise.
Function arrayIncludes(haystack as Object, needle as Dynamic) as Boolean
  for each thing in haystack
    if thing = needle
      return true
    end if
  end for
  return false
End Function
