'**********************************************************
'**  Video Player Example Application - General Utilities
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

'******************************************************
'Registry Helper Functions
'******************************************************
Function RegRead(key, section = invalid)
  if section = invalid then section = "Default"
  sec = CreateObject("roRegistrySection", section)
  if sec.Exists(key) then return sec.Read(key)
  return invalid
End Function

Function RegReadAll(section = invalid)
  if section = invalid then section = "Default"
  sec = CreateObject("roRegistrySection", section)
  keys = sec.GetKeyList()
  allInfo = {}
  for each key in keys
    value = RegRead(key, section)
    allInfo[key] = value
  end for
  return allInfo
End Function

Function RegWrite(key, val, section = invalid)
  if section = invalid then section = "Default"
  sec = CreateObject("roRegistrySection", section)
  sec.Write(key, val)
  sec.Flush() ' commit it
End Function

Function RegDelete(key, section = invalid)
  if section = invalid then section = "Default"
  sec = CreateObject("roRegistrySection", section)
  sec.Delete(key)
  sec.Flush()
End Function


Function RegDeleteSection(section = invalid)
  if section = invalid then section = "Default"
  sec = CreateObject("roRegistrySection", section)
  keys = sec.GetKeyList()
  for each key in keys
    sec.Delete(key)
  end for
  sec.Flush()
End Function


'******************************************************
'Insertion Sort
'Will sort an array directly, or use a key function
'******************************************************
sub Sort(A as Object, key = invalid as Dynamic)

  if type(A) <> "roArray" then return

  if (key = invalid) then
    for i = 1 to A.Count() - 1
      value = A[i]
      j = i - 1
      while j >= 0 AND A[j] > value
        A[j + 1] = A[j]
        j = j - 1
      end while
      A[j + 1] = value
    next

  else
    if type(key) <> "Function" then return
    for i = 1 to A.Count() - 1
      valuekey = key(A[i])
      value = A[i]
      j = i - 1
      while j >= 0 AND key(A[j]) > valuekey
        A[j + 1] = A[j]
        j = j - 1
      end while
      A[j + 1] = value
    next

  end if

end sub


'******************************************************
'Convert anything to a string
'
'Always returns a string, trying to use native toStr() function
'******************************************************
Function tostr(any)
  ret = invalid
  if FindMemberFunction(any, "toStr") <> invalid then ret = any.toStr()
  if ret = invalid then ret = AnyToString(any)
  if ret = invalid then ret = type(any)
  if ret = invalid then ret = "unknown" 'failsafe
  return ret
End Function


'******************************************************
'Get a " char as a string
'******************************************************
Function Quote()
  q$ = Chr(34)
  return q$
End Function


'******************************************************
'isxmlelement
'
'Determine if the given object supports the ifXMLElement interface
'******************************************************
Function isxmlelement(obj as Dynamic) as Boolean
  if obj = invalid return false
  if GetInterface(obj, "ifXMLElement") = invalid return false
  return true
End Function


'******************************************************
'islist
'
'Determine if the given object supports the ifList interface
'******************************************************
Function islist(obj as Dynamic) as Boolean
  if obj = invalid return false
  if GetInterface(obj, "ifArray") = invalid return false
  return true
End Function


'******************************************************
'isint
'
'Determine if the given object supports the ifInt interface
'******************************************************
Function isint(obj as Dynamic) as Boolean
  if obj = invalid return false
  if GetInterface(obj, "ifInt") = invalid return false
  return true
End Function

'******************************************************
' validstr
'
' always return a valid string. if the argument is
' invalid or not a string, return an empty string
'******************************************************
Function validstr(obj as Dynamic) as String
  if isnonemptystr(obj) return obj
  return ""
End Function


'******************************************************
'isstr
'
'Determine if the given object supports the ifString interface
'******************************************************
Function isstr(obj as Dynamic) as Boolean
  if obj = invalid return false
  if GetInterface(obj, "ifString") = invalid return false
  return true
End Function


