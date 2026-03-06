' Appends the given number of low-order bits of the given value
' to the given buffer. Requires 0 <= len <= 31 and 0 <= val < 2^len.
Function appendBits(value as Integer, length as Integer, bb as Object)
  if ((length < 0) OR (length > 31) OR (value >> length <> 0)) then
    throw("Value out of range")
  end if
  for i = length - 1 to 0 step -1 ' Append bit by bit
    bb.push((value >> i) AND 1)
  next
End Function


' Returns true iff the i'th bit of x is set to 1.
Function getBit(x as Integer, i as Integer) as Boolean
  return ((x >> i) AND 1) <> 0
End Function


' Throws an exception if the given condition is false.
Function assert(condition as Boolean)
  if (not condition) then
    throw("Assertion error")
  end if
End Function


'Since Brightscript doesn't have a XOR operator, we use this function to calculate it.
Function xor(x, y)
  if type(x) = "roInvalid" then x = 0
  if type(y) = "roInvalid" then y = 0
  return (x OR y) - (x AND y)
End Function


Function iif(check as Boolean, yes as Dynamic, no as Dynamic) as Dynamic
  if check then
    return yes
  end if
  return no
End Function

Function floor(f as Float) as Integer
  return int(f)
End Function

Function ceil(f as Float) as Integer
  return int(f + 0.999)
End Function

Function min(a, b)
  if a < b then return a
  return b
End Function

Function max(a, b)
  if a > b then return a
  return b
End Function

Function slice(array as Object, start = 0 as Integer, finish = 0 as Integer) as Object
  size = array.count() - 1
  if (start < 0) then
    start += size
  end if
  if (finish = 0 OR finish >= size) then
    finish = size + 1
  else if (finish < 0) then
    finish += size
  end if
  new = []
  for x = start to finish - 1
    new.push(array[x])
  next
  return new
End Function

Function concat(array1 as Object, array2 as Object) as Object
  new = []
  new.append(array1)
  new.append(array2)
  return new
End Function

Function splice(array as Object, start as Integer, delete = 999999 as Integer, insert = [] as Object)
  if start > array.count() - 1 then start = array.count() - 1
  if start < 0 then start = array.count() - start
  if start < 0 then start = 0
  if delete < 0 then delete = 0
  for d = 1 to delete
    array.delete(start)
  next
  tmp = []
  tmp.append(insert)
  while(array.count() - 1 > start)
    tmp.push(array[start])
    array.delete(start)
  end while
  array.append(tmp)
  return array
End Function

Function infinity()
  return 999999
End Function

Function joinNums(array as Object, sep = ", " as String) as String
  ret = ""
  for each item in array
    if ret <> "" then
      ret += sep
    end if
    if type(item) = "Invalid" then
      ret += "invalid"
    else
      ret += item.toStr()
    end if
  next
  return ret
End Function

Function isNullOrEmpty(obj as Object) as Boolean
  if type(obj) = "Invalid" OR type(obj) = "roInvalid" then
    return true
  else if obj = "" then
    return true
  end if
  return false
End Function