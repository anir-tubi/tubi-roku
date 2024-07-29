function logUtil()
    logger = {
        set: function(errortype as string, tag as string, msg as dynamic, addMsg = "" as dynamic)
           ' date = CreateObject("roDateTime").ToISOString()
            Print " ["; errortype;".";tag; "] |"; msg; addMsg
        end function
    }
    return logger
end function