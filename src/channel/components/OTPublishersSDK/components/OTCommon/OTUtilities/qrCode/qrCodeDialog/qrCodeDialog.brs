function init()
    m.qrCodeLayout = m.top.findNode("qrCodeLayout")
    m.paddingH = 55
    m.paddingW = 90
end function

sub printFocusButton()
    print "m.buttonArea button ";m.top.buttons[m.top.buttonFocused];" focused"
end sub

sub printSelectedButtonAndClose()
    print "m.buttonArea button ";m.top.buttons[m.top.buttonSelected];" selected"
    m.top.close = true
end sub

sub wasClosedChanged()
    print "SimpleProgressDialog Closed"
end sub

function onQrCodeData()
    m.qrCodeLayout.show = m.top.show
    m.qrCodeLayout.qrCodeLightColor = m.top.qrCodeLightColor
    m.qrCodeLayout.qrCodeDarkColor = m.top.qrCodeDarkColor
    m.qrCodeLayout.headerText = m.top.headerText
    m.qrCodeLayout.headerColor = m.top.headerColor
    customPalette = createObject("roSGNode", "RSGPalette")
    customPalette.colors = {
        DialogBackgroundColor: m.top.qrCodeLightColor,
    }
    m.top.palette = customPalette
    m.top.translation = [-400, -400]
    m.qrCodeLayout.uri = m.top.uri
    rect = m.qrCodeLayout.boundingRect()
    m.top.width = rect.width + m.paddingW + m.paddingW
    m.top.height = rect.height + m.paddingH + m.paddingH
end function
