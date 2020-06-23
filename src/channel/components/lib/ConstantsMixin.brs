' make sure constants is set in the case that m.global is not immediately available
Function getConstantsFromGlobal()
  constants = invalid
  while constants = invalid
    if m.global <> invalid and m.global.constants <> invalid
      constants = m.global.constants
    end if
  end while
  return constants
End Function