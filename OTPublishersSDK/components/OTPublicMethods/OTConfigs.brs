Function updateOTConfigs(OT_Data)
  _OT_Data = m.global.OT_Data
  if OT_Data <> invalid
    if OT_Data.fonts <> invalid
      _OT_Data["fonts"] = getdefaultFont(OT_Data)
      _OT_Data["multiStyleFonts"] = getdefaultMultiStyleFont(OT_Data)
    end if
  end if
  m.global.OT_Data = _OT_Data
  return _OT_Data
End Function

Function getdefaultFont(OT_Data)
  return {
    "title": m.node.font(OT_Data.fonts.bold, OT_Data.fontSize.large),
    "heading": m.node.font(OT_Data.fonts.bold, OT_Data.fontSize.medium)
    "subHeading": m.node.font(OT_Data.fonts.bold, OT_Data.fontSize.small)
    "description": m.node.font(OT_Data.fonts.regular, OT_Data.fontSize.smallest),
    "boldDescription": m.node.font(OT_Data.fonts.bold, OT_Data.fontSize.smallest),
    "smallDescription": m.node.font(OT_Data.fonts.regular, OT_Data.fontSize.smallest),
  }
End Function

Function getdefaultMultiStyleFont(OT_Data)
  return {
    "description": {
      fontSize: OT_Data.fontSize.smallest,
      fontUri: OT_Data.fonts.regular
    },
    "boldDescription": {
      fontSize: OT_Data.fontSize.smallest,
      fontUri: OT_Data.fonts.bold
    }
  }
End Function