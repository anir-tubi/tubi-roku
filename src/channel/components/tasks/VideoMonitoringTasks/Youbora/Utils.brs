function currentMillis() as LongInteger

	date = CreateObject("roDateTime")
	seconds& = date.AsSeconds() 'seconds is long
	seconds& = seconds& * 1000

	millis& = date.GetMilliseconds()

	return seconds& + millis&

end function

sub YouboraLog(message as String)

	if m.global.YouboraLogActive = true
		print message
	endif
end sub