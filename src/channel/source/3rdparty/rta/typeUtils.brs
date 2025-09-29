' Taken from RTA_common.brs
' https://github.com/triwav/roku-test-automation/blob/master/device/components/RTA_common.brs

' /**
' * @description Checks if the supplied value is a valid Integer type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
Function isInteger(value as Dynamic) as Boolean
  valueType = type(value)
  return (valueType = "Integer") OR (valueType = "roInt") OR (valueType = "roInteger") OR (valueType = "LongInteger")
End Function

' /**
' * @description Checks if the supplied value is a valid Float type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
Function isFloat(value as Dynamic) as Boolean
  valueType = type(value)
  return (valueType = "Float") OR (valueType = "roFloat")
End Function

' /**
' * @description Checks if the supplied value is a valid Double type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
Function isDouble(value as Dynamic) as Boolean
  valueType = type(value)
  return (valueType = "Double") OR (valueType = "roDouble") OR (valueType = "roIntrinsicDouble")
End Function

' /**
' * @description Checks if the supplied value is a valid number type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
Function isNumber(obj as Dynamic) as Boolean
  if isInteger(obj) then return true
  if isFloat(obj) then return true
  if isDouble(obj) then return true
  return false
End Function

' /**
' * @description Checks if the supplied value is a valid String type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
Function isString(value as Dynamic) as Boolean
  valueType = type(value)
  return (valueType = "String") OR (valueType = "roString")
End Function

' /**
' * @description Checks if the supplied value is a valid AssociativeArray type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
Function isAA(value as Dynamic) as Boolean
  return type(value) = "roAssociativeArray"
End Function


' /**
' * @description Checks if the supplied value is a valid Array type and not empty
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
Function isNonEmptyAA(value as Dynamic) as Boolean
  return (isAA(value) AND not value.keys().isEmpty())
End Function


' /**
' * @description Checks if the supplied value is a valid Boolean type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
Function isBoolean(value as Dynamic) as Boolean
  valueType = type(value)
  return (valueType = "Boolean") OR (valueType = "roBoolean")
End Function

' /**
' * @description Checks if the supplied value is a valid Function type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
Function isFunction(value as Dynamic) as Boolean
  valueType = type(value)
  return (valueType = "roFunction") OR (valueType = "Function")
End Function

' /**
' * @description Checks if the supplied value is a valid Array type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
Function isArray(value as Dynamic) as Boolean
  return type(value) = "roArray"
End Function

' /**
' * @description Checks if the supplied value is a valid Array type and not empty
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
Function isNonEmptyArray(value as Dynamic) as Boolean
  return (isArray(value) AND not value.isEmpty())
End Function

' * @description Checks if the supplied value is a valid Node type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
Function isNode(value as Dynamic) as Boolean
  return type(value) = "roSGNode"
End Function

' /**
' * @description Gets node subtype in a safe manor that will return an empty string if not a node
' * @param {Dynamic} value The variable to get subtype for
' * @return {String} Subtype if node or empty string if not
' */
Function getNodeSubtype(value as Dynamic) as String
  if isNode(value) = true then
    return value.subtype()
  end if
  return ""
End Function