'******************************************************
'isnonemptystr
'
'Determine if the given object supports the ifString interface
'and returns a string of non zero length
'******************************************************
Function isnonemptystr(obj)
  if isnullorempty(obj) return false
  return true
End Function


'******************************************************
'isnullorempty
'
'Determine if the given object is invalid or supports
'the ifString interface and returns a string of non zero length
'******************************************************
Function isnullorempty(obj)
  if obj = invalid return true
  if not isstr(obj) return true
  if Len(obj) = 0 return true
  return false
End Function


'******************************************************
'isbool
'
'Determine if the given object supports the ifBoolean interface
'******************************************************
Function isbool(obj as Dynamic) as Boolean
  if obj = invalid return false
  if GetInterface(obj, "ifBoolean") = invalid return false
  return true
End Function


'******************************************************
'strtobool
'
'Convert string to boolean safely. Don't crash
'Looks for certain string values
'******************************************************
Function strtobool(obj as Dynamic) as Boolean
  if obj = invalid return false
  if type(obj) <> "roString" return false
  o = strTrim(obj)
  o = Lcase(o)
  if o = "true" return true
  if o = "t" return true
  if o = "y" return true
  if o = "1" return true
  return false
End Function


'******************************************************
'itostr
'
'Convert int to string. This is necessary because
'the builtin Stri(x) prepends whitespace
'******************************************************
Function itostr(i as Integer) as String
  str = Stri(i)
  return strTrim(str)
End Function


'******************************************************
'Get remaining hours from a total seconds
'******************************************************
Function hoursLeft(seconds as Integer) as Integer
  hours% = seconds / 3600
  return hours%
End Function


'******************************************************
'Get remaining minutes from a total seconds
'******************************************************
Function minutesLeft(seconds as Integer) as Integer
  hours% = seconds / 3600
  mins% = seconds - (hours% * 3600)
  mins% = mins% / 60
  return mins%
End Function


'******************************************************
'Pluralize simple strings like "1 minute" or "2 minutes"
'******************************************************
Function Pluralize(val as Integer, str as String) as String
  ret = itostr(val) + " " + str
  if val <> 1 ret = ret + "s"
  return ret
End Function


'******************************************************
'Trim a string
'******************************************************
Function strTrim(str as String) as String
  st = CreateObject("roString")
  st.SetString(str)
  return st.Trim()
End Function


'******************************************************
'Tokenize a string. Return roList of strings
'******************************************************
Function strTokenize(str as String, delim as String) as Object
  st = CreateObject("roString")
  st.SetString(str)
  return st.Tokenize(delim)
End Function


'******************************************************
'Replace substrings in a string. Return new string
'******************************************************
Function strReplace(basestr as String, oldsub as String, newsub as String) as String
  newstr = ""

  i = 1
  while i <= Len(basestr)
    x = Instr(i, basestr, oldsub)
    if x = 0 then
      newstr = newstr + Mid(basestr, i)
      exit while
    end if

    if x > i then
      newstr = newstr + Mid(basestr, i, x - i)
      i = x
    end if

    newstr = newstr + newsub
    i = i + Len(oldsub)
  end while

  return newstr
End Function


'******************************************************
'Get all XML subelements by name
'
'return list of 0 or more elements
'******************************************************
Function GetXMLElementsByName(xml as Object, name as String) as Object
  list = CreateObject("roArray", 100, true)
  if islist(xml.GetBody()) = false return list

  for each e in xml.GetBody()
    if e.GetName() = name then
      list.Push(e)
    end if
  next

  return list
End Function


'******************************************************
'Get all XML subelement's string bodies by name
'
'return list of 0 or more strings
'******************************************************
Function GetXMLElementBodiesByName(xml as Object, name as String) as Object
  list = CreateObject("roArray", 100, true)
  if islist(xml.GetBody()) = false return list

  for each e in xml.GetBody()
    if e.GetName() = name then
      b = e.GetBody()
      if type(b) = "roString" list.Push(b)
    end if
  next

  return list
End Function


