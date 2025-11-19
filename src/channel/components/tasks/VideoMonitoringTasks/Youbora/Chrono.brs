Function Chrono() as Object

  this = CreateObject("roAssociativeArray")

  this.date = CreateObject("roDateTime")

  this.startTime = invalid
  this.stopTime = invalid

  this.start = Function() as Void
    m.startTime = m.currentMillis()
    m.stopTime = invalid
  End Function

  this.stop = Function() as Integer
    m.stopTime = m.currentMillis()
    return m.getDeltaTime()
  End Function

  this.getDeltaTime = Function(stopIfNeeded = invalid) as Integer

    if m.startTime = invalid
      return -1
    end if

    if m.stopTime = invalid
      if stopIfNeeded = true
        return m.stop()
      else
        return m.currentMillis() - m.startTime
      end if
    else
      return m.stopTime - m.startTime
    end if
  End Function

  'Return the current timestamp in millis
  this.currentMillis = Function() as Longinteger
    m.date.Mark() 'Read time

    seconds& = m.date.AsSeconds() 'seconds# is long
    seconds& = seconds& * 1000

    millis& = m.date.GetMilliseconds()
    return seconds& + millis&
  End Function

  this.getStartTime = Function() as Longinteger
    return m.startTime
  End Function

  this.setStartTime = Function(newStartTime as Longinteger) as Void
    m.startTime = newStartTime
  End Function

  this.reset = Function() as Void
    m.startTime = invalid
    m.stopTime = invalid
  End Function

  return this
End Function
