'-- Private helper functions --

' Returns an ascending list of positions of alignment patterns for this version number.
' Each position is in the range [0,177), and are used on both the x and y axes.
' This could be implemented as lookup table of 40 variable-length lists of integers.
Function _qrCode_help_getAlignmentPatternPositions() as Object
  if (m.version = 1) then
    return []
  else
    numAlign = floor(m.version / 7) + 2
    stepSize = iif(m.version = 32, 26, ceil((m.version * 4 + 4) / (numAlign * 2 - 2)) * 2)
    result = [6]
    position = m.size - 7
    while(result.count() < numAlign)
      splice(result, 1, 0, [position])
      position -= stepSize
    end while
    return result
  end if
End Function


' Returns the number of data bits that can be stored in a QR Code of the given version number, after
' all function modules are excluded. This includes remainder bits, so it might not be a multiple of 8.
' The result is in the range [208, 29648]. This could be implemented as a 40-entry lookup table.
Function _qrCode_help_getNumRawDataModules(ver as Integer) as Integer
  if ((ver < m.MIN_VERSION) OR (ver > m.MAX_VERSION)) then
    throw("Version number out of range")
  end if
  result = (16 * ver + 128) * ver + 64
  if (ver >= 2) then
    numAlign = floor(ver / 7) + 2
    result -= (25 * numAlign - 10) * numAlign - 55
    if (ver >= 7) then
      result -= 36
    end if
  end if
  assert((208 <= result) AND (result <= 29648))
  return result
End Function


' Returns the number of 8-bit data (i.e. not error correction) codewords contained in any
' QR Code of the given version number and error correction level, with remainder bits discarded.
' This stateless pure function could be implemented as a (40*4)-cell lookup table.
Function _qrCode_help_getNumDataCodewords(ver as Integer, ecl as Object) as Integer
  return floor(m.getNumRawDataModules(ver) / 8) - m.ECC_CODEWORDS_PER_BLOCK[ecl.ordinal][ver] * m.NUM_ERROR_CORRECTION_BLOCKS[ecl.ordinal][ver]
End Function


' Returns a Reed-Solomon ECC generator polynomial for the given degree. This could be
' implemented as a lookup table over all possible parameter values, instead of as an algorithm.
Function _qrCode_help_reedSolomonComputeDivisor(degree as Integer) as Object
  if ((degree < 1) OR (degree > 255)) then
    throw("Degree out of range")
  end if
  ' Polynomial coefficients are stored from highest to lowest power, excluding the leading term which is always 1.
  ' For example the polynomial x^3 + 255x^2 + 8x + 93 is stored as the uint8 array [255, 8, 93].
  result = []
  for i = 0 to degree - 2
    result.push(0)
  next
  result.push(1) ' Start off with the monomial x^0

  ' Compute the product polynomial (x - r^0) * (x - r^1) * (x - r^2) * ... * (x - r^{degree-1}),
  ' and drop the highest monomial term which is always 1x^degree.
  ' Note that r = 0x02, which is a generator element of this field GF(2^8/0x11D).
  root = 1
  for i = 0 to degree - 1
    ' Multiply the current product by (x - r^i)
    for j = 0 to result.count() - 1
      result[j] = m.reedSolomonMultiply(result[j], root)
      if (j + 1 < result.count()) then
        result[j] = xor(result[j], result[j + 1])
      end if
    next
    root = m.reedSolomonMultiply(root, &h02)
  next
  return result
End Function


' Returns the Reed-Solomon error correction codeword for the given data and divisor polynomials.
Function _qrCode_help_reedSolomonComputeRemainder(data as Object, divisor as Object) as Object
  result = []
  for each _d in divisor ' Prefix d with underscore to avoid unused variable warning
    result.push(0)
  next
  for each b in data ' Polynomial division
    factor = xor(b, result.shift())
    result.push(0)
    for i = 0 to divisor.count() - 1
      coef = divisor[i]
      res = result[i]
      result[i] = xor(res, m.reedSolomonMultiply(coef, factor))
    next
  next
  return result
End Function


' Returns the product of the two given field elements modulo GF(2^8/0x11D). The arguments and result
' are unsigned 8-bit integers. This could be implemented as a lookup table of 256*256 entries of uint8.
Function _qrCode_help_reedSolomonMultiply(x as Integer, y as Integer) as Integer
  if ((x >> 8 <> 0) OR (y >> 8 <> 0)) then
    throw("Byte out of range")
  end if
  ' Russian peasant multiplication
  z = 0
  for i = 7 to 0 step -1
    z = xor((z << 1), ((z >> 7) * &h11D))
    z = xor(z, ((y >> i) AND 1) * x)
  next
  assert(z >> 8 = 0)
  return z
End Function


' Can only be called immediately after a light run is added, and
' returns either 0, 1, or 2. A helper function for getPenaltyScore().
Function _qrCode_help_finderPenaltyCountPatterns(runHistory as Object) as Integer
  n = runHistory[1]
  assert(n <= m.size * 3)
  core = iif((n > 0) AND (runHistory[2] = n) AND (runHistory[3] = n * 3) AND (runHistory[4] = n) AND (runHistory[5] = n), 1, 0)
  return (core AND iif(runHistory[0] >= n * 4, 1, 0) AND iif(runHistory[6] >= n, 1, 0)) + (core AND iif(runHistory[6] >= n * 4, 1, 0) AND iif(runHistory[0] >= n, 1, 0))
End Function


' Must be called at the end of a line (row or column) of modules. A helper function for getPenaltyScore().
Function _qrCode_help_finderPenaltyTerminateAndCount(currentRunColor as Boolean, currentRunLength as Integer, runHistory as Object) as Integer
  if (currentRunColor) then ' Terminate dark run
    m.finderPenaltyAddHistory(currentRunLength, runHistory)
    currentRunLength = 0
  end if
  currentRunLength += m.size ' Add light border to final run
  m.finderPenaltyAddHistory(currentRunLength, runHistory)
  return m.finderPenaltyCountPatterns(runHistory)
End Function


' Pushes the given value to the front and drops the last value. A helper function for getPenaltyScore().
Function _qrCode_help_finderPenaltyAddHistory(currentRunLength as Integer, runHistory as Object)
  if (runHistory[0] = 0)
    currentRunLength += m.size ' Add light border to initial run
  end if
  runHistory.pop()
  runHistory.unshift(currentRunLength)
End Function
