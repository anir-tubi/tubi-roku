'-- Private helper methods for constructor: Drawing function modules --

' Reads this object's version field, and draws and marks all function modules.
Function _qrCode_draw_drawFunctionPatterns()
  ' Draw horizontal and vertical timing patterns
  for i = 0 to m.size - 1
    m.setFunctionModule(6, i, i mod 2 = 0)
    m.setFunctionModule(i, 6, i mod 2 = 0)
  next

  ' Draw 3 finder patterns (all corners except bottom right; overwrites some timing modules)
  m.drawFinderPattern(3, 3)
  m.drawFinderPattern(m.size - 4, 3)
  m.drawFinderPattern(3, m.size - 4)

  ' Draw numerous alignment patterns
  alignPatPos = m.getAlignmentPatternPositions()
  numAlign = alignPatPos.count()
  for i = 0 to numAlign - 1
    for j = 0 to numAlign - 1
      ' Don't draw on the three finder corners
      if (not ((i = 0) AND (j = 0) OR (i = 0) AND (j = numAlign - 1) OR (i = numAlign - 1) AND (j = 0))) then
        m.drawAlignmentPattern(alignPatPos[i], alignPatPos[j])
      end if
    next
  next

  ' Draw configuration data
  m.drawFormatBits(0) ' Dummy mask value; overwritten later in the constructor
  m.drawVersion()
End Function


' Draws two copies of the format bits (with its own error correction code)
' based on the given mask and this object's error correction level field.
Function _qrCode_draw_drawFormatBits(mask as Integer)
  ' Calculate error correction code and pack bits
  data = m.errorCorrectionLevel.formatBits << 3 OR mask ' errCorrLvl is uint2, mask is uint3
  remain = data
  for i = 0 to 9
    remain = xor((remain << 1), (remain >> 9) * &h537)
  next
  bits = xor((data << 10 OR remain), &h5412) ' uint15
  assert(bits >> 15 = 0)

  ' Draw first copy
  for i = 0 to 5
    m.setFunctionModule(8, i, getBit(bits, i))
  next
  m.setFunctionModule(8, 7, getBit(bits, 6))
  m.setFunctionModule(8, 8, getBit(bits, 7))
  m.setFunctionModule(7, 8, getBit(bits, 8))
  for i = 9 to 14
    m.setFunctionModule(14 - i, 8, getBit(bits, i))
  next

  ' Draw second copy
  for i = 0 to 7
    m.setFunctionModule(m.size - 1 - i, 8, getBit(bits, i))
  next
  for i = 8 to 14
    m.setFunctionModule(8, m.size - 15 + i, getBit(bits, i))
  next
  m.setFunctionModule(8, m.size - 8, true) ' Always dark
End Function


' Draws two copies of the version bits (with its own error correction code),
' based on this object's version field, iff 7 <= version <= 40.
Function _qrCode_draw_drawVersion()
  if (m.version < 7) then
    return false
  end if

  ' Calculate error correction code and pack bits
  remain = m.version ' version is uint6, in the range [7, 40]
  for i = 0 to 11
    remain = xor((remain << 1), (remain >> 11) * &h1F25)
  next
  bits = m.version << 12 OR remain ' uint18
  assert(bits >> 18 = 0)

  ' Draw two copies
  for i = 0 to 17
    color = getBit(bits, i)
    a = m.size - 11 + i mod 3
    b = floor(i / 3)
    m.setFunctionModule(a, b, color)
    m.setFunctionModule(b, a, color)
  next
End Function


' Draws a 9*9 finder pattern including the border separator,
' with the center module at (x, y). Modules can be out of bounds.
Function _qrCode_draw_drawFinderPattern(x as Integer, y as Integer)
  for dy = -4 to 4
    for dx = -4 to 4
      dist = max(abs(dx), abs(dy)) ' Chebyshev/infinity norm
      xx = x + dx
      yy = y + dy
      if ((0 <= xx) AND (xx < m.size) AND (0 <= yy) AND (yy < m.size)) then
        m.setFunctionModule(xx, yy, (dist <> 2) AND (dist <> 4))
      end if
    next
  next
End Function


' Draws a 5*5 alignment pattern, with the center module
' at (x, y). All modules must be in bounds.
Function _qrCode_draw_drawAlignmentPattern(x as Integer, y as Integer)
  for dy = -2 to 2
    for dx = -2 to 2
      m.setFunctionModule(x + dx, y + dy, max(abs(dx), abs(dy)) <> 1)
    next
  next
End Function


' Sets the color of a module and marks it as a function module.
' Only used by the constructor. Coordinates must be in bounds.
Function _qrCode_draw_setFunctionModule(x as Integer, y as Integer, isDark as Boolean)
  m.modules[y][x] = iif(isDark, 1, 0)
  m.isFunction[y][x] = true
End Function
