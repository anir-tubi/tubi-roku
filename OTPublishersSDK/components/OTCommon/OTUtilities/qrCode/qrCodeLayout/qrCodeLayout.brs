function init()
    m.qrCodeLayoutGroup = m.top.findNode("qrCodeLayoutGroup")
    m.qrCodeHeader = m.top.findNode("qrCodeHeader")
    m.qrCode = m.top.findNode("qrCode")
end function

function onQrCodeData()
    m.qrCodeLayoutGroup.scale = [0, 0]
    m.qrCodeLayoutGroup.visible = m.top.show
    if m.top.show
        m.qrCodeLayoutGroup.scale = [1, 1]
        m.qrCode.lightColor = m.top.qrCodeLightColor
        m.qrCode.darkColor = m.top.qrCodeDarkColor
        m.qrCodeHeader.text = m.top.headerText
        m.qrCodeHeader.color = m.top.headerColor
        m.qrCode.width = 400
        m.qrCode.height = 400
        m.qrCodeHeader.width = m.qrCode.width
        m.qrCodeHeader.height = m.qrCodeHeader.boundingRect().height + 20
        m.qrCode.border = 0
        m.qrCode.text = m.top.uri
    end if
end function