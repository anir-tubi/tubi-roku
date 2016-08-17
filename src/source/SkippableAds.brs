function createSkippableAd (canvas, utils)
    mode = utils.deviceInfo.displayMode
    res = "480px/"
    if mode = "720p"
      res = "720px/"
    end if

    rect = canvas.GetCanvasRect()
    o = {
        canvas: canvas
        textcolor: "#CCCCCC"
        fonts :     CreateObject("roFontRegistry")
        skipTime: 5
        time: 0
      }
    if mode = "720p"
      o.layout = {
         full: rect
          counter: { x: 947, y: 627, w: 250, h: 60 }
        }
      o.counterFont = o.fonts.get("Default", 18, 50, false)
      o.counterFont = o.fonts.get("Default", 25, 50, false)
    else
      o.layout = {
        full: rect
        counter :  { x : 512,  y : 351,  w : 40,  h : 40 }
      }
      o.counterFont = o.fonts.get("Default", 12, 50, false)
      o.counterFont = o.fonts.get("Default", 14, 50, false)
    end if

    '---------------------------
    o.setup = function ()
      m.canvas.AllowUpdates(false)
      m.canvas.Clear()
      m.canvas.SetLayer(0, [
        {
        Color: "#00000000",
        targetRect: m.layout.full
        compositionMode: "Source"
        }
      ])
      m.update(0)
      m.canvas.AllowUpdates(true)
    end function

    '---------------------------
    o.update = function (time)
      m.time = time
      list = []

      list.Push({
              Color: "#88FFFFFF",
              TargetRect: { x: m.layout.counter.x-1, y: m.layout.counter.y-1, w: m.layout.counter.w+2, h:  m.layout.counter.h+2 }
              compositionMode: "Source_over"
            })
      list.Push({
              Color: "#88000000",
              TargetRect: m.layout.counter
              compositionMode: "Source"
            })

      remaining = m.skipTime - m.time

      if remaining < 1
        list.Push({
              Text: "Press OK to skip this ad now"
              TargetRect: m.layout.counter
              TextAttrs: { halign: "HCenter", valign: "VCenter", font: m.counterFont, color: m.textcolor }
            })
       else
        list.Push({
              Text: "You may skip ad in " + remaining.tostr() + " seconds"
              TargetRect: m.layout.counter
              TextAttrs: { halign: "HCenter", valign: "VCenter", font: m.counterFont, color: m.textcolor }
            })
      end if
      m.canvas.SetLayer(1, list)
    end function

    return o

end function