'******************************************************
'Get first XML subelement by name
'
'return invalid if not found, else the element
'******************************************************
Function GetFirstXMLElementByName(xml as Object, name as String) as Dynamic
  if islist(xml.GetBody()) = false return invalid

  for each e in xml.GetBody()
    if e.GetName() = name return e
  next

  return invalid
End Function


'******************************************************
'Get first XML subelement's string body by name
'
'return invalid if not found, else the subelement's body string
'******************************************************
Function GetFirstXMLElementBodyStringByName(xml as Object, name as String) as Dynamic
  e = GetFirstXMLElementByName(xml, name)
  if e = invalid return invalid
  if type(e.GetBody()) <> "roString" return invalid
  return e.GetBody()
End Function


'******************************************************
'Get the xml element as an integer
'
'return invalid if body not a string, else the integer as converted by strtoi
'******************************************************
Function GetXMLBodyAsInteger(xml as Object) as Dynamic
  if type(xml.GetBody()) <> "roString" return invalid
  return strtoi(xml.GetBody())
End Function


'******************************************************
'Parse a string into a roXMLElement
'
'return invalid on error, else the xml object
'******************************************************
Function ParseXML(str as String) as Dynamic
  if str = invalid return invalid
  xml = CreateObject("roXMLElement")
  if not xml.Parse(str) return invalid
  return xml
End Function


'******************************************************
'Get XML sub elements whose bodies are strings into an associative array.
'subelements that are themselves parents are skipped
'namespace :'s are replaced with _'s
'
'So an XML element like...
'
'<blah>
'    <This>abcdefg</This>
'    <Sucks>xyz</Sucks>
'    <sub>
'        <sub2>
'        ....
'        </sub2>
'    </sub>
'    <ns:doh>homer</ns:doh>
'</blah>
'
'returns an AA with:
'
'aa.This = "abcdefg"
'aa.Sucks = "xyz"
'aa.ns_doh = "homer"
'
'return an empty AA if nothing found
'******************************************************
sub GetXMLintoAA(xml as Object, aa as Object)
  for each e in xml.GetBody()
    body = e.GetBody()
    if type(body) = "roString" then
      name = e.GetName()
      name = strReplace(name, ":", "_")
      aa.AddReplace(name, body)
    end if
  next
end sub


'******************************************************
'Walk an AA and print it
'******************************************************
sub PrintAA(aa as Object)
  print "---- AA ----"
  if aa = invalid
    print "invalid"
    return
  else
    cnt = 0
    for each e in aa
      PrintAny(0, e + ": ", aa[e])
      cnt = cnt + 1
    next
    if cnt = 0
      PrintAny(0, "Nothing from for each. Looks like :", aa)
    end if
  end if
  print "------------"
end sub


'******************************************************
'Walk a list and print it
'******************************************************
sub PrintList(list as Object)
  print "---- list ----"
  PrintAnyList(0, list)
  print "--------------"
end sub


'******************************************************
'Print an associativearray
'******************************************************
sub PrintAnyAA(depth as Integer, aa as Object)
  for each e in aa
    PrintAny(depth, e + ": ", aa[e])
  next
end sub


'******************************************************
'Print a list with indent depth
'******************************************************
sub PrintAnyList(depth as Integer, list as Object)
  i = 0
  for each e in list
    PrintAny(depth, "List(" + itostr(i) + ")= ", e)
    i = i + 1
  next
end sub


'******************************************************
'Print anything
'******************************************************
sub PrintAny(depth as Integer, prefix as String, any as Dynamic)
  if depth >= 10
    print "**** TOO DEEP " + itostr(5)
    return
  end if
  prefix = string(depth * 2, " ") + prefix
  depth = depth + 1
  str = AnyToString(any)
  if str <> invalid
    print prefix + str
    return
  end if
  if type(any) = "roAssociativeArray"
    print prefix + "(assocarr)..."
    PrintAnyAA(depth, any)
    return
  end if
  if islist(any) = true
    print prefix + "(list of " + itostr(any.Count()) + ")..."
    PrintAnyList(depth, any)
    return
  end if

  print prefix + "?" + type(any) + "?"
