' padding [left, top, bottom, right]
Function style()
  screenSize = m.global.screenSize
  return {
    gridButtonAdjustment: 22 * screenSize.scale
    containerPadding: 110 * screenSize.scale,
    containerPaddingTop: 55 * screenSize.scale,
    headerBottomPadding: 50 * screenSize.scale,
    footerTopPadding: 30 * screenSize.scale,
    buttonspacing: 30 * screenSize.scale,
    buttonPadding: [15 * screenSize.scale, 20 * screenSize.scale, 20 * screenSize.scale, 15 * screenSize.scale],

    buttonItemSpacings: [15 * screenSize.scale]
    bimageTranslation: [0, 5 * screenSize.scale],
    qrcode: {
      width: 380 * screenSize.scale,
      height: 380 * screenSize.scale
      translation: [40 * screenSize.scale, 0]
    },
    qrcodeUri: {
      size: 400
    },
    logo: {
      height: 100 * screenSize.scale
      width: 250 * screenSize.scale
    },
    scrollThumb: {
      width: 10 * screenSize.scale
      padding: 10 * screenSize.scale
    },
    descriptionScrollRec: {
      itemSpacings: 50 * screenSize.scale
    },
    bannerHeading: {
      itemSpacings: 30 * screenSize.scale
    }
    detailScreen: {
      padding: 55 * screenSize.scale
      itemSpacings: 15 * screenSize.scale
      paddinglabel: 30 * screenSize.scale
    }
    setPadding: Function(node, padding, width, height = invalid)
      node.translation = [padding[0], padding[1]]
      if height <> invalid then node.height = height - padding[1] - padding[2]
      node.width = width - padding[0] - padding[3]
    End Function
    opacity: "0.3",
    focusOpacity: "1",
    fonts: {
      "bold": "font:SmallestBoldSystemFont",
      "regular": "font:SmallestSystemFont",
      '"bold": "pkg:/fonts/bold.ttf",
      '"regular": "pkg:/fonts/regular.ttf",
    }
    ' SmallestSystemFont	27px
    ' SmallSystemFont	33px
    ' MediumSystemFont	36px
    ' LargeSystemFont	45px
    fontSize: {
      large: 45 * screenSize.scale
      medium: 36 * screenSize.scale
      small: 33 * screenSize.scale
      smallest: 27 * screenSize.scale
    }
    rightArrow: {
      width: 25 * screenSize.scale,
      padding: 10 * screenSize.scale
    }
    button: {
      wrapSize: 5 * screenSize.scale
      itemSpacing: 15 * screenSize.scale
      arrowAdj: 10 * screenSize.scale
    }
    checkbox: {
      size: 30 * screenSize.scale
    }
    filter: {
      size: 35 * screenSize.scale
      padding: [10 * screenSize.scale, 15 * screenSize.scale]
      filterPadding: [18 * screenSize.scale, 12.5 * screenSize.scale]
    }
    backbutton: {
      size: 50 * screenSize.scale
    }
    OTHeader: {
      padding: 30 * screenSize.scale
    }
    menu: {
      padding: 30 * screenSize.scale
    }
    listItem: {
      padding: 10 * screenSize.scale
      bulletWidth: 15 * screenSize.scale
    }
    divider: {
      height: 2 * screenSize.scale
    }
  }
End Function