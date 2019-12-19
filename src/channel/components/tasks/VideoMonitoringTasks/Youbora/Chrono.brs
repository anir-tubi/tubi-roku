function Chrono() As Object

	this  = CreateObject("roAssociativeArray")

	this.date = CreateObject("roDateTime")

	this.startTime = Invalid
	this.stopTime = Invalid	

	this.start = function() as Void
		m.startTime = m.currentMillis()
		m.stopTime = Invalid
	end function

	this.stop = function() as 	Integer
		m.stopTime = m.currentMillis()
		return m.getDeltaTime()
	end function

	this.getDeltaTime = function(stopIfNeeded = Invalid) as Integer

		if m.startTime = Invalid
			return -1
		endif

		if m.stopTime = Invalid
			if stopIfNeeded = true
				return m.stop()
			else 
				return m.currentMillis() - m.startTime
			endif
		else
			return m.stopTime - m.startTime
		endif
	end function

	'Return the current timestamp in millis
	this.currentMillis = function() as LongInteger
		m.date.Mark() 'Read time

		seconds& = m.date.AsSeconds() 'seconds# is long
		seconds& = seconds& * 1000

		millis& = m.date.GetMilliseconds()
		return seconds& + millis&
	end function
	
	this.getStartTime = function() as LongInteger
       return m.startTime
    end function
    
    this.setStartTime = function(newStartTime as LongInteger) as Void
       m.startTime = newStartTime
    end function

	this.reset = function() as Void
		m.startTime = Invalid
		m.stopTime = Invalid	
	end function

	return this
end function