end sub


'******************************************************
'Print an object as a string for debugging. If it is
'very long print the first 500 chars.
'******************************************************
sub Dbg(pre as Dynamic, o = invalid as Dynamic)
  p = AnyToString(pre)
  if p = invalid p = ""
  if o = invalid o = ""
  s = AnyToString(o)
  if s = invalid s = "???: " + type(o)
  if Len(s) > 4000
    s = Left(s, 4000)
  end if
  print p + s
end sub


'******************************************************
'Try to convert anything to a string. Only works on simple items.
'
'Test with this script...
'
'    s$ = "yo1"
'    ss = "yo2"
'    i% = 111
'    ii = 222
'    f! = 333.333
'    ff = 444.444
'    d# = 555.555
'    dd = 555.555
'    bb = true
'
'    so = CreateObject("roString")
'    so.SetString("strobj")
'    io = CreateObject("roInt")
'    io.SetInt(666)
'    tm = CreateObject("roTimespan")
'
'    Dbg("", s$ ) 'call the Dbg() function which calls AnyToString()
'    Dbg("", ss )
'    Dbg("", "yo3")
'    Dbg("", i% )
'    Dbg("", ii )
'    Dbg("", 2222 )
'    Dbg("", f! )
'    Dbg("", ff )
'    Dbg("", 3333.3333 )
'    Dbg("", d# )
'    Dbg("", dd )
'    Dbg("", so )
'    Dbg("", io )
'    Dbg("", bb )
'    Dbg("", true )
'    Dbg("", tm )
'
'try to convert an object to a string. return invalid if can't
'******************************************************
Function AnyToString(any as Dynamic) as Dynamic
  if any = invalid return "invalid"
  if isstr(any) return any
  if isint(any) return itostr(any)
  if isbool(any)
    if any = true return "true"
    return "false"
  end if
  if isfloat(any) return any.toStr()
  if type(any) = "roTimespan" return itostr(any.TotalMilliseconds()) + "ms"
  return invalid
End Function



'******************************************************
'Same as AnyToString() but return empty string if any = invalid
'******************************************************
Function AnyToStringButNotInvalid(any as Dynamic) as Dynamic
  if any = invalid return ""
  return AnyToString(any)
End Function

'******************************************************
'Walk an XML tree and print it
'******************************************************
sub PrintXML(element as Object, depth as Integer)
  print tab(depth * 3);"Name: [" + element.GetName() + "]"
  if invalid <> element.GetAttributes() then
    print tab(depth * 3);"Attributes: ";
    for each a in element.GetAttributes()
      print a;"=";left(element.GetAttributes()[a], 4000);
      if element.GetAttributes().IsNext() then print ", ";
    next
    print
  end if

  if element.GetBody() = invalid then
    ' print tab(depth*3);"No Body"
  else if type(element.GetBody()) = "roString" then
    print tab(depth * 3);"Contains string: [" + left(element.GetBody(), 4000) + "]"
  else
    print tab(depth * 3);"Contains list:"
    for each e in element.GetBody()
      PrintXML(e, depth + 1)
    next
  end if
  print
end sub


'******************************************************
'Dump the bytes of a string
'******************************************************
sub DumpString(str as String)
  print "DUMP STRING"
  print "---------------------------"
  print str
  print "---------------------------"
  l = Len(str) - 1
  i = 0
  for i = 0 to l
    c = Mid(str, i)
    val = Asc(c)
    print itostr(val)
  next
  print "---------------------------"
end sub


'******************************************************
'Validate parameter is the correct type
'******************************************************
Function validateParam(param as Object, paramType as String, functionName as String, allowInvalid = false) as Boolean
  if type(param) = paramType then
    return true
  end if

  if allowInvalid = true then
    if type(param) = invalid then
      return true
    end if
  end if

  print "invalid parameter of type "; type(param); " for "; paramType; " in function "; functionName
  return false
End Function
