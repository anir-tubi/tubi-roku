Function logUtil()
  logger = {
    set: Function(errortype as String, tag as String, msg as Dynamic, addMsg = "" as Dynamic)
      ' date = CreateObject("roDateTime").ToISOString()
      print " ["; errortype;".";tag; "] |"; msg; addMsg
    End Function
    error: sub(e)
      try
        errortype = "error"
        tag = ""
        if e.message <> invalid then tag = e.message
        print " ["; errortype;".";tag; "] |"; FormatJson(e)
      catch e
        print FormatJson(e)
      end try
    end sub
  }
  return logger
End Function

