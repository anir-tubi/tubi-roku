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


' make sure theme is set in the case that m.global is not immediately available
' limits the number of attempts so the while loop doesn't block into perpetuity.
Function getThemeFromGlobal()
  theme = invalid
  attempts = 0
  while theme = invalid and attempts < 100
    if m.global <> invalid and m.global.theme <> invalid
      theme = m.global.theme
    end if
    attempts += 1
  end while
  return theme
End Function