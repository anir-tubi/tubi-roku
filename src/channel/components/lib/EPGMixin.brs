' This function will return if a linear program is live based on the passed parameter. 
' This function requires the importation of source/lib/TimeUtils.brs
' @param program: roSGNode, EPG program node
Function isProgramLive(program)
  now = getCurrentLocalTime()
  if program <> invalid and program.startTime = 0 and program.endTime = 0 ' No programs and EPG has single element and click will play live
    return true
  else if program <> invalid and isint(program.startTime) and isint(program.endTime)
    return program.startTime <= now and program.endTime > now
  else
    return false
  end if
End Function