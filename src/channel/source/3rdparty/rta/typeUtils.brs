' Taken from RTA_common.brs
' https://github.com/triwav/roku-test-automation/blob/master/device/components/RTA_common.brs

' /**
' * @description Checks if the supplied value is a valid Integer type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
function isInteger(value as Dynamic) as Boolean
	valueType = type(value)
	return (valueType = "Integer") OR (valueType = "roInt") OR (valueType = "roInteger") OR (valueType = "LongInteger")
end function

' /**
' * @description Checks if the supplied value is a valid Float type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
function isFloat(value as Dynamic) as Boolean
	valueType = type(value)
	return (valueType = "Float") OR (valueType = "roFloat")
end function

' /**
' * @description Checks if the supplied value is a valid Double type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
function isDouble(value as Dynamic) as Boolean
	valueType = type(value)
	return (valueType = "Double") OR (valueType = "roDouble") OR (valueType = "roIntrinsicDouble")
end function

' /**
' * @description Checks if the supplied value is a valid number type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
function isNumber(obj as Dynamic) as Boolean
	if isInteger(obj) then return true
	if isFloat(obj) then return true
	if isDouble(obj) then return true
	return false
end function

' /**
' * @description Checks if the supplied value is a valid String type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
function isString(value as Dynamic) as Boolean
	valueType = type(value)
	return (valueType = "String") OR (valueType = "roString")
end function

' /**
' * @description Checks if the supplied value is a valid AssociativeArray type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
function isAA(value as Dynamic) as Boolean
	return type(value) = "roAssociativeArray"
end function

' /**
' * @description Checks if the supplied value is a valid Boolean type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
function isBoolean(value as Dynamic) as Boolean
	valueType = type(value)
	return (valueType = "Boolean") OR (valueType = "roBoolean")
end function

' /**
' * @description Checks if the supplied value is a valid Function type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
function isFunction(value as Dynamic) as Boolean
	valueType = type(value)
	return (valueType = "roFunction") OR (valueType = "Function")
end function

' /**
' * @description Checks if the supplied value is a valid Node type
' * @param {Dynamic} value The variable to be checked
' * @return {Boolean} Results of the check
' */
function isNode(value as Dynamic) as Boolean
	return type(value) = "roSGNode"
end function

' /**
' * @description Gets node subtype in a safe manor that will return an empty string if not a node
' * @param {Dynamic} value The variable to get subtype for
' * @return {String} Subtype if node or empty string if not
' */
function getNodeSubtype(value as Dynamic) as String
	if isNode(value) = true then
		return value.subtype()
	end if
	return ""
end function
