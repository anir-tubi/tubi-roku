'-- Static factory functions (high level) --

' Returns a QR Code representing the given Unicode text string at the given error correction level.
' As a conservative upper bound, this function is guaranteed to succeed for strings that have 738 or fewer
' Unicode code points (not UTF-16 code units) if the low error correction level is used. The smallest possible
' QR Code version is automatically chosen for the output. The ECC level of the result may be higher than the
' ecl argument if it can be done without increasing the version.
Function _qrCode_high_encodeText(text as String, ecl as Object) as Object
  segs = m.QrSegment.makeSegments(text)
  return m.encodeSegments(segs, ecl)
End Function

' Returns a QR Code representing the given binary data at the given error correction level.
' This function always encodes using the binary segment mode, not any text mode. The maximum number of
' bytes allowed is 2953. The smallest possible QR Code version is automatically chosen for the output.
' The ECC level of the result may be higher than the ecl argument if it can be done without increasing the version.
Function _qrCode_high_encodeBinary(data as Object, ecl as Object) as Object
  seg = m.QrSegment.makeBytes(data)
  return m.encodeSegments([seg], ecl)
End Function