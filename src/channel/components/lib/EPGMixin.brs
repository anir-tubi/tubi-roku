' This function will return if a linear program is live based on the passed parameter. 
' This function requires the importation of source/lib/TimeUtils.brs
' @param program: roSGNode, EPG program node
Function isProgramLive(program)
  now = getCurrentLocalTime()
  if program <> invalid AND program.startTime = 0 AND program.endTime = 0 ' No programs and EPG has single element and click will play live
    return true
  else if program <> invalid AND isint(program.startTime) AND isint(program.endTime)
    return program.startTime <= now AND program.endTime > now
  else
    return false
  end if
End Function