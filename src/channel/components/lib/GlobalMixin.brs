' make sure constants is set in the case that m.global is not immediately available
' limits the number of attempts so the while loop doesn't block into perpetuity.
Function getConstantsFromGlobal()
  constants = invalid
  attempts = 0
  while constants = invalid and attempts < 100
    globalAA = m.global
    if globalAA <> invalid and globalAA.constants <> invalid
      constants = globalAA.constants
    end if
    attempts += 1
  end while
  return constants
End Function


' make sure theme is set in the case that m.global is not immediately available
' limits the number of attempts so the while loop doesn't block into perpetuity.
Function getThemeFromGlobal()
  theme = invalid
  attempts = 0
  while theme = invalid and attempts < 100
    globalAA = m.global
    if globalAA <> invalid and globalAA.constants <> invalid
      theme = globalAA.theme
    end if
    attempts += 1
  end while
  return theme
End Function
