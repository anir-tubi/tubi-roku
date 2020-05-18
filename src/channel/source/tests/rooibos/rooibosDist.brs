'/**
' * rooibos - simple, flexible, fun brightscript test framework for roku scenegraph apps
' * @version v3.4.3
' * @link https://github.com/georgejecook/rooibos#readme
' * @license MIT
' */
 function RBS_BTS_BaseTestSuite_AddTest(name, func, funcName, setup = invalid, teardown = invalid)
  m.testCases.Push(m.createTest(name, func, setup, teardown))
end function
 function RBS_BTS_BaseTestSuite_CreateTest(name, func, funcName, setup = invalid, teardown = invalid) as object
  if (func = invalid)
    ? " ASKED TO CREATE TEST WITH INVALID FUNCITON POINTER FOR FUNCTION " ; funcName
  end if
  return {
    Name: name
    Func: func
    FuncName: funcName
    SetUp: setup
    TearDown: teardown
  }
end function
 function RBS_BTS_BaseTestSuite_Fail(msg = "Error") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  m.currentResult.AddResult(msg)
  return m.GetLegacyCompatibleReturnValue(false)
end function
 function RBS_BTS_BaseTestSuite_GetLegacyCompatibleReturnValue(value) as object
  if (value = true)
    if (m.isLegacy = true)
      return ""
    else
      return true
    end if
  else
    if (m.isLegacy = true)
      return "ERROR"
    else
      return false
    end if
  end if
end function
 function RBS_BTS_BaseTestSuite_AssertFalse(expr , msg = "Expression evaluates to true") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if not  rbs_cmn_IsBoolean(expr) or expr
    m.currentResult.AddResult(msg)
    return m.fail(msg)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertTrue(expr , msg = "Expression evaluates to false") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if not  rbs_cmn_IsBoolean(expr) or not expr then
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertEqual(first , second , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if not m.eqValues(first, second)
    if msg = ""
      first_as_string =  rbs_cmn_AsString(first)
      second_as_string =  rbs_cmn_AsString(second)
      msg = first_as_string + " != " + second_as_string
    end if
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertLike(first , second , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if first <> second
    if msg = ""
      first_as_string =  rbs_cmn_AsString(first)
      second_as_string =  rbs_cmn_AsString(second)
      msg = first_as_string + " != " + second_as_string
    end if
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertNotEqual(first , second , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if m.eqValues(first, second)
    if msg = ""
      first_as_string =  rbs_cmn_AsString(first)
      second_as_string =  rbs_cmn_AsString(second)
      msg = first_as_string + " == " + second_as_string
    end if
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertInvalid(value , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if value <> invalid
    if msg = ""
      expr_as_string =  rbs_cmn_AsString(value)
      msg = expr_as_string + " <> Invalid"
    end if
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertNotInvalid(value , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if value = invalid
    if msg = ""
      expr_as_string =  rbs_cmn_AsString(value)
      msg = expr_as_string + " = Invalid"
    end if
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertAAHasKey(array , key , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if  rbs_cmn_IsAssociativeArray(array)
    if not array.DoesExist(key)
      if msg = ""
        msg = "Array doesn't have the '" + key + "' key."
      end if
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "Input value is not an Associative Array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertAANotHasKey(array , key , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if  rbs_cmn_IsAssociativeArray(array)
    if array.DoesExist(key)
      if msg = ""
        msg = "Array has the '" + key + "' key."
      end if
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "Input value is not an Associative Array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertAAHasKeys(array , keys , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if  rbs_cmn_IsAssociativeArray(array) and  rbs_cmn_IsArray(keys)
    for each key in keys
      if not array.DoesExist(key)
        if msg = ""
          msg = "Array doesn't have the '" + key + "' key."
        end if
        m.currentResult.AddResult(msg)
        return m.GetLegacyCompatibleReturnValue(false)
      end if
    end for
  else
    msg = "Input value is not an Associative Array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertAANotHasKeys(array , keys , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if  rbs_cmn_IsAssociativeArray(array) and  rbs_cmn_IsArray(keys)
    for each key in keys
      if array.DoesExist(key)
        if msg = ""
          msg = "Array has the '" + key + "' key."
        end if
        m.currentResult.AddResult(msg)
        return m.GetLegacyCompatibleReturnValue(false)
      end if
    end for
  else
    msg = "Input value is not an Associative Array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertArrayContains(array , value , key = invalid , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if  rbs_cmn_IsAssociativeArray(array) or  rbs_cmn_IsArray(array)
    if not  rbs_cmn_ArrayContains(array, value, key)
      msg = "Array doesn't have the '" +  rbs_cmn_AsString(value) + "' value."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "Input value is not an Array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertArrayContainsAAs(array , values , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if not  rbs_cmn_IsArray(values)
    msg = "values to search for are not an Array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  if  rbs_cmn_IsArray(array)
    for each value in values
      isMatched = false
      if not  rbs_cmn_IsAssociativeArray(value)
        msg = "Value to search for was not associativeArray " +  rbs_cmn_AsString(value)
        m.currentResult.AddResult(msg)
        return m.GetLegacyCompatibleReturnValue(false)
      end if
      for each item in array
        if (RBS_CMN_IsAssociativeArray(item))
          isValueMatched = true
          for each key in value
            fieldValue = value[key]
            itemValue = item[key]
            if (not m.EqValues(fieldValue, itemValue))
              isValueMatched = false
              exit for
            end if
          end for
          if (isValueMatched)
            isMatched = true
            exit for
          end if
        end if
      end for ' items in array
      if not isMatched
        msg = "array missing value: " +  rbs_cmn_AsString(value)
        m.currentResult.AddResult(msg)
        return m.GetLegacyCompatibleReturnValue(false)
      end if
    end for 'values to match
  else
    msg = "Input value is not an Array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertArrayNotContains(array , value , key = invalid , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if  rbs_cmn_IsAssociativeArray(array) or  rbs_cmn_IsArray(array)
    if  rbs_cmn_ArrayContains(array, value, key)
      msg = "Array has the '" +  rbs_cmn_AsString(value) + "' value."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "Input value is not an Array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertArrayContainsSubset(array , subset , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if (rbs_cmn_IsAssociativeArray(array) and  rbs_cmn_IsAssociativeArray(subset)) or (rbs_cmn_IsArray(array) and  rbs_cmn_IsArray(subset))
    isAA =  rbs_cmn_IsAssociativeArray(subset)
    for each item in subset
      key = invalid
      value = item
      if isAA
        key = item
        value = subset[key]
      end if
      if not  rbs_cmn_ArrayContains(array, value, key)
        msg = "Array doesn't have the '" +  rbs_cmn_AsString(value) + "' value."
        m.currentResult.AddResult(msg)
        return m.GetLegacyCompatibleReturnValue(false)
      end if
    end for
  else
    msg = "Input value is not an Array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertArrayNotContainsSubset(array , subset , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if (rbs_cmn_IsAssociativeArray(array) and  rbs_cmn_IsAssociativeArray(subset)) or (rbs_cmn_IsArray(array) and  rbs_cmn_IsArray(subset))
    isAA =  rbs_cmn_IsAssociativeArray(subset)
    for each item in subset
      key = invalid
      value = item
      if isAA
        key = item
        value = item[key]
      end if
      if  rbs_cmn_ArrayContains(array, value, key)
        msg = "Array has the '" +  rbs_cmn_AsString(value) + "' value."
        m.currentResult.AddResult(msg)
        return m.GetLegacyCompatibleReturnValue(false)
      end if
    end for
  else
    msg = "Input value is not an Array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertArrayCount(array , count , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if  rbs_cmn_IsAssociativeArray(array) or  rbs_cmn_IsArray(array)
    if array.Count() <> count
      msg = "Array items count " +  rbs_cmn_AsString(array.Count()) + " <> " +  rbs_cmn_AsString(count) + "."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "Input value is not an Array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertArrayNotCount(array , count , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if  rbs_cmn_IsAssociativeArray(array) or  rbs_cmn_IsArray(array)
    if array.Count() = count
      msg = "Array items count = " +  rbs_cmn_AsString(count) + "."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "Input value is not an Array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertEmpty(item , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if  rbs_cmn_IsAssociativeArray(item) or  rbs_cmn_IsArray(item)
    if item.Count() > 0
      msg = "Array is not empty."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else if (rbs_cmn_IsString(item))
    if (rbs_cmn_AsString(item) <> "")
      msg = "Input value is not empty."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "AssertEmpty: Input value was not an array or a string"
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertNotEmpty(item , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if  rbs_cmn_IsAssociativeArray(item) or  rbs_cmn_IsArray(item)
    if item.Count() = 0
      msg = "Array is empty."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else if  rbs_cmn_IsString(item)
    if (item = "")
      msg = "Input value is empty."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "Input value is not a string or array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertArrayContainsOnlyValuesOfType(array , typeStr , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if typeStr <> "String" and typeStr <> "Integer" and typeStr <> "Boolean" and typeStr <> "Array" and typeStr <> "AssociativeArray"
    msg = "Type must be Boolean, String, Array, Integer, or AssociativeArray"
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  if  rbs_cmn_IsAssociativeArray(array) or  rbs_cmn_IsArray(array)
    methodName = "RBS_CMN_Is" + typeStr
    typeCheckFunction = m.GetIsTypeFunction(methodName)
    if (typeCheckFunction <> invalid)
      for each item in array
        if not typeCheckFunction(item)
          msg =  rbs_cmn_AsString(item) + "is not a '" + typeStr + "' type."
          m.currentResult.AddResult(msg)
          return m.GetLegacyCompatibleReturnValue(false)
        end if
      end for
    else
      msg = "could not find comparator for type '" + typeStr + "' type."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "Input value is not an Array."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_GetIsTypeFunction(name)
  if name = "RBS_CMN_IsFunction"
    return  rbs_cmn_IsFunction
  else if name = "RBS_CMN_IsXmlElement"
    return  rbs_cmn_IsXmlElement
  else if name = "RBS_CMN_IsInteger"
    return  rbs_cmn_IsInteger
  else if name = "RBS_CMN_IsBoolean"
    return  rbs_cmn_IsBoolean
  else if name = "RBS_CMN_IsFloat"
    return  rbs_cmn_IsFloat
  else if name = "RBS_CMN_IsDouble"
    return  rbs_cmn_IsDouble
  else if name = "RBS_CMN_IsLongInteger"
    return  rbs_cmn_IsLongInteger
  else if name = "RBS_CMN_IsNumber"
    return  rbs_cmn_IsNumber
  else if name = "RBS_CMN_IsList"
    return  rbs_cmn_IsList
  else if name = "RBS_CMN_IsArray"
    return  rbs_cmn_IsArray
  else if name = "RBS_CMN_IsAssociativeArray"
    return  rbs_cmn_IsAssociativeArray
  else if name = "RBS_CMN_IsSGNode"
    return  rbs_cmn_IsSGNode
  else if name = "RBS_CMN_IsString"
    return  rbs_cmn_IsString
  else if name = "RBS_CMN_IsDateTime"
    return  rbs_cmn_IsDateTime
  else if name = "RBS_CMN_IsUndefined"
    return  rbs_cmn_IsUndefined
  else
    return invalid
  end if
end function
 function RBS_BTS_BaseTestSuite_AssertType(value , typeStr , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if type(value) <> typeStr
    if msg = ""
      expr_as_string =  rbs_cmn_AsString(value)
      msg = expr_as_string + " was not expected type " + typeStr
    end if
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertSubType(value , typeStr , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if type(value) <> "roSGNode"
    if msg = ""
      expr_as_string =  rbs_cmn_AsString(value)
      msg = expr_as_string + " was not a node, so could not match subtype " + typeStr
    end if
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  else if (value.subType() <> typeStr)
    if msg = ""
      expr_as_string =  rbs_cmn_AsString(value)
      msg = expr_as_string + "( type : " + value.subType() + ") was not of subType " + typeStr
    end if
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_EqValues(Value1 , Value2) as dynamic
  val1Type = type(Value1)
  val2Type = type(Value2)
  if val1Type = "<uninitialized>" or val2Type = "<uninitialized>" or val1Type = "" or val2Type = ""
    ? "ERROR!!!! - undefined value passed"
    return false
  end if
  if val1Type = "roString" or val1Type = "String"
    Value1 =  rbs_cmn_AsString(Value1)
  else
    Value1 = box(Value1)
  end if
  if val2Type = "roString" or val2Type = "String"
    Value2 =  rbs_cmn_AsString(Value2)
  else
    Value2 = box(Value2)
  end if
  val1Type = type(Value1)
  val2Type = type(Value2)
  if val1Type = "roFloat" and val2Type = "roInt"
    Value2 = box(Cdbl(Value2))
  else if val2Type = "roFloat" and val1Type = "roInt"
    Value1 = box(Cdbl(Value1))
  end if
  if val1Type <> val2Type
    return false
  else
    valtype = val1Type
    if valtype = "roList"
      return  rbs_bts_basetestsuite_EqArray(Value1, Value2)
    else if valtype = "roAssociativeArray"
      return  rbs_bts_basetestsuite_EqAssocArray(Value1, Value2)
    else if valtype = "roArray"
      return  rbs_bts_basetestsuite_EqArray(Value1, Value2)
    else if (valtype = "roSGNode")
      if (val2Type <> "roSGNode")
        return false
      else
        return Value1.isSameNode(Value2)
      end if
    else
      return Value1 = Value2
    end if
  end if
end function
 function RBS_BTS_BaseTestSuite_EqAssocArray(Value1 , Value2) as dynamic
  l1 = Value1.Count()
  l2 = Value2.Count()
  if not l1 = l2
    return false
  else
    for each k in Value1
      if k <> "__mocks" and k <> "__stubs" 'fix infinite loop/box crash when doing equals on an aa with a mock
        if not Value2.DoesExist(k)
          return false
        else
          v1 = Value1[k]
          v2 = Value2[k]
          if not  rbs_bts_basetestsuite_EqValues(v1, v2)
            return false
          end if
        end if
      end if
    end for
    return true
  end if
end function
 function RBS_BTS_BaseTestSuite_EqArray(Value1 , Value2) as dynamic
  if not (rbs_cmn_IsArray(Value1)) or not  rbs_cmn_IsArray(Value2) then return false
  l1 = Value1.Count()
  l2 = Value2.Count()
  if not l1 = l2
    return false
  else
    for i = 0 to l1 - 1
      v1 = Value1[i]
      v2 = Value2[i]
      if not  rbs_bts_basetestsuite_EqValues(v1, v2) then
        return false
      end if
    end for
    return true
  end if
end function
 function RBS_BTS_BaseTestSuite_AssertNodeCount(node , count , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if type(node) = "roSGNode"
    if node.getChildCount() <> count
      msg = "node items count <> " +  rbs_cmn_AsString(count) + ". Received " +  rbs_cmn_AsString(node.getChildCount())
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "Input value is not an node."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertNodeNotCount(node , count , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if type(node) = "roSGNode"
    if node.getChildCount() = count
      msg = "node items count = " +  rbs_cmn_AsString(count) + "."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "Input value is not an node."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertNodeEmpty(node , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if type(node) = "roSGNode"
    if node.getChildCount() > 0
      msg = "node is not empty."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertNodeNotEmpty(node , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if type(node) = "roSGNode"
    if node.Count() = 0
      msg = "Array is empty."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertNodeContains(node , value , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if type(node) = "roSGNode"
    if not  rbs_cmn_NodeContains(node, value)
      msg = "Node doesn't have the '" +  rbs_cmn_AsString(value) + "' value."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "Input value is not an Node."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertNodeContainsOnly(node , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if type(node) = "roSGNode"
    if not  rbs_cmn_NodeContains(node, value)
      msg = "Node doesn't have the '" +  rbs_cmn_AsString(value) + "' value."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    else if node.getChildCount() <> 1
      msg = "Node Contains speicified value; but other values as well"
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "Input value is not an Node."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertNodeNotContains(node , value , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if type(node) = "roSGNode"
    if  rbs_cmn_NodeContains(node, value)
      msg = "Node has the '" +  rbs_cmn_AsString(value) + "' value."
      m.currentResult.AddResult(msg)
      return m.GetLegacyCompatibleReturnValue(false)
    end if
  else
    msg = "Input value is not an Node."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertNodeContainsFields(node , subset , ignoredFields = invalid, msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if (type(node) = "roSGNode" and  rbs_cmn_IsAssociativeArray(subset)) or (type(node) = "roSGNode" and  rbs_cmn_IsArray(subset))
    isAA =  rbs_cmn_IsAssociativeArray(subset)
    isIgnoredFields =  rbs_cmn_IsArray(ignoredFields)
    for each key in subset
      if (key <> "")
        if (not isIgnoredFields or not  rbs_cmn_ArrayContains(ignoredFields, key))
 subsetValue = subset[key]
          nodeValue = node[key]
          if not m.eqValues(nodeValue, subsetValue)
            msg = key + ": Expected '" +  rbs_cmn_AsString(subsetValue) + "', got '" +  rbs_cmn_AsString(nodeValue) + "'"
            m.currentResult.AddResult(msg)
            return m.GetLegacyCompatibleReturnValue(false)
          end if
        end if
      else
        ? "Found empty key!"
      end if
    end for
  else
    msg = "Input value is not an Node."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertNodeNotContainsFields(node , subset , msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if (type(node) = "roSGNode" and  rbs_cmn_IsAssociativeArray(subset)) or (type(node) = "roSGNode" and  rbs_cmn_IsArray(subset))
    isAA =  rbs_cmn_IsAssociativeArray(subset)
    for each item in subset
      key = invalid
      value = item
      if isAA
        key = item
        value = item[key]
      end if
      if  rbs_cmn_NodeContains(node, value, key)
        msg = "Node has the '" +  rbs_cmn_AsString(value) + "' value."
        m.currentResult.AddResult(msg)
        return m.GetLegacyCompatibleReturnValue(false)
      end if
    end for
  else
    msg = "Input value is not an Node."
    m.currentResult.AddResult(msg)
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_AssertAAContainsSubset(array , subset , ignoredFields = invalid, msg = "") as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  if (rbs_cmn_IsAssociativeArray(array) and  rbs_cmn_IsAssociativeArray(subset))
    isAA =  rbs_cmn_IsAssociativeArray(subset)
    isIgnoredFields =  rbs_cmn_IsArray(ignoredFields)
    for each key in subset
      if (key <> "")
        if (not isIgnoredFields or not  rbs_cmn_ArrayContains(ignoredFields, key))
 subsetValue = subset[key]
          arrayValue = array[key]
          if not m.eqValues(arrayValue, subsetValue)
            msg = key + ": Expected '" +  rbs_cmn_AsString(subsetValue) + "', got '" +  rbs_cmn_AsString(arrayValue) + "'"
            m.currentResult.AddResult(msg)
            return m.GetLegacyCompatibleReturnValue(false)
          end if
        end if
      else
        ? "Found empty key!"
      end if
    end for
  else
    msg = "Input values are not an Associative Array."
    return m.GetLegacyCompatibleReturnValue(false)
  end if
  m.currentResult.AddResult("")
  return m.GetLegacyCompatibleReturnValue(true)
end function
 function RBS_BTS_BaseTestSuite_Stub(target, methodName, returnValue = invalid, allowNonExistingMethods = false) as object
  if (type(target) <> "roAssociativeArray")
    m.Fail("could not create Stub provided target was null")
    return {}
  end if
  if (m.stubs = invalid)
    m.__stubId = -1
    m.stubs = {}
  end if
  m.__stubId++
  if (m.__stubId > 5)
    ? "ERROR ONLY 6 STUBS PER TEST ARE SUPPORTED!!"
    return invalid
  end if
  id = stri(m.__stubId).trim()
  fake = m.CreateFake(id, target, methodName, 1, invalid, returnValue)
  m.stubs[id] = fake
  allowNonExisting = m.allowNonExistingMethodsOnMocks = true or allowNonExistingMethods
  isMethodPresent = type(target[methodName]) = "Function" or type(target[methodName]) = "roFunction"
  if (isMethodPresent or allowNonExisting)
    target[methodName] = m["StubCallback" + id]
    target.__stubs = m.stubs
    if (not isMethodPresent)
      ? "WARNING - stubbing call " ; methodName; " which did not exist on target object"
    end if
  else
    ? "ERROR - could not create Stub : method not found  "; target ; "." ; methodName
  end if
  return fake
end function
 function RBS_BTS_BaseTestSuite_ExpectOnce(target, methodName, expectedArgs = invalid, returnValue = invalid, allowNonExistingMethods = false) as object
  return m.Mock(target, methodName, 1, expectedArgs, returnValue, allowNonExistingMethods)
end function
 function RBS_BTS_BaseTestSuite_ExpectOnceWLN(lineNumber, target, methodName, expectedArgs = invalid, returnValue = invalid, allowNonExistingMethods = false) as object
  return m.Mock(target, methodName, 1, expectedArgs, returnValue, allowNonExistingMethods, lineNumber)
end function
 function RBS_BTS_BaseTestSuite_ExpectOnceOrNone(target, methodName, isExpected, expectedArgs = invalid, returnValue = invalid, allowNonExistingMethods = false) as object
  if isExpected
    return m.ExpectOnce(target, methodName, expectedArgs, returnValue, allowNonExistingMethods)
  else
    return m.ExpectNone(target, methodName, allowNonExistingMethods)
  end if
end function
 function RBS_BTS_BaseTestSuite_ExpectOnceOrNoneWLN(lineNumber, target, methodName, isExpected, expectedArgs = invalid, returnValue = invalid, allowNonExistingMethods = false) as object
  if isExpected
    return m.ExpectOnceWLN(lineNumber, target, methodName, expectedArgs, returnValue, allowNonExistingMethods)
  else
    return m.ExpectNoneWLN(lineNumber, target, methodName, allowNonExistingMethods)
  end if
end function
 function RBS_BTS_BaseTestSuite_ExpectNone(target, methodName, allowNonExistingMethods = false) as object
  return m.Mock(target, methodName, 0, invalid, invalid, allowNonExistingMethods)
end function
 function RBS_BTS_BaseTestSuite_ExpectNoneWLN(lineNumber, target, methodName, allowNonExistingMethods = false) as object
  return m.Mock(target, methodName, 0, invalid, invalid, allowNonExistingMethods, lineNumber)
end function
 function RBS_BTS_BaseTestSuite_Expect(target, methodName, expectedInvocations = 1, expectedArgs = invalid, returnValue = invalid, allowNonExistingMethods = false) as object
  return m.Mock(target, methodName, expectedInvocations, expectedArgs, returnValue, allowNonExistingMethods)
end function
 function RBS_BTS_BaseTestSuite_ExpectWLN(lineNumber, target, methodName, expectedInvocations = 1, expectedArgs = invalid, returnValue = invalid, allowNonExistingMethods = false) as object
  return m.Mock(target, methodName, expectedInvocations, expectedArgs, returnValue, allowNonExistingMethods, lineNumber)
end function
 function RBS_BTS_BaseTestSuite_Mock(target, methodName, expectedInvocations = 1, expectedArgs = invalid, returnValue = invalid, allowNonExistingMethods = false, lineNumber = -1) as object
  if not  rbs_cmn_IsAssociativeArray(target)
    m.Fail("mock args: target was not an AA")
  else if not  rbs_cmn_IsString(methodName)
    m.Fail("mock args: methodName was not a string")
  else if not  rbs_cmn_IsNumber(expectedInvocations)
    m.Fail("mock args: expectedInvocations was not an int")
  else if not  rbs_cmn_IsArray(expectedArgs) and  rbs_cmn_IsValid(expectedArgs)
    m.Fail("mock args: expectedArgs was not invalid or an array of args")
  else if  rbs_cmn_IsUndefined(expectedArgs)
    m.Fail("mock args: expectedArgs undefined")
  else if  rbs_cmn_IsUndefined(returnValue)
    m.Fail("mock args: returnValue undefined")
  end if
  if m.currentResult.isFail
    ? "ERROR: "; m.currentResult.messages[m.currentResult.currentAssertIndex - 1]
    return {}
  end if
  if (m.mocks = invalid)
    m.__mockId = -1
    m.__mockTargetId = -1
    m.mocks = {}
  end if
  fake = invalid
  if not target.doesExist("__rooibosTargetId")
    m.__mockTargetId++
    target["__rooibosTargetId"] = m.__mockTargetId
  end if
  for i = 0 to m.__mockId
    id = stri(i).trim()
    mock = m.mocks[id]
    if mock <> invalid and mock.methodName = methodName and mock.target.__rooibosTargetId = target.__rooibosTargetId
      fake = mock
      fake.lineNumbers.push(lineNumber)
      exit for
    end if
  end for
  if fake = invalid
    m.__mockId++
    id = stri(m.__mockId).trim()
    if (m.__mockId > 25)
      ? "ERROR ONLY 25 MOCKS PER TEST ARE SUPPORTED!! you're on # " ; m.__mockId
      ? " Method was " ; methodName
      return invalid
    end if
    fake = m.CreateFake(id, target, methodName, expectedInvocations, expectedArgs, returnValue, lineNumber)
    m.mocks[id] = fake 'this will bind it to m
    allowNonExisting = m.allowNonExistingMethodsOnMocks = true or allowNonExistingMethods
    isMethodPresent = type(target[methodName]) = "Function" or type(target[methodName]) = "roFunction"
    if (isMethodPresent or allowNonExisting)
      target[methodName] = m["MockCallback" + id]
      target.__mocks = m.mocks
      if (not isMethodPresent)
        ? "WARNING - mocking call " ; methodName; " which did not exist on target object"
      end if
    else
      ? "ERROR - could not create Mock : method not found  "; target ; "." ; methodName
    end if
  else
    m.CombineFakes(fake, m.CreateFake(id, target, methodName, expectedInvocations, expectedArgs, returnValue, lineNumber))
  end if
  return fake
end function
 function RBS_BTS_BaseTestSuite_CreateFake(id, target, methodName, expectedInvocations = 1, expectedArgs = invalid, returnValue = invalid, lineNumber = -1) as object
  expectedArgsValues = []
  hasArgs =  rbs_cmn_IsArray(expectedArgs)
  if (hasArgs)
    defaultValue = m.invalidValue
  else
    defaultValue = m.ignoreValue
    expectedArgs = []
  end if
  lineNumbers = [lineNumber]
  for i = 0 to 9
    if (hasArgs and expectedArgs.count() > i)
      value = expectedArgs[i]
      if not  rbs_cmn_IsUndefined(value)
        if  rbs_cmn_IsAssociativeArray(value) and  rbs_cmn_isValid(value.matcher)
          if not  rbs_cmn_isFunction(value.matcher)
            ? "[ERROR] you have specified a matching function; but it is not in scope!"
            expectedArgsValues.push("#ERR-OUT_OF_SCOPE_MATCHER!")
          else
            expectedArgsValues.push(expectedArgs[i])
          end if
        else
          expectedArgsValues.push(expectedArgs[i])
        end if
      else
        expectedArgsValues.push("#ERR-UNDEFINED!")
      end if
    else
      expectedArgsValues.push(defaultValue)
    end if
  end for
  fake = {
    id : id,
    target: target,
    methodName: methodName,
    returnValue: returnValue,
    lineNumbers: lineNumbers,
    isCalled: false,
    invocations: 0,
    invokedArgs: [invalid, invalid, invalid, invalid, invalid, invalid, invalid, invalid, invalid],
    expectedArgs: expectedArgsValues,
    expectedInvocations: expectedInvocations,
    callback: function(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
      if (m.allInvokedArgs = invalid)
        m.allInvokedArgs = []
      end if
      m.invokedArgs = [arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
      m.allInvokedArgs.push ([arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9])
      m.isCalled = true
      m.invocations++
      if (type(m.returnValue) = "roAssociativeArray" and m.returnValue.doesExist("multiResult"))
        returnValues = m.returnValue["multiResult"]
        returnIndex = m.invocations - 1
        if (type(returnValues) = "roArray" and returnValues.count() > 0)
          if returnValues.count() <= m.invocations
            returnIndex = returnValues.count() - 1
            print "Multi return values all used up - repeating last value"
          end if
          return returnValues[returnIndex]
        else
          ? "Multi return value was specified; but no array of results were found"
          return invalid
        end if
      else
        return m.returnValue
      end if
    end function
  }
  return fake
end function
 function RBS_BTS_BaseTestSuite_CombineFakes(fake, otherFake)
  if type(fake.expectedArgs) <> "roAssociativeArray" or not fake.expectedArgs.doesExist("multiInvoke")
    currentExpectedArgsArgs = fake.expectedArgs
    fake.expectedArgs = {
      "multiInvoke": [currentExpectedArgsArgs]
    }
  end if
  fake.expectedArgs.multiInvoke.push(otherFake.expectedArgs)
  if type(fake.returnValue) <> "roAssociativeArray" or not fake.returnValue.doesExist("multiResult")
    currentReturnValue = fake.returnValue
    fake.returnValue = {
      "multiResult": [currentReturnValue]
    }
  end if
  fake.returnValue.multiResult.push(otherFake.returnValue)
  fake.lineNumbers.push(lineNumber)
  fake.expectedInvocations++
end function
 function RBS_BTS_BaseTestSuite_AssertMocks() as void
  if (m.__mockId = invalid or not  rbs_cmn_IsAssociativeArray(m.mocks))
    return
  end if
  lastId = int(m.__mockId)
  for each id in m.mocks
    mock = m.mocks[id]
    methodName = mock.methodName
    if (mock.expectedInvocations <> mock.invocations)
      m.MockFail(mock.lineNumbers[0], methodName, "Wrong number of calls. (" + stri(mock.invocations).trim() + " / " + stri(mock.expectedInvocations).trim() + ")")
      m.CleanMocks()
      return
    else if mock.expectedInvocations > 0 and (rbs_cmn_IsArray(mock.expectedArgs) or (type(mock.expectedArgs) = "roAssociativeArray" and  rbs_cmn_IsArray(mock.expectedArgs.multiInvoke)))
      isMultiArgsSupported = type(mock.expectedArgs) = "roAssociativeArray" and  rbs_cmn_IsArray(mock.expectedArgs.multiInvoke)
      for invocationIndex = 0 to mock.invocations - 1
        invokedArgs = mock.allInvokedArgs[invocationIndex]
        if isMultiArgsSupported
          expectedArgs = mock.expectedArgs.multiInvoke[invocationIndex]
        else
          expectedArgs = mock.expectedArgs
        end if
        for i = 0 to expectedArgs.count() - 1
          value = invokedArgs[i]
          expected = expectedArgs[i]
          didNotExpectArg =  rbs_cmn_IsString(expected) and expected = m.invalidValue
          if (didNotExpectArg)
            expected = invalid
          end if
          isUsingMatcher =  rbs_cmn_IsAssociativeArray(expected) and  rbs_cmn_isFunction(expected.matcher)
          if isUsingMatcher
            if not expected.matcher(value)
              m.MockFail(mock.lineNumbers[invocationIndex], methodName, "on Invocation #" + stri(invocationIndex).trim() + ", expected arg #" + stri(i).trim() + "  to match matching function '" +  rbs_cmn_AsString(expected.matcher) + "' got '" +  rbs_cmn_AsString(value) + "')")
              m.CleanMocks()
            end if
          else
            if (not (rbs_cmn_IsString(expected) and expected = m.ignoreValue) and not m.eqValues(value, expected))
              if (expected = invalid)
                expected = "[INVALID]"
              end if
              m.MockFail(mock.lineNumbers[invocationIndex], methodName, "on Invocation #" + stri(invocationIndex).trim() + ", expected arg #" + stri(i).trim() + "  to be '" +  rbs_cmn_AsString(expected) + "' got '" +  rbs_cmn_AsString(value) + "')")
              m.CleanMocks()
              return
            end if
          end if
        end for
      end for
    end if
  end for
  m.CleanMocks()
end function
 function RBS_BTS_BaseTestSuite_CleanMocks() as void
  if m.mocks = invalid then return
  for each id in m.mocks
    mock = m.mocks[id]
    mock.target.__mocks = invalid
  end for
  m.mocks = invalid
end function
 function RBS_BTS_BaseTestSuite_CleanStubs() as void
  if m.stubs = invalid then return
  for each id in m.stubs
    stub = m.stubs[id]
    stub.target.__stubs = invalid
  end for
  m.stubs = invalid
end function
 function RBS_BTS_BaseTestSuite_MockFail(lineNumber, methodName, message) as dynamic
  if (m.currentResult.isFail) then return m.GetLegacyCompatibleReturnValue(false) ' skip test we already failed
  m.currentResult.AddMockResult(lineNumber, "mock failure on '" + methodName + "' : " + message)
  return m.GetLegacyCompatibleReturnValue(false)
end function
 function RBS_BTS_BaseTestSuite_StubCallback0(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__Stubs["0"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_StubCallback1(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__Stubs["1"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_StubCallback2(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__Stubs["2"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_StubCallback3(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__Stubs["3"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_StubCallback4(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__Stubs["4"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_StubCallback5(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__Stubs["5"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback0(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["0"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback1(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["1"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback2(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["2"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback3(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["3"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback4(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["4"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback5(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["5"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback6(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["6"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback7(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["7"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback8(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["8"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback9(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["9"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback10(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["10"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback11(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["11"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback12(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["12"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback13(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["13"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback14(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["14"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback15(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["15"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback16(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["16"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback17(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["17"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback18(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["18"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback19(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["19"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback20(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["20"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback21(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["21"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback22(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["22"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback23(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["23"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_MockCallback24(arg1 = invalid, arg2 = invalid, arg3 = invalid, arg4 = invalid, arg5 = invalid, arg6 = invalid, arg7 = invalid, arg8 = invalid, arg9 = invalid)as dynamic
  fake = m.__mocks["24"]
  return fake.callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end function
 function RBS_BTS_BaseTestSuite_pathAsArray_(path)
  pathRE = CreateObject("roRegex", "\[([0-9]+)\]", "i")
  segments = []
  if type(path) = "String" or type(path) = "roString"
    dottedPath = pathRE.replaceAll(path, ".\1")
    stringSegments = dottedPath.tokenize(".")
    for each s in stringSegments
      if (Asc(s) >= 48) and (Asc(s) <= 57)
        segments.push(s.toInt())
      else
        segments.push(s)
      end if
    end for
  else if type(path) = "roList" or type(path) = "roArray"
    stringPath = ""
    for each s in path
      stringPath = stringPath + "." + Box(s).toStr()
    end for
    segments = m.pathAsArray_(stringPath)
  else
    segments = invalid
  end if
  return segments
end function
 function RBS_BTS_BaseTestSuite_g(aa, path, default = invalid)
  if type(aa) <> "roAssociativeArray" and type(aa) <> "roArray" and type(aa) <> "roSGNode" then return default
  segments = m.pathAsArray_(path)
  if (Type(path) = "roInt" or Type(path) = "roInteger" or Type(path) = "Integer")
    path = stri(path).trim()
  end if
  if segments = invalid then return default
  result = invalid
  while segments.count() > 0
    key = segments.shift()
    if (type(key) = "roInteger") 'it's a valid index
      if (aa <> invalid and GetInterface(aa, "ifArray") <> invalid)
        value = aa[key]
      else if (aa <> invalid and GetInterface(aa, "ifSGNodeChildren") <> invalid)
        value = aa.getChild(key)
      else if (aa <> invalid and GetInterface(aa, "ifAssociativeArray") <> invalid)
        key = tostr(key)
        if not aa.doesExist(key)
          exit while
        end if
        value = aa.lookup(key)
      else
        value = invalid
      end if
    else
      if not aa.doesExist(key)
        exit while
      end if
      value = aa.lookup(key)
    end if
    if segments.count() = 0
      result = value
      exit while
    end if
    if type(value) <> "roAssociativeArray" and type(value) <> "roArray" and type(value) <> "roSGNode"
      exit while
    end if
    aa = value
  end while
  if result = invalid then return default
  return result
end function
      function __BaseTestSuite_builder()
      instance = {}
      BaseTestSuite_instance = {
        __className: "BaseTestSuite"
        AddTest: RBS_BTS_BaseTestSuite_AddTest
        CreateTest: RBS_BTS_BaseTestSuite_CreateTest
        Fail: RBS_BTS_BaseTestSuite_Fail
        GetLegacyCompatibleReturnValue: RBS_BTS_BaseTestSuite_GetLegacyCompatibleReturnValue
        AssertFalse: RBS_BTS_BaseTestSuite_AssertFalse
        AssertTrue: RBS_BTS_BaseTestSuite_AssertTrue
        AssertEqual: RBS_BTS_BaseTestSuite_AssertEqual
        AssertLike: RBS_BTS_BaseTestSuite_AssertLike
        AssertNotEqual: RBS_BTS_BaseTestSuite_AssertNotEqual
        AssertInvalid: RBS_BTS_BaseTestSuite_AssertInvalid
        AssertNotInvalid: RBS_BTS_BaseTestSuite_AssertNotInvalid
        AssertAAHasKey: RBS_BTS_BaseTestSuite_AssertAAHasKey
        AssertAANotHasKey: RBS_BTS_BaseTestSuite_AssertAANotHasKey
        AssertAAHasKeys: RBS_BTS_BaseTestSuite_AssertAAHasKeys
        AssertAANotHasKeys: RBS_BTS_BaseTestSuite_AssertAANotHasKeys
        AssertArrayContains: RBS_BTS_BaseTestSuite_AssertArrayContains
        AssertArrayContainsAAs: RBS_BTS_BaseTestSuite_AssertArrayContainsAAs
        AssertArrayNotContains: RBS_BTS_BaseTestSuite_AssertArrayNotContains
        AssertArrayContainsSubset: RBS_BTS_BaseTestSuite_AssertArrayContainsSubset
        AssertArrayNotContainsSubset: RBS_BTS_BaseTestSuite_AssertArrayNotContainsSubset
        AssertArrayCount: RBS_BTS_BaseTestSuite_AssertArrayCount
        AssertArrayNotCount: RBS_BTS_BaseTestSuite_AssertArrayNotCount
        AssertEmpty: RBS_BTS_BaseTestSuite_AssertEmpty
        AssertNotEmpty: RBS_BTS_BaseTestSuite_AssertNotEmpty
        AssertArrayContainsOnlyValuesOfType: RBS_BTS_BaseTestSuite_AssertArrayContainsOnlyValuesOfType
        GetIsTypeFunction: RBS_BTS_BaseTestSuite_GetIsTypeFunction
        AssertType: RBS_BTS_BaseTestSuite_AssertType
        AssertSubType: RBS_BTS_BaseTestSuite_AssertSubType
        EqValues: RBS_BTS_BaseTestSuite_EqValues
        EqAssocArray: RBS_BTS_BaseTestSuite_EqAssocArray
        EqArray: RBS_BTS_BaseTestSuite_EqArray
        AssertNodeCount: RBS_BTS_BaseTestSuite_AssertNodeCount
        AssertNodeNotCount: RBS_BTS_BaseTestSuite_AssertNodeNotCount
        AssertNodeEmpty: RBS_BTS_BaseTestSuite_AssertNodeEmpty
        AssertNodeNotEmpty: RBS_BTS_BaseTestSuite_AssertNodeNotEmpty
        AssertNodeContains: RBS_BTS_BaseTestSuite_AssertNodeContains
        AssertNodeContainsOnly: RBS_BTS_BaseTestSuite_AssertNodeContainsOnly
        AssertNodeNotContains: RBS_BTS_BaseTestSuite_AssertNodeNotContains
        AssertNodeContainsFields: RBS_BTS_BaseTestSuite_AssertNodeContainsFields
        AssertNodeNotContainsFields: RBS_BTS_BaseTestSuite_AssertNodeNotContainsFields
        AssertAAContainsSubset: RBS_BTS_BaseTestSuite_AssertAAContainsSubset
        Stub: RBS_BTS_BaseTestSuite_Stub
        ExpectOnce: RBS_BTS_BaseTestSuite_ExpectOnce
        ExpectOnceWLN: RBS_BTS_BaseTestSuite_ExpectOnceWLN
        ExpectOnceOrNone: RBS_BTS_BaseTestSuite_ExpectOnceOrNone
        ExpectOnceOrNoneWLN: RBS_BTS_BaseTestSuite_ExpectOnceOrNoneWLN
        ExpectNone: RBS_BTS_BaseTestSuite_ExpectNone
        ExpectNoneWLN: RBS_BTS_BaseTestSuite_ExpectNoneWLN
        Expect: RBS_BTS_BaseTestSuite_Expect
        ExpectWLN: RBS_BTS_BaseTestSuite_ExpectWLN
        Mock: RBS_BTS_BaseTestSuite_Mock
        CreateFake: RBS_BTS_BaseTestSuite_CreateFake
        CombineFakes: RBS_BTS_BaseTestSuite_CombineFakes
        AssertMocks: RBS_BTS_BaseTestSuite_AssertMocks
        CleanMocks: RBS_BTS_BaseTestSuite_CleanMocks
        CleanStubs: RBS_BTS_BaseTestSuite_CleanStubs
        MockFail: RBS_BTS_BaseTestSuite_MockFail
        StubCallback0: RBS_BTS_BaseTestSuite_StubCallback0
        StubCallback1: RBS_BTS_BaseTestSuite_StubCallback1
        StubCallback2: RBS_BTS_BaseTestSuite_StubCallback2
        StubCallback3: RBS_BTS_BaseTestSuite_StubCallback3
        StubCallback4: RBS_BTS_BaseTestSuite_StubCallback4
        StubCallback5: RBS_BTS_BaseTestSuite_StubCallback5
        MockCallback0: RBS_BTS_BaseTestSuite_MockCallback0
        MockCallback1: RBS_BTS_BaseTestSuite_MockCallback1
        MockCallback2: RBS_BTS_BaseTestSuite_MockCallback2
        MockCallback3: RBS_BTS_BaseTestSuite_MockCallback3
        MockCallback4: RBS_BTS_BaseTestSuite_MockCallback4
        MockCallback5: RBS_BTS_BaseTestSuite_MockCallback5
        MockCallback6: RBS_BTS_BaseTestSuite_MockCallback6
        MockCallback7: RBS_BTS_BaseTestSuite_MockCallback7
        MockCallback8: RBS_BTS_BaseTestSuite_MockCallback8
        MockCallback9: RBS_BTS_BaseTestSuite_MockCallback9
        MockCallback10: RBS_BTS_BaseTestSuite_MockCallback10
        MockCallback11: RBS_BTS_BaseTestSuite_MockCallback11
        MockCallback12: RBS_BTS_BaseTestSuite_MockCallback12
        MockCallback13: RBS_BTS_BaseTestSuite_MockCallback13
        MockCallback14: RBS_BTS_BaseTestSuite_MockCallback14
        MockCallback15: RBS_BTS_BaseTestSuite_MockCallback15
        MockCallback16: RBS_BTS_BaseTestSuite_MockCallback16
        MockCallback17: RBS_BTS_BaseTestSuite_MockCallback17
        MockCallback18: RBS_BTS_BaseTestSuite_MockCallback18
        MockCallback19: RBS_BTS_BaseTestSuite_MockCallback19
        MockCallback20: RBS_BTS_BaseTestSuite_MockCallback20
        MockCallback21: RBS_BTS_BaseTestSuite_MockCallback21
        MockCallback22: RBS_BTS_BaseTestSuite_MockCallback22
        MockCallback23: RBS_BTS_BaseTestSuite_MockCallback23
        MockCallback24: RBS_BTS_BaseTestSuite_MockCallback24
        pathAsArray_: RBS_BTS_BaseTestSuite_pathAsArray_
        g: RBS_BTS_BaseTestSuite_g
        Name: "BaseTestSuite"
        invalidValue: "#ROIBOS#INVALID_VALUE" ' special value used in mock arguments
        ignoreValue: "#ROIBOS#IGNORE_VALUE" ' special value used in mock arguments
        anyStringMatcher: { "matcher":  rbs_match_anyStringMatcher } 
        anyBoolMatcher: { "matcher":  rbs_match_anyBoolMatcher } 
        anyNumberMatcher: { "matcher":  rbs_match_anyNumberMatcher } 
        anyAAMatcher: { "matcher":  rbs_match_anyAAMatcher } 
        anyArrayMatcher: { "matcher":  rbs_match_anyArrayMatcher } 
        anyNodeMatcher: { "matcher":  rbs_match_anyNodeMatcher } 
        allowNonExistingMethodsOnMocks: true
        isAutoAssertingMocks: true
        TestCases: []
         __BaseTestSuite: RBS_BTS_BaseTestSuite_new_
      }
      instance.append(BaseTestSuite_instance)
      return instance
      end function
      function BaseTestSuite()
        instance = __BaseTestSuite_builder()
        instance.__BaseTestSuite()
        return instance
      end function
      function RBS_BTS_BaseTestSuite_new_()
      end function
function RBS_CMN_IsXmlElement(value) as boolean
  return  rbs_cmn_IsValid(value) and GetInterface(value, "ifXMLElement") <> invalid
end function
function RBS_CMN_IsFunction(value) as boolean
  return  rbs_cmn_IsValid(value) and GetInterface(value, "ifFunction") <> invalid
end function
function RBS_CMN_GetFunction(filename, functionName) as object
  if (not  rbs_cmn_IsNotEmptyString(functionName)) then return invalid
  if (not  rbs_cmn_IsNotEmptyString(filename)) then return invalid
  mapFunction = RBSFM_getFunctionsForFile(filename)
  if mapFunction <> invalid
    map = mapFunction()
    if (type(map) = "roAssociativeArray")
      functionPointer = map[functionName]
      return functionPointer
    else
      return invalid
    end if
  end if
  return invalid
end function
function RBS_CMN_GetFunctionBruteForce(functionName) as object
  if (not  rbs_cmn_IsNotEmptyString(functionName)) then return invalid
  filenames = RBSFM_getFilenames()
  for i = 0 to filenames.count() - 1
    filename = filenames[i]
    mapFunction = RBSFM_getFunctionsForFile(filename)
    if mapFunction <> invalid
      map = mapFunction()
      if (type(map) = "roAssociativeArray")
        functionPointer = map[functionName]
        if functionPointer <> invalid
          return functionPointer
        end if
      end if
    end if
  end for
  return invalid
end function
function RBS_CMN_IsBoolean(value) as boolean
  return  rbs_cmn_IsValid(value) and GetInterface(value, "ifBoolean") <> invalid
end function
function RBS_CMN_IsInteger(value) as boolean
  return  rbs_cmn_IsValid(value) and GetInterface(value, "ifInt") <> invalid and (Type(value) = "roInt" or Type(value) = "roInteger" or Type(value) = "Integer")
end function
function RBS_CMN_IsFloat(value) as boolean
  return  rbs_cmn_IsValid(value) and GetInterface(value, "ifFloat") <> invalid
end function
function RBS_CMN_IsDouble(value) as boolean
  return  rbs_cmn_IsValid(value) and GetInterface(value, "ifDouble") <> invalid
end function
function RBS_CMN_IsLongInteger(value) as boolean
  return  rbs_cmn_IsValid(value) and GetInterface(value, "ifLongInt") <> invalid
end function
function RBS_CMN_IsNumber(value) as boolean
  return  rbs_cmn_IsLongInteger(value) or  rbs_cmn_IsDouble(value) or  rbs_cmn_IsInteger(value) or  rbs_cmn_IsFloat(value)
end function
function RBS_CMN_IsList(value) as boolean
  return  rbs_cmn_IsValid(value) and GetInterface(value, "ifList") <> invalid
end function
function RBS_CMN_IsArray(value) as boolean
  return  rbs_cmn_IsValid(value) and GetInterface(value, "ifArray") <> invalid
end function
function RBS_CMN_IsAssociativeArray(value) as boolean
  return  rbs_cmn_IsValid(value) and GetInterface(value, "ifAssociativeArray") <> invalid
end function
function RBS_CMN_IsSGNode(value) as boolean
  return  rbs_cmn_IsValid(value) and GetInterface(value, "ifSGNodeChildren") <> invalid
end function
function RBS_CMN_IsString(value) as boolean
  return  rbs_cmn_IsValid(value) and GetInterface(value, "ifString") <> invalid
end function
function RBS_CMN_IsNotEmptyString(value) as boolean
  return  rbs_cmn_IsString(value) and len(value) > 0
end function
function RBS_CMN_IsDateTime(value) as boolean
  return  rbs_cmn_IsValid(value) and (GetInterface(value, "ifDateTime") <> invalid or Type(value) = "roDateTime")
end function
function RBS_CMN_IsValid(value) as boolean
  return not  rbs_cmn_IsUndefined(value) and value <> invalid
end function
function RBS_CMN_IsUndefined(value) as boolean
  return type(value) = "" or Type(value) = "<uninitialized>"
end function
function RBS_CMN_ValidStr(obj) as string
  if obj <> invalid and GetInterface(obj, "ifString") <> invalid
    return obj
  else
    return ""
  end if
end function
function RBS_CMN_AsString(input) as string
  if  rbs_cmn_IsValid(input) = false
    return "Invalid"
  else if  rbs_cmn_IsString(input)
    return input
  else if  rbs_cmn_IsInteger(input) or  rbs_cmn_IsLongInteger(input) or  rbs_cmn_IsBoolean(input)
    return input.ToStr()
  else if  rbs_cmn_IsFloat(input) or  rbs_cmn_IsDouble(input)
    return Str(input).Trim()
  else if type(input) = "roSGNode"
    return "Node(" + input.subType() + ")"
  else if type(input) = "roAssociativeArray"
    isFirst = true
    text = "{"
    if (not isFirst)
      text += ","
      isFirst = false
    end if
    for each key in input
      if key <> "__mocks" and key <> "__stubs"
        text += key + ":" +  rbs_cmn_AsString(input[key])
      end if
    end for
    text += "}"
    return text
  else if RBS_CMN_isFunction(input)
    return input.toStr()
  else
    return ""
  end if
end function
function RBS_CMN_AsInteger(input) as integer
  if  rbs_cmn_IsValid(input) = false
    return 0
  else if  rbs_cmn_IsString(input)
    return input.ToInt()
  else if  rbs_cmn_IsInteger(input)
    return input
  else if  rbs_cmn_IsFloat(input) or  rbs_cmn_IsDouble(input) or  rbs_cmn_IsLongInteger(input)
    return Int(input)
  else
    return 0
  end if
end function
function RBS_CMN_AsLongInteger(input) as longinteger
  if  rbs_cmn_IsValid(input) = false
    return 0
  else if  rbs_cmn_IsString(input)
    return  rbs_cmn_AsInteger(input)
  else if  rbs_cmn_IsLongInteger(input) or  rbs_cmn_IsFloat(input) or  rbs_cmn_IsDouble(input) or  rbs_cmn_IsInteger(input)
    return input
  else
    return 0
  end if
end function
function RBS_CMN_AsFloat(input) as float
  if  rbs_cmn_IsValid(input) = false
    return 0.0
  else if  rbs_cmn_IsString(input)
    return input.ToFloat()
  else if  rbs_cmn_IsInteger(input)
    return (input / 1)
  else if  rbs_cmn_IsFloat(input) or  rbs_cmn_IsDouble(input) or  rbs_cmn_IsLongInteger(input)
    return input
  else
    return 0.0
  end if
end function
function RBS_CMN_AsDouble(input) as double
  if  rbs_cmn_IsValid(input) = false
    return 0.0
  else if  rbs_cmn_IsString(input)
    return  rbs_cmn_AsFloat(input)
  else if  rbs_cmn_IsInteger(input) or  rbs_cmn_IsLongInteger(input) or  rbs_cmn_IsFloat(input) or  rbs_cmn_IsDouble(input)
    return input
  else
    return 0.0
  end if
end function
function RBS_CMN_AsBoolean(input) as boolean
  if  rbs_cmn_IsValid(input) = false
    return false
  else if  rbs_cmn_IsString(input)
    return LCase(input) = "true"
  else if  rbs_cmn_IsInteger(input) or  rbs_cmn_IsFloat(input)
    return input <> 0
  else if  rbs_cmn_IsBoolean(input)
    return input
  else
    return false
  end if
end function
function RBS_CMN_AsArray(value) as object
  if  rbs_cmn_IsValid(value)
    if not  rbs_cmn_IsArray(value)
      return [value]
    else
      return value
    end if
  end if
  return []
end function
function RBS_CMN_IsNullOrEmpty(value) as boolean
  if  rbs_cmn_IsString(value)
    return Len(value) = 0
  else
    return not  rbs_cmn_IsValid(value)
  end if
end function
function RBS_CMN_FindElementIndexInArray(array , value , compareAttribute = invalid , caseSensitive = false) as integer
  if  rbs_cmn_IsArray(array)
    for i = 0 to  rbs_cmn_AsArray(array).Count() - 1
      compareValue = array[i]
      if compareAttribute <> invalid and  rbs_cmn_IsAssociativeArray(compareValue)
        compareValue = compareValue.LookupCI(compareAttribute)
      end if
      if  rbs_bts_basetestsuite_EqValues(compareValue, value)
        return i
      end if
      item = array[i]
    next
  end if
  return -1
end function
function RBS_CMN_ArrayContains(array , value , compareAttribute = invalid) as boolean
  return (rbs_cmn_FindElementIndexInArray(array, value, compareAttribute) > -1)
end function
function RBS_CMN_FindElementIndexInNode(node , value) as integer
  if type(node) = "roSGNode"
    for i = 0 to node.getChildCount() - 1
      compareValue = node.getChild(i)
      if type(compareValue) = "roSGNode" and compareValue.isSameNode(value)
        return i
      end if
    next
  end if
  return -1
end function
function RBS_CMN_NodeContains(node , value) as boolean
  return (rbs_cmn_FindElementIndexInNode(node, value) > -1)
end function
function RBS_Coverage_createLCovOutput()
  ? "Generating lcov.info file..."
  cc = m.global._rbs_ccn
  expectedMap = cc.expectedMap
  filePathMap = cc.filePathMap
  resolvedMap = cc.resolvedMap
  buffer = ""
  for each module in filePathMap.items()
    moduleNumber = module.key
    filePath = module.value
    packageName = "."
    relativePath = filePath.replace("pkg:", packageName)
    sanitizedPath = relativePath.replace("\\", "/")
    buffer += "TN:" + chr(10)
    buffer += "SF:" + sanitizedPath + chr(10)
    for each expected in expectedMap[moduleNumber]
      lineNumber = expected[0]
      SHIFT = 1
      if (resolvedMap[moduleNumber] <> invalid) and resolvedMap[moduleNumber].doesExist(str(lineNumber)) then
        buffer += "DA:" + str(lineNumber + SHIFT) + ",1" + chr(10)
      else
        buffer += "DA:" + str(lineNumber + SHIFT) + ",0" + chr(10)
      end if
    end for
    buffer += "end_of_record" + chr(10)
  end for
  return buffer
end function
function RBS_Coverage_printLCovInfo()
  ?
  ? "+++++++++++++++++++++++++++++++++++++++++++"
  ? "LCOV.INFO FILE"
  ? "+++++++++++++++++++++++++++++++++++++++++++"
  ?
  ? "+-=-coverage:start"
  ?  rbs_coverage_createLCovOutput()
  ? "+-=-coverage:end"
end function
function RBS_ItG_GetTestCases(group) as object
  if (group.hasSoloTests = true)
    return group.soloTestCases
  else
    return group.testCases
  end if
end function
function RBS_ItG_GetRunnableTestSuite(group) as object
  testCases =  rbs_itg_GetTestCases(group)
  runnableSuite = BaseTestSuite()
  runnableSuite.name = group.name
  runnableSuite.isLegacy = group.isLegacy = true
  if group.testCaseLookup = invalid
    group.testCaseLookup = {}
  end if
  for each testCase in testCases
    name = testCase.name
    if (testCase.isSolo = true)
      name += " [SOLO] "
    end if
    testFunction =  rbs_cmn_GetFunction(group.filename, testCase.funcName)
    runnableSuite.addTest(name, testFunction, testCase.funcName)
    group.testCaseLookup[name] = testCase
  end for
  runnableSuite.SetUp =  rbs_cmn_GetFunction(group.filename, group.setupFunctionName)
  runnableSuite.TearDown =  rbs_cmn_GetFunction(group.filename, group.teardownFunctionName)
  runnableSuite.BeforeEach =  rbs_cmn_GetFunction(group.filename, group.beforeEachFunctionName)
  runnableSuite.AfterEach =  rbs_cmn_GetFunction(group.filename, group.afterEachFunctionName)
  return runnableSuite
end function
 function RBS_IG_ItemGenerator_new()
  m.isValid =  rbs_cmn_IsValid(scheme)
end function
 function RBS_IG_ItemGenerator_GetItem(scheme as object) as object
  item = invalid
  if  rbs_cmn_IsAssociativeArray(scheme)
    item = m.getAssocArray(scheme)
  else if  rbs_cmn_IsArray(scheme)
    item = m.getArray(scheme)
  else if  rbs_cmn_IsString(scheme)
    item = m.getSimpleType(lCase(scheme))
  end if
  return item
end function
 function RBS_IG_ItemGenerator_GetAssocArray(scheme as object) as object
  item = {}
  for each key in scheme
    if not item.DoesExist(key)
      item[key] = m.getItem(scheme[key])
    end if
  end for
  return item
end function
 function RBS_IG_ItemGenerator_GetArray(scheme as object) as object
  item = []
  for each key in scheme
    item.Push(m.getItem(key))
  end for
  return item
end function
 function RBS_IG_ItemGenerator_GetSimpleType(typeStr as string) as object
  item = invalid
  if typeStr = "integer" or typeStr = "int" or typeStr = "roint"
    item = m.getInteger()
  else if typeStr = "float" or typeStr = "rofloat"
    item = m.getFloat()
  else if typeStr = "string" or typeStr = "rostring"
    item = m.getString(10)
  else if typeStr = "boolean" or typeStr = "roboolean"
    item = m.getBoolean()
  end if
  return item
end function
 function RBS_IG_ItemGenerator_GetBoolean() as boolean
  return  rbs_cmn_AsBoolean(Rnd(2) \ Rnd(2))
end function
 function RBS_IG_ItemGenerator_GetInteger(seed = 100 as integer) as integer
  return Rnd(seed)
end function
 function RBS_IG_ItemGenerator_GetFloat() as float
  return Rnd(0)
end function
 function RBS_IG_ItemGenerator_GetString(seed as integer) as string
  item = ""
  if seed > 0
    stringLength = Rnd(seed)
    for i = 0 to stringLength
      chType = Rnd(3)
      if chType = 1     'Chr(48-57) - numbers
        chNumber = 47 + Rnd(10)
      else if chType = 2  'Chr(65-90) - Uppercase Letters
        chNumber = 64 + Rnd(26)
      else        'Chr(97-122) - Lowercase Letters
        chNumber = 96 + Rnd(26)
      end if
      item = item + Chr(chNumber)
    end for
  end if
  return item
end function
      function __ItemGenerator_builder()
      instance = {}
      ItemGenerator_instance = {
        __className: "ItemGenerator"
        GetItem: RBS_IG_ItemGenerator_GetItem
        GetAssocArray: RBS_IG_ItemGenerator_GetAssocArray
        GetArray: RBS_IG_ItemGenerator_GetArray
        GetSimpleType: RBS_IG_ItemGenerator_GetSimpleType
        GetBoolean: RBS_IG_ItemGenerator_GetBoolean
        GetInteger: RBS_IG_ItemGenerator_GetInteger
        GetFloat: RBS_IG_ItemGenerator_GetFloat
        GetString: RBS_IG_ItemGenerator_GetString
         __ItemGenerator: RBS_IG_ItemGenerator_new
      }
      instance.append(ItemGenerator_instance)
      return instance
      end function
      function ItemGenerator()
        instance = __ItemGenerator_builder()
        instance.__ItemGenerator()
        return instance
      end function
function RBS_MATCH_anyStringMatcher(value)
  return  rbs_cmn_isString(value)
end function
function RBS_MATCH_anyBoolMatcher(value)
  return  rbs_cmn_isBoolean(value)
end function
function RBS_MATCH_anyNumberMatcher(value)
  return  rbs_cmn_isNumber(value)
end function
function RBS_MATCH_anyAAMatcher(value)
  return  rbs_cmn_isAssociativeArray(value)
end function
function RBS_MATCH_anyArrayMatcher(value)
  return  rbs_cmn_isArray(value)
end function
function RBS_MATCH_anyNodeMatcher(value)
  return  rbs_cmn_isSGNode(value)
end function
function Rooibos__Init(preTestSetup = invalid, testUtilsDecoratorMethodName = invalid, testSceneName = invalid, nodeContext = invalid) as void
  args = {}
  if createObject("roAPPInfo").IsDev() <> true then
    ? " not running in dev mode! - rooibos tests only support sideloaded builds - aborting"
    return
  end if
  args.testUtilsDecoratorMethodName = testUtilsDecoratorMethodName
  args.nodeContext = nodeContext
  screen = CreateObject("roSGScreen")
  m.port = CreateObject("roMessagePort")
  screen.setMessagePort(m.port)
  if testSceneName = invalid
    testSceneName = "TestsScene"
  end if
  ? "Starting test using test scene with name TestsScene" ; testSceneName
  scene = screen.CreateScene(testSceneName)
  scene.id = "ROOT"
  screen.show()
  m.global = screen.getGlobalNode()
  m.global.addFields({ "testsScene": scene })
  if (preTestSetup <> invalid)
    preTestSetup(screen)
  end if
  testId = args.TestId
  if (testId = invalid)
    testId = "UNDEFINED_TEST_ID"
  end if
  ? "#########################################################################"
  ? "#TEST START : ###" ; testId ; "###"
  args.testScene = scene
  args.global = m.global
  rooibosVersion = "3.4.3"
  requiredRooibosPreprocessorVersion = "1.0.0"
  if not  rbs_cmn_isFunction(RBSFM_getPreprocessorVersion)
    versionError = "You are using a rooibos-preprocessor (i.e. rooibos-cli) version older than 1.0.0 - please update to " + requiredRooibosPreprocessorVersion
  else 
    if  rooibos__versionCompare(RBSFM_getPreprocessorVersion(), requiredRooibosPreprocessorVersion) >= 0
      versionError = ""
    else
      versionError = "Your rooibos-preprocessor (i.e. rooibos-cli) version '" + RBSFM_getPreprocessorVersion() + "' is not compatible with rooibos version " + rooibosVersion + ". Please upgrade your rooibos-cli to version " + requiredRooibosPreprocessorVersion
    end if 
  end if
  if versionError = ""
    ? "######################################################"
    ? ""
    ? "# rooibos framework version: " ; rooibosVersion
    ? "# tests parsed with rooibosC version: " ; RBSFM_getPreprocessorVersion()
    ? "######################################################"
    ? ""
    runner =     TestRunner(args)
    runner.Run()
    while(true)
      msg = wait(0, m.port)
      msgType = type(msg)
      if msgType = "roSGScreenEvent"
        if msg.isScreenClosed()
          return
        end if
      end if
    end while
  else
    ? ""
    ? "#########################################################"
    ? "ERROR - VERSION MISMATCH"
    ? versionError
    ? "#########################################################"
  end if
end function
function Rooibos__versionCompare(v1, v2) 
  v1parts = v1.split(".")
  v2parts = v2.split(".")
  while v1parts.count() < v2parts.count()
    v1parts.push("0")
  end while
  while v2parts.count() < v1parts.count()
    v2parts.push("0")
  end while
  for i = 0 to v1parts.count() - 1
    if (v2parts.count() = i)
      return 1
    end if
    if (v1parts[i] <> v2parts[i])
      if (v1parts[i] > v2parts[i])
        return 1
      else 
        return -1
      end if
    end if
  end for
  if (v1parts.count() <> v2parts.count()) 
    return -1
  end if
  return 0
end function
 function RBS_UTRC_UnitTestRuntimeConfig_new()
  m.suites = m.CreateSuites()
end function
 function RBS_UTRC_UnitTestRuntimeConfig_CreateSuites()
  suites = RBSFM_getTestSuitesForProject()
  includedSuites = []
  for i = 0 to suites.count() - 1
    suite = suites[i]
    if (suite.valid)
      if (suite.isSolo)
        m.hasSoloSuites = true
      end if
      if (suite.hasSoloTests = true)
        m.hasSoloTests = true
      end if
      if (suite.hasSoloGroups = true)
        m.hasSoloGroups = true
      end if
      includedSuites.Push(suite)
    else
      ? "ERROR! suite was not valid - ignoring"
    end if
  end for
  return includedSuites
end function
      function __UnitTestRuntimeConfig_builder()
      instance = {}
      UnitTestRuntimeConfig_instance = {
        __className: "UnitTestRuntimeConfig"
        CreateSuites: RBS_UTRC_UnitTestRuntimeConfig_CreateSuites
        hasSoloSuites: false
        hasSoloGroups: false
        hasSoloTests: false
         __UnitTestRuntimeConfig: RBS_UTRC_UnitTestRuntimeConfig_new
      }
      instance.append(UnitTestRuntimeConfig_instance)
      return instance
      end function
      function UnitTestRuntimeConfig()
        instance = __UnitTestRuntimeConfig_builder()
        instance.__UnitTestRuntimeConfig()
        return instance
      end function
function RBS_STATS_CreateTotalStatistic() as object
  statTotalItem = {
    Suites    : []
    Time    : 0
    Total     : 0
    Correct   : 0
    Fail    : 0
    Ignored   : 0
    Crash     : 0
    IgnoredTestNames: []
  }
  return statTotalItem
end function
function RBS_STATS_MergeTotalStatistic(stat1, stat2) as void
  for each suite in stat2.Suites
    stat1.Suites.push(suite)
  end for
  stat1.Time += stat2.Time
  stat1.Total += stat2.Total
  stat1.Correct += stat2.Correct
  stat1.Fail += stat2.Fail
  stat1.Crash += stat2.Crash
  stat1.Ignored += stat2.Ignored
  stat1.IgnoredTestNames.append(stat2.IgnoredTestNames)
end function
function RBS_STATS_CreateSuiteStatistic(name as string) as object
  statSuiteItem = {
    Name  : name
    Tests   : []
    Time  : 0
    Total   : 0
    Correct : 0
    Fail  : 0
    Crash   : 0
    Ignored   : 0
    IgnoredTestNames:[]
  }
  return statSuiteItem
end function
function RBS_STATS_CreateTestStatistic(name as string, result = "Success" as string, time = 0 as integer, errorCode = 0 as integer, errorMessage = "" as string) as object
  statTestItem = {
    Name  : name
    Result  : result
    Time  : time
    Error   : {
      Code  : errorCode
      Message : errorMessage
    }
  }
  return statTestItem
end function
sub RBS_STATS_AppendTestStatistic(statSuiteObj as object, statTestObj as object)
  if  rbs_cmn_IsAssociativeArray(statSuiteObj) and  rbs_cmn_IsAssociativeArray(statTestObj)
    statSuiteObj.Tests.Push(statTestObj)
    if  rbs_cmn_IsInteger(statTestObj.time)
      statSuiteObj.Time = statSuiteObj.Time + statTestObj.Time
    end if
    statSuiteObj.Total = statSuiteObj.Total + 1
    if lCase(statTestObj.Result) = "success"
      statSuiteObj.Correct = statSuiteObj.Correct + 1
    else if lCase(statTestObj.result) = "fail"
      statSuiteObj.Fail = statSuiteObj.Fail + 1
    else
      statSuiteObj.crash = statSuiteObj.crash + 1
    end if
  end if
end sub
sub RBS_STATS_AppendSuiteStatistic(statTotalObj as object, statSuiteObj as object)
  if  rbs_cmn_IsAssociativeArray(statTotalObj) and  rbs_cmn_IsAssociativeArray(statSuiteObj)
    statTotalObj.Suites.Push(statSuiteObj)
    statTotalObj.Time = statTotalObj.Time + statSuiteObj.Time
    if  rbs_cmn_IsInteger(statSuiteObj.Total)
      statTotalObj.Total = statTotalObj.Total + statSuiteObj.Total
    end if
    if  rbs_cmn_IsInteger(statSuiteObj.Correct)
      statTotalObj.Correct = statTotalObj.Correct + statSuiteObj.Correct
    end if
    if  rbs_cmn_IsInteger(statSuiteObj.Fail)
      statTotalObj.Fail = statTotalObj.Fail + statSuiteObj.Fail
    end if
    if  rbs_cmn_IsInteger(statSuiteObj.Crash)
      statTotalObj.Crash = statTotalObj.Crash + statSuiteObj.Crash
    end if
  end if
end sub
 function RBS_TC_UnitTestCase_new(name as string, func as dynamic, funcName as string, isSolo as boolean, isIgnored as boolean, lineNumber as integer, params = invalid, paramTestIndex = 0, paramLineNumber = 0)
  m.isSolo = isSolo
  m.func = func
  m.funcName = funcName
  m.isIgnored = isIgnored
  m.name = name
  m.lineNumber = lineNumber
  m.paramLineNumber = paramLineNumber
  m.rawParams = params
  m.paramTestIndex = paramTestIndex
  if (params <> invalid)
    m.name += stri(m.paramTestIndex)
  end if
  return this
end function
 function RBS_TC_UnitTestCase_GetAssertLine(testCase, index)
  if (testCase.assertLineNumberMap.doesExist(stri(index).trim()))
    return testCase.assertLineNumberMap[stri(index).trim()]
  else if (testCase.assertLineNumberMap.doesExist(stri(index + 1000).trim()))
    return testCase.assertLineNumberMap[stri(index + 1000).trim()]
    return testCase.lineNumber
  end if
end function
      function __UnitTestCase_builder()
      instance = {}
      UnitTestCase_instance = {
        __className: "UnitTestCase"
        GetAssertLine: RBS_TC_UnitTestCase_GetAssertLine
        isSolo: invalid
        func: invalid
        funcName: invalid
        isIgnored: invalid
        name: invalid
        lineNumber: invalid
        paramLineNumber: invalid
        assertIndex: 0
        assertLineNumberMap: {}
        getTestLineIndex: 0
        rawParams: invalid
        paramTestIndex: invalid
        isParamTest: false
        time: 0
         __UnitTestCase: RBS_TC_UnitTestCase_new
      }
      instance.append(UnitTestCase_instance)
      return instance
      end function
      function UnitTestCase(name as string, func as dynamic, funcName as string, isSolo as boolean, isIgnored as boolean, lineNumber as integer, params = invalid, paramTestIndex = 0, paramLineNumber = 0)
        instance = __UnitTestCase_builder()
        instance.__UnitTestCase(name, func, funcName, isSolo, isIgnored, lineNumber, params, paramTestIndex, paramLineNumber)
        return instance
      end function
 function RBS_LOGGER_Logger_new(config)
  m.config = config
  m.verbosityLevel = {
    basic : 0
    normal : 1
    verbose : 2
  }
  m.verbosity = m.config.logLevel
end function
 sub RBS_LOGGER_Logger_PrintStatistic(statObj as object)
  m.PrintStart()
  previousfile = invalid
  for each testSuite in statObj.Suites
    if (not statObj.testRunHasFailures or ((not m.config.showOnlyFailures) or testSuite.fail > 0 or testSuite.crash > 0))
      if (testSuite.metaTestSuite.filePath <> previousfile)
        m.PrintMetaSuiteStart(testSuite.metaTestSuite)
        previousfile = testSuite.metaTestSuite.filePath
      end if
      m.PrintSuiteStatistic(testSuite, statObj.testRunHasFailures)
    end if
  end for
  ? ""
  m.PrintEnd()
  ignoredInfo = RBSFM_getIgnoredTestInfo()
  ? "Total  = ";  rbs_cmn_AsString(statObj.Total); " ; Passed  = "; statObj.Correct; " ; Failed   = "; statObj.Fail; " ; Ignored   = "; ignoredInfo.count
  ? " Time spent: "; statObj.Time; "ms"
  ? ""
  ? ""
  if (ignoredInfo.count > 0)
    ? "IGNORED TESTS:"
    for each ignoredItemName in ignoredInfo.items
      print ignoredItemName
    end for
  end if
  if (statObj.ignored > 0)
    ? "IGNORED TESTS:"
    for each ignoredItemName in statObj.IgnoredTestNames
      print ignoredItemName
    end for
  end if
  if (statObj.Total = statObj.Correct)
    overrallResult = "Success"
  else
    overrallResult = "Fail"
  end if
  ? "RESULT: "; overrallResult
end sub
 sub RBS_LOGGER_Logger_PrintSuiteStatistic(statSuiteObj as object, hasFailures)
  m.PrintSuiteStart(statSuiteObj.Name)
  for each testCase in statSuiteObj.Tests
    if (not hasFailures or ((not m.config.showOnlyFailures) or testCase.Result <> "Success"))
      m.PrintTestStatistic(testCase)
    end if
  end for
  ? " |"
end sub
 sub RBS_LOGGER_Logger_PrintTestStatistic(testCase as object)
  metaTestCase = testCase.metaTestCase
  if (LCase(testCase.Result) <> "success")
    testChar = "-"
    if metaTestCase.testResult.failedMockLineNumber > -1
      lineNumber = metaTestCase.testResult.failedMockLineNumber
    else
      assertIndex = metaTestCase.testResult.failedAssertIndex
      lineNumber = RBS_TC_UnitTestCase_GetAssertLine(metaTestCase, assertIndex)
    end if
    locationLine = StrI(lineNumber).trim()
  else
    testChar = "|"
    locationLine = StrI(metaTestCase.lineNumber).trim()
  end if
  locationText = "pkg:/" + testCase.filePath.trim() + "(" + locationLine + ")"
  if m.config.printTestTimes = true
    timeText = " (" + stri(metaTestCase.time).trim() + "ms)"
  else
    timeText = ""
  end if
  insetText = ""
  if (metaTestcase.isParamTest <> true)
    messageLine = m.FillText(" " + testChar + " |--" + metaTestCase.Name + " : ", ".", 80)
    ? messageLine ; testCase.Result ; timeText
  else if (metaTestcase.paramTestIndex = 0)
    name = metaTestCase.Name
    if (len(name) > 1 and right(name, 1) = "0")
      name = left(name, len(name) - 1)
    end if
    ? " " + testChar + " |--" + name + " : "
  end if
  if (metaTestcase.isParamTest = true)
    insetText = "  "
    if type(metaTestCase.rawParams) = "roAssociativeArray"
      rawParams = {}
      for each key in metaTestCase.rawParams
        if type(metaTestCase.rawParams[key]) <> "Function" and type(metaTestCase.rawParams[key]) <> "roFunction"
          rawParams[key] = metaTestCase.rawParams[key]
        end if
      end for
    else
      rawParams = metaTestCase.rawParams
    end if
    messageLine = m.fillText(" " + testChar + insetText + " |--" + formatJson(rawParams) + " : ", ".", 80)
    ? messageLine ; testCase.Result ; timeText
  end if
  if LCase(testCase.Result) <> "success"
    ? " | "; insettext ;"  |--Location: "; locationText
    if (metaTestcase.isParamTest = true)
      ? " | "; insettext ;"  |--Param Line: "; StrI(metaTestCase.paramlineNumber).trim()
    end if
    ? " | "; insettext ;"  |--Error Message: "; testCase.Error.Message
  end if
end sub
 function RBS_LOGGER_Logger_FillText(text as string, fillChar = " ", numChars = 40) as string
  if (len(text) >= numChars)
    text = left(text, numChars - 5) + "..." + fillChar + fillChar
  else
    numToFill = numChars - len(text) - 1
    for i = 0 to numToFill
      text += fillChar
    end for
  end if
  return text
end function
 sub RBS_LOGGER_Logger_PrintStart()
  ? ""
  ? "[START TEST REPORT]"
  ? ""
end sub
 sub RBS_LOGGER_Logger_PrintEnd()
  ? ""
  ? "[END TEST REPORT]"
  ? ""
end sub
 sub RBS_LOGGER_Logger_PrintSuiteSetUp(sName as string)
  if m.verbosity = m.verbosityLevel.verbose
    ? "================================================================="
    ? "===   SetUp "; sName; " suite."
    ? "================================================================="
  end if
end sub
 sub RBS_LOGGER_Logger_PrintMetaSuiteStart(metaTestSuite)
  ? metaTestSuite.name; " " ; "pkg:/" ; metaTestSuite.filePath + "(1)"
end sub
 sub RBS_LOGGER_Logger_PrintSuiteStart(sName as string)
  ? " |-" ; sName
end sub
 sub RBS_LOGGER_Logger_PrintSuiteTearDown(sName as string)
  if m.verbosity = m.verbosityLevel.verbose
    ? "================================================================="
    ? "===   TearDown "; sName; " suite."
    ? "================================================================="
  end if
end sub
 sub RBS_LOGGER_Logger_PrintTestSetUp(tName as string)
  if m.verbosity = m.verbosityLevel.verbose
    ? "----------------------------------------------------------------"
    ? "---   SetUp "; tName; " test."
    ? "----------------------------------------------------------------"
  end if
end sub
 sub RBS_LOGGER_Logger_PrintTestTearDown(tName as string)
  if m.verbosity = m.verbosityLevel.verbose
    ? "----------------------------------------------------------------"
    ? "---   TearDown "; tName; " test."
    ? "----------------------------------------------------------------"
  end if
end sub
      function __Logger_builder()
      instance = {}
      Logger_instance = {
        __className: "Logger"
        PrintStatistic: RBS_LOGGER_Logger_PrintStatistic
        PrintSuiteStatistic: RBS_LOGGER_Logger_PrintSuiteStatistic
        PrintTestStatistic: RBS_LOGGER_Logger_PrintTestStatistic
        FillText: RBS_LOGGER_Logger_FillText
        PrintStart: RBS_LOGGER_Logger_PrintStart
        PrintEnd: RBS_LOGGER_Logger_PrintEnd
        PrintSuiteSetUp: RBS_LOGGER_Logger_PrintSuiteSetUp
        PrintMetaSuiteStart: RBS_LOGGER_Logger_PrintMetaSuiteStart
        PrintSuiteStart: RBS_LOGGER_Logger_PrintSuiteStart
        PrintSuiteTearDown: RBS_LOGGER_Logger_PrintSuiteTearDown
        PrintTestSetUp: RBS_LOGGER_Logger_PrintTestSetUp
        PrintTestTearDown: RBS_LOGGER_Logger_PrintTestTearDown
         __Logger: RBS_LOGGER_Logger_new
      }
      instance.append(Logger_instance)
      return instance
      end function
      function Logger(config)
        instance = __Logger_builder()
        instance.__Logger(config)
        return instance
      end function
 function Rooibos_TestRunner_new(args = {})
  m.testScene = args.testScene
  m.nodeContext = args.nodeContext
  config = RBSFM_getRuntimeConfig()
  if (config = invalid or not  rbs_cmn_IsAssociativeArray(config))
    ? "WARNING : specified config is invalid - using default"
    config = {
      showOnlyFailures: false
      failFast: false
    }
  end if
  if (args.showOnlyFailures <> invalid)
    config.showOnlyFailures = args.showOnlyFailures = "true"
  end if
  if (args.failFast <> invalid)
    config.failFast = args.failFast = "true"
  end if
  m.testUtilsDecoratorMethodName = args.testUtilsDecoratorMethodName
  m.config = config
  m.config.testsDirectory = config.testsDirectory
  m.logger = Logger(m.config)
  m.global = args.global
end function
 sub Rooibos_TestRunner_run()
  if type(RBSFM_getTestSuitesForProject) <> "Function"
    ? " ERROR! RBSFM_getTestSuitesForProject is not found! That looks like you didn't run the preprocessor as part of your test process. Please refer to the docs."
    return
  end if
  totalStatObj =  rbs_stats_CreateTotalStatistic()
  m.runtimeConfig = UnitTestRuntimeConfig()
  m.runtimeConfig.global = m.global
  totalStatObj.testRunHasFailures = false
  for each metaTestSuite in m.runtimeConfig.suites
    if (m.runtimeConfig.hasSoloTests = true)
      if (metaTestSuite.hasSoloTests <> true)
        if (m.config.logLevel = 2)
          ? "TestSuite " ; metaTestSuite.name ; " Is filtered because it has no solo tests"
        end if
        goto skipSuite
      end if
    else if (m.runtimeConfig.hasSoloSuites)
      if (metaTestSuite.isSolo <> true)
        if (m.config.logLevel = 2)
          ? "TestSuite " ; metaTestSuite.name ; " Is filtered due to solo flag"
        end if
        goto skipSuite
      end if
    end if
    if (metaTestSuite.isIgnored = true)
      if (m.config.logLevel = 2)
        ? "Ignoring TestSuite " ; metaTestSuite.name ; " Due to Ignore flag"
      end if
      totalstatobj.ignored ++
      totalStatObj.IgnoredTestNames.push("|-" + metaTestSuite.name + " [WHOLE SUITE]")
      goto skipSuite
    end if
    ? ""
    ?  rbs_logger_logger_FillText("> SUITE: " + metaTestSuite.name, ">", 80)
    if (metaTestSuite.isNodeTest = true and metaTestSuite.nodeTestFileName <> "")
      ? " +++++RUNNING NODE TEST"
      nodeType = metaTestSuite.nodeTestFileName
      ? " node type is " ; nodeType
      node = m.testScene.CallFunc("Rooibos_CreateTestNode", nodeType)
      if (type(node) = "roSGNode" and node.subType() = nodeType)
        args = {
          "metaTestSuite": metaTestSuite
          "testUtilsDecoratorMethodName": m.testUtilsDecoratorMethodName
          "config": m.config
          "runtimeConfig": m.runtimeConfig
        }
        nodeStatResults = node.callFunc("Rooibos_RunNodeTests", args)
  rbs_stats_MergeTotalStatistic(totalStatObj, nodeStatResults)
        m.testScene.RemoveChild(node)
      else
        ? " ERROR!! - could not create node required to execute tests for " ; metaTestSuite.name
        ? " Node of type " ; nodeType ; " was not found/could not be instantiated"
      end if
    else
      if (metaTestSuite.hasIgnoredTests)
        totalStatObj.IgnoredTestNames.push("|-" + metaTestSuite.name)
      end if
      m.RunItGroups(metaTestSuite, totalStatObj, m.testUtilsDecoratorMethodName, m.config, m.runtimeConfig, m.nodeContext)
    end if
    skipSuite:
  end for
  m.logger.PrintStatistic(totalStatObj)
  if  rbs_cmn_IsFunction(RBS_ReportCodeCoverage)
    RBS_ReportCodeCoverage()
    if m.config.printLcov = true
      RBS_Coverage_printLCovInfo()
    end if
  end if
  m.SendHomeKeypress()
end sub
 sub Rooibos_TestRunner_RunItGroups(metaTestSuite, totalStatObj, testUtilsDecoratorMethodName, config, runtimeConfig, nodeContext = invalid)
  if (testUtilsDecoratorMethodName <> invalid)
    testUtilsDecorator =  rbs_cmn_GetFunctionBruteForce(testUtilsDecoratorMethodName)
    if (not  rbs_cmn_IsFunction(testUtilsDecorator))
      ? "[ERROR] Test utils decorator method `" ; testUtilsDecoratorMethodName ;"` was not in scope! for testSuite: " + metaTestSuite.name
    end if
  end if
  for each itGroup in metaTestSuite.itGroups
    testSuite =  rbs_itg_GetRunnableTestSuite(itGroup)
    if (nodeContext <> invalid)
      testSuite.node = nodeContext
      testSuite.global = nodeContext.global
      testSuite.top = nodeContext.top
    end if
    if (rbs_cmn_IsFunction(testUtilsDecorator))
      testUtilsDecorator(testSuite)
    end if
    totalStatObj.Ignored += itGroup.ignoredTestCases.count()
    if (itGroup.isIgnored = true)
      if (config.logLevel = 2)
        ? "Ignoring itGroup " ; itGroup.name ; " Due to Ignore flag"
      end if
      totalStatObj.ignored += itGroup.testCases.count()
      totalStatObj.IgnoredTestNames.push("  |-" + itGroup.name + " [WHOLE GROUP]")
      goto skipItGroup
    else
      if (itGroup.ignoredTestCases.count() > 0)
        totalStatObj.IgnoredTestNames.push("  |-" + itGroup.name)
        totalStatObj.ignored += itGroup.ignoredTestCases.count()
        for each testCase in itGroup.ignoredTestCases
          if (testcase.isParamTest <> true)
            totalStatObj.IgnoredTestNames.push("  | |--" + testCase.name)
          else if (testcase.paramTestIndex = 0)
            testCaseName = testCase.Name
            if (len(testCaseName) > 1 and right(testCaseName, 1) = "0")
              testCaseName = left(testCaseName, len(testCaseName) - 1)
            end if
            totalStatObj.IgnoredTestNames.push("  | |--" + testCaseName)
          end if
        end for
      end if
    end if
    if (runtimeConfig.hasSoloTests)
      if (itGroup.hasSoloTests <> true)
        if (config.logLevel = 2)
          ? "Ignoring itGroup " ; itGroup.name ; " Because it has no solo tests"
        end if
        goto skipItGroup
      end if
    else if (runtimeConfig.hasSoloGroups)
      if (itGroup.isSolo <> true)
        goto skipItGroup
      end if
    end if
    if (testSuite.testCases.Count() = 0)
      if (config.logLevel = 2)
        ? "Ignoring TestSuite " ; itGroup.name ; " - NO TEST CASES"
      end if
      goto skipItGroup
    end if
    ? ""
    ?  rbs_logger_logger_FillText("> GROUP: " + itGroup.name, ">", 80)
    if  rbs_cmn_IsFunction(testSuite.SetUp)
      testSuite.SetUp()
    end if
  rooibos_testrunner_RunTestCases(metaTestSuite, itGroup, testSuite, totalStatObj, config, runtimeConfig)
    if  rbs_cmn_IsFunction(testSuite.TearDown)
      testSuite.TearDown()
    end if
    if (totalStatObj.testRunHasFailures = true and config.failFast = true)
      exit for
    end if
    skipItGroup:
  end for
end sub
 sub Rooibos_TestRunner_RunTestCases(metaTestSuite, itGroup, testSuite, totalStatObj, config, runtimeConfig)
  suiteStatObj =  rbs_stats_CreateSuiteStatistic(itGroup.Name)
  testSuite.global = runtimeConfig.global
  for each testCase in testSuite.testCases
    metaTestCase = itGroup.testCaseLookup[testCase.Name]
    metaTestCase.time = 0
    if (runtimeConfig.hasSoloTests and not metaTestCase.isSolo)
      goto skipTestCase
    end if
    ? ""
    ?  rbs_logger_logger_FillText("> TEST: " + testCase.Name + " ", ">", 80)
    if  rbs_cmn_IsFunction(testSuite.beforeEach)
      testSuite.beforeEach()
    end if
    testTimer = CreateObject("roTimespan")
    testCaseTimer = CreateObject("roTimespan")
    testStatObj =  rbs_stats_CreateTestStatistic(testCase.Name)
    testSuite.testCase = testCase.Func
    testStatObj.filePath = metaTestSuite.filePath
    testStatObj.metaTestCase = metaTestCase
    testSuite.currentResult = UnitTestResult()
    testStatObj.metaTestCase.testResult = testSuite.currentResult
    if (metaTestCase.isParamsValid)
      if (metaTestCase.isParamTest)
        testCaseParams = []
        for paramIndex = 0 to metaTestCase.rawParams.count()
          paramValue = metaTestCase.rawParams[paramIndex]
          if type(paramValue) = "roString" and len(paramValue) >= 8 and left(paramValue, 8) = "#RBSNode"
            nodeType = "ContentNode"
            paramDirectiveArgs = paramValue.split("|")
            if paramDirectiveArgs.count() > 1
              nodeType = paramDirectiveArgs[1]
            end if
            paramValue = createObject("roSGNode", nodeType)
          end if
          testCaseParams.push(paramValue)
        end for
        testCaseTimer.mark()
        if (metaTestCase.expectedNumberOfParams = 1)
          testSuite.testCase(testCaseParams[0])
        else if (metaTestCase.expectedNumberOfParams = 2)
          testSuite.testCase(testCaseParams[0], testCaseParams[1])
        else if (metaTestCase.expectedNumberOfParams = 3)
          testSuite.testCase(testCaseParams[0], testCaseParams[1], testCaseParams[2])
        else if (metaTestCase.expectedNumberOfParams = 4)
          testSuite.testCase(testCaseParams[0], testCaseParams[1], testCaseParams[2], testCaseParams[3])
        else if (metaTestCase.expectedNumberOfParams = 5)
          testSuite.testCase(testCaseParams[0], testCaseParams[1], testCaseParams[2], testCaseParams[3], testCaseParams[4])
        else if (metaTestCase.expectedNumberOfParams = 6)
          testSuite.testCase(testCaseParams[0], testCaseParams[1], testCaseParams[2], testCaseParams[3], testCaseParams[4], testCaseParams[5])
        else if (metaTestCase.expectedNumberOfParams = 7)
          testSuite.testCase(testCaseParams[0], testCaseParams[1], testCaseParams[2], testCaseParams[3], testCaseParams[4], testCaseParams[5], testCaseParams[6])
        else if (metaTestCase.expectedNumberOfParams = 8)
          testSuite.testCase(testCaseParams[0], testCaseParams[1], testCaseParams[2], testCaseParams[3], testCaseParams[4], testCaseParams[5], testCaseParams[6], testCaseParams[7])
        else if (metaTestCase.expectedNumberOfParams = 9)
          testSuite.testCase(testCaseParams[0], testCaseParams[1], testCaseParams[2], testCaseParams[3], testCaseParams[4], testCaseParams[5], testCaseParams[6], testCaseParams[7], testCaseParams[8])
        else if (metaTestCase.expectedNumberOfParams = 10)
          testSuite.testCase(testCaseParams[0], testCaseParams[1], testCaseParams[2], testCaseParams[3], testCaseParams[4], testCaseParams[5], testCaseParams[6], testCaseParams[7], testCaseParams[8], testCaseParams[9])
        else if (metaTestCase.expectedNumberOfParams = 11)
          testSuite.testCase(testCaseParams[0], testCaseParams[1], testCaseParams[2], testCaseParams[3], testCaseParams[4], testCaseParams[5], testCaseParams[6], testCaseParams[7], testCaseParams[8], testCaseParams[9], testCaseParams[10])
        else if (metaTestCase.expectedNumberOfParams = 12)
          testSuite.testCase(testCaseParams[0], testCaseParams[1], testCaseParams[2], testCaseParams[3], testCaseParams[4], testCaseParams[5], testCaseParams[6], testCaseParams[7], testCaseParams[8], testCaseParams[9], testCaseParams[10], testCaseParams[11])
        else if (metaTestCase.expectedNumberOfParams > 12)
          testSuite.fail("Test case had more than 12 params. Max of 12 params is supported")
        end if
        metaTestCase.time = testCaseTimer.totalMilliseconds()
      else
        testCaseTimer.mark()
        testSuite.testCase()
        metaTestCase.time = testCaseTimer.totalMilliseconds()
      end if
    else
      testSuite.Fail("Could not parse args for test ")
    end if
    if testSuite.isAutoAssertingMocks = true
      testSuite.AssertMocks()
      testSuite.CleanMocks()
      testSuite.CleanStubs()
    end if
    runResult = testSuite.currentResult.GetResult()
    if runResult <> ""
      testStatObj.Result = "Fail"
      testStatObj.Error.Code = 1
      testStatObj.Error.Message = runResult
    else
      testStatObj.Result = "Success"
    end if
    testStatObj.Time = testTimer.TotalMilliseconds()
  rbs_stats_AppendTestStatistic(suiteStatObj, testStatObj)
    if  rbs_cmn_IsFunction(testSuite.afterEach)
      testSuite.afterEach()
    end if
    if testStatObj.Result <> "Success"
      totalStatObj.testRunHasFailures = true
    end if
    if testStatObj.Result = "Fail" and config.failFast = true
      exit for
    end if
    skipTestCase:
  end for
  suiteStatObj.metaTestSuite = metaTestSuite
  rbs_stats_AppendSuiteStatistic(totalStatObj, suiteStatObj)
end sub
 sub Rooibos_TestRunner_SendHomeKeypress()
  ut = CreateObject("roUrlTransfer")
  ut.SetUrl("http://localhost:8060/keypress/Home")
  ut.PostFromString("")
end sub
function Rooibos_TestRunner_RunNodeTests(args) as object
  ? " RUNNING NODE TESTS"
  totalStatObj =  rbs_stats_CreateTotalStatistic()
  m.RunItGroups(args.metaTestSuite, totalStatObj, args.testUtilsDecoratorMethodName, args.config, args.runtimeConfig, m)
  return totalStatObj
end function
function Rooibos_TestRunner_CreateTestNode(nodeType) as object
  node = createObject("roSGNode", nodeType)
  if (type(node) = "roSGNode" and node.subType() = nodeType)
    m.top.AppendChild(node)
    return node
  else
    ? " Error creating test node of type " ; nodeType
    return invalid
  end if
end function
      function __TestRunner_builder()
      instance = {}
      TestRunner_instance = {
        __className: "TestRunner"
        run: Rooibos_TestRunner_run
        RunItGroups: Rooibos_TestRunner_RunItGroups
        RunTestCases: Rooibos_TestRunner_RunTestCases
        SendHomeKeypress: Rooibos_TestRunner_SendHomeKeypress
        RunNodeTests: Rooibos_TestRunner_RunNodeTests
        CreateTestNode: Rooibos_TestRunner_CreateTestNode
         __TestRunner: Rooibos_TestRunner_new
      }
      instance.append(TestRunner_instance)
      return instance
      end function
      function TestRunner(args = {})
        instance = __TestRunner_builder()
        instance.__TestRunner(args)
        return instance
      end function
 function RBS_UTR_UnitTestResult_Reset() as void
  m.isFail = false
  m.failedMockLineNumber = -1
  m.messages = []
end function
 function RBS_UTR_UnitTestResult_AddResult(message as string) as string
  if (message <> "")
    m.messages.push(message)
    if (not m.isFail)
      m.failedAssertIndex = m.currentAssertIndex
    end if
    m.isFail = true
  end if
  m.currentAssertIndex++
  return message
end function
 function RBS_UTR_UnitTestResult_AddMockResult(lineNumber, message as string) as string
  if (message <> "")
    m.messages.push(message)
    if (not m.isFail)
      m.failedMockLineNumber = lineNumber
    end if
    m.isFail = true
  end if
  return message
end function
 function RBS_UTR_UnitTestResult_GetResult() as string
  if (m.isFail)
    msg = m.messages.peek()
    if (msg <> invalid)
      return msg
    else
      return "unknown test failure"
    end if
  else
    return ""
  end if
end function
      function __UnitTestResult_builder()
      instance = {}
      UnitTestResult_instance = {
        __className: "UnitTestResult"
        Reset: RBS_UTR_UnitTestResult_Reset
        AddResult: RBS_UTR_UnitTestResult_AddResult
        AddMockResult: RBS_UTR_UnitTestResult_AddMockResult
        GetResult: RBS_UTR_UnitTestResult_GetResult
        messages: []
        isFail: false
        currentAssertIndex: 0
        failedAssertIndex: 0
        failedMockLineNumber: -1
         __UnitTestResult: RBS_UTR_UnitTestResult_new_
      }
      instance.append(UnitTestResult_instance)
      return instance
      end function
      function UnitTestResult()
        instance = __UnitTestResult_builder()
        instance.__UnitTestResult()
        return instance
      end function
      function RBS_UTR_UnitTestResult_new_()
      end function