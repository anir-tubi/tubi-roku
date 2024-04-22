'//TypographyMixin.brs
'//This file depends on the following files. They need to be imported by all files that make reference to any functions within this file:
'//<script type="text/brightscript" uri="pkg:/components/lib/GlobalMixin.brs" />
'//<script type="text/brightscript" uri="pkg:/source/lib/Log.brs" />
'//::TODO::typography - the following files need to be imported only when the typography feature is part of an experiment
'//<script type="text/brightscript" uri="pkg:/components/lib/ExperimentMixin.brs" />
'//<script type="text/brightscript" uri="pkg:/source/lib/TubiExperiments.brs" />

Function getTypographyConstants()
  constants = {}

  '//The gulp install command will look thru the JSON file (typography.tokens.json),
  '//and generate associative arrays to replace the following string values.
  '//::NOTE:: See the ReadMe on how to update the JSON.
  displayLarge = "TYPOGRAPHY_displayLarge_TYPOGRAPHY"
  displayMedium = "TYPOGRAPHY_displayMedium_TYPOGRAPHY"
  headerLarge = "TYPOGRAPHY_headerLarge_TYPOGRAPHY"
  headerMedium = "TYPOGRAPHY_headerMedium_TYPOGRAPHY"
  headerSmall = "TYPOGRAPHY_headerSmall_TYPOGRAPHY"
  subheaderLarge = "TYPOGRAPHY_subheaderLarge_TYPOGRAPHY"
  subheaderMedium = "TYPOGRAPHY_subheaderMedium_TYPOGRAPHY"
  subheaderSmall = "TYPOGRAPHY_subheaderSmall_TYPOGRAPHY"
  bodyLargeStrong = "TYPOGRAPHY_bodyLargeStrong_TYPOGRAPHY"
  bodyLarge = "TYPOGRAPHY_bodyLarge_TYPOGRAPHY"
  bodyMediumStrong = "TYPOGRAPHY_bodyMediumStrong_TYPOGRAPHY"
  bodyMedium = "TYPOGRAPHY_bodyMedium_TYPOGRAPHY"
  bodySmall = "TYPOGRAPHY_bodySmall_TYPOGRAPHY"
  bodySmallStrong = "TYPOGRAPHY_bodySmallStrong_TYPOGRAPHY"
  bodyExtraSmall = "TYPOGRAPHY_bodyExtraSmall_TYPOGRAPHY"
  bodyExtraSmallStrong = "TYPOGRAPHY_bodyExtraSmallStrong_TYPOGRAPHY"

  constants.ids = {}
  constants.ids.displayLarge = "displayLarge"
  constants.ids.displayMedium = "displayMedium"
  constants.ids.headerLarge = "headerLarge"
  constants.ids.headerMedium = "headerMedium"
  constants.ids.headerSmall = "headerSmall"
  constants.ids.subheaderLarge = "subheaderLarge"
  constants.ids.subheaderMedium = "subheaderMedium"
  constants.ids.subheaderSmall = "subheaderSmall"
  constants.ids.bodyLargeStrong = "bodyLargeStrong"
  constants.ids.bodyLarge = "bodyLarge"
  constants.ids.bodyMediumStrong = "bodyMediumStrong"
  constants.ids.bodyMedium = "bodyMedium"
  constants.ids.bodySmall = "bodySmall"
  constants.ids.bodySmallStrong = "bodySmallStrong"
  constants.ids.bodyExtraSmall = "bodyExtraSmall"
  constants.ids.bodyExtraSmallStrong = "bodyExtraSmallStrong"

  constants.typographyAA = {}
  constants.typographyAA[constants.ids.displayLarge] = displayLarge
  constants.typographyAA[constants.ids.displayMedium] = displayMedium
  constants.typographyAA[constants.ids.headerLarge] = headerLarge
  constants.typographyAA[constants.ids.headerMedium] = headerMedium
  constants.typographyAA[constants.ids.headerSmall] = headerSmall
  constants.typographyAA[constants.ids.subheaderLarge] = subheaderLarge
  constants.typographyAA[constants.ids.subheaderMedium] = subheaderMedium
  constants.typographyAA[constants.ids.subheaderSmall] = subheaderSmall
  constants.typographyAA[constants.ids.bodyLargeStrong] = bodyLargeStrong
  constants.typographyAA[constants.ids.bodyLarge] = bodyLarge
  constants.typographyAA[constants.ids.bodyMediumStrong] = bodyMediumStrong
  constants.typographyAA[constants.ids.bodyMedium] = bodyMedium
  constants.typographyAA[constants.ids.bodySmall] = bodySmall
  constants.typographyAA[constants.ids.bodySmallStrong] = bodySmallStrong
  constants.typographyAA[constants.ids.bodyExtraSmall] = bodyExtraSmall
  constants.typographyAA[constants.ids.bodyExtraSmallStrong] = bodyExtraSmallStrong
  return constants
End Function


'Set the typography (font size, font file, etc) of the passed label node
'@param labelNode, Node: The Label Node that its properties will be set based on the ID passed
'@param typographyId, String: The ID that will determine the properties of the label node.
'     The value of this ID should be one of the IDs available in this file: i.e. getTypographyConstants().ids.headerLarge
Function setTypographyOfLabel(labelNode, typographyId)
  constants = getTypographyConstants()

  if typographyId <> invalid AND labelNode <> invalid
    aaTypography = constants.typographyAA[typographyId]
    if aaTypography <> invalid
      sFontFile = getTypographyFontFile(aaTypography)
      nFontSize = getTypographyFontSize(aaTypography)

      nLineSpacing = 0
      if aaTypography.lineHeight <> invalid AND aaTypography.lineHeight > 0
        nLineSpacing = aaTypography.lineHeight - nFontSize
      end if

      '//set properties depending on the label mode type
      nodeType = type(labelNode)
      if nodeType = "roAssociativeArray" OR labelNode.subType() = "TextIcon" OR labelNode.subType() = "SimpleLabel"
        labelNode.fontUri = sFontFile
        labelNode.fontSize = nFontSize
      else if labelNode.subType() = "Label" OR labelNode.subType() = "ScrollableText"
        if nLineSpacing >= 0
          labelNode.lineSpacing = nLineSpacing
        end if

        fontNode = labelNode.font
        if fontNode <> invalid AND fontNode.subType() = "Font"
          fontNode.uri = sFontFile
          fontNode.size = nFontSize
        end if
      end if

    else
      tubilog("TypographyMixin, setTypographyOfLabel(): WARNING: Associative array associated with passed Typography string ID does not exist")
    end if
  else
    tubilog("TypographyMixin, setTypographyOfLabel(): WARNING: passed typographyId or label does not exist")
  end if
End Function


'Set the typography (font size, font file, etc) of the passed multistyle label node
'
'@param typographyId, String: The ID that will determine the properties of the label node.
'     The value of this ID should be one of the IDs available in this file: i.e. getTypographyConstants().ids.headerLarge
'@param color, String: A color value as taken from constants.ui.themes
'
'@returns assocArray: an AA with the following format:
'
'  {
'    "fontSize": 36
'    "fontUri": "pkg:/fonts/vSHandprinted.otf"
'    "color": "#FF0000FF"
'  }
Function getTypographyOfMultiStyleLabel(typographyId, color = "#FFFFFFFF")
  labelStyle = {
    "fontSize": 0
    "fontUri": ""
    "color": ""
  }

  constants = getTypographyConstants()

  if typographyId <> invalid
    typographyStyle = constants.typographyAA[typographyId]

    if typographyStyle <> invalid
      labelStyle.fontUri = getTypographyFontFile(typographyStyle)
      labelStyle.fontSize = getTypographyFontSize(typographyStyle)
    end if

    labelStyle.color = color
  end if

  return labelStyle
End Function


'@typographyStyle: assocArray, a style comprised of keys like fontFamily, fontWeight
'                              etc. as defined in the design team's JSON file.
'
'@returns: string, a font file url like "pkg:/fonts/Inter-Medium.ttf" based on
'                  typography style
Function getTypographyFontFile(typographyStyle)
  fontFile = "pkg:/fonts/Inter-Medium.ttf"
  if typographyStyle.fontFamily = "TubiStans"
    fontFile = "pkg:/fonts/TubiStans.ttf"
  else if typographyStyle.fontWeight = 700
    fontFile = "pkg:/fonts/Inter-Bold.ttf"
  end if

  return fontFile
End Function


'@typographyStyle: assocArray, a style comprised of keys like fontFamily, fontWeight
'                              etc. as defined in the design team's JSON file.
'
'@returns: integer, the font size corresponding to the typography style
Function getTypographyFontSize(typographyStyle)
  fontSize = 16
  if typographyStyle.fontSize <> invalid AND typographyStyle.fontSize > 0
    fontSize = typographyStyle.fontSize
  end if

  return fontSize
End Function