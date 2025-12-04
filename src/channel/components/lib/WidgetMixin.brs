' WidgetMixin.brs
' Provides reusable widget creation functions for common UI elements
'
' Usage:
' Include this file in your component XML:
' <script type="text/brightscript" uri="pkg:/components/lib/WidgetMixin.brs" />


' Applies common configuration properties to any node
' @param node - roSGNode, the node to configure
' @param config - AssocArray with optional properties:
'   - id: String, node ID
'   - width: Integer/Float, node width
'   - height: Integer/Float, node height
'   - translation: Array, [x, y] position
Function applyCommonConfig(node as Object, config as Object) as Void
  if config = invalid then return

  if config.id <> invalid then node.id = config.id
  if config.width <> invalid then node.width = config.width
  if config.height <> invalid then node.height = config.height
  if config.translation <> invalid then node.translation = config.translation
End Function


' Creates a label with configurable properties
' @param text - String, label text content
' @param config - AssocArray with optional properties:
'   - id: String, node ID (default: not set)
'   - width: Integer, label width (default: not set)
'   - height: Integer, label height (default: not set)
'   - translation: Array, [x, y] position (default: not set)
'   - color: String, text color (default: not set)
'   - typographyFont: Object, typography font to apply (default: invalid)
'   - horizAlign: String, horizontal alignment (default: not set)
'   - vertAlign: String, vertical alignment (default: not set)
'   - wrap: Boolean, whether to wrap text (default: not set)
' @return roSGNode - Configured Label node
Function createLabel(text, config = invalid) as Object
  label = CreateObject("roSGNode", "Label")
  label.text = text

  ' Apply common config properties
  applyCommonConfig(label, config)

  ' Apply label-specific configuration if provided
  if config <> invalid
    if config.color <> invalid then label.color = config.color
    if config.horizAlign <> invalid then label.horizAlign = config.horizAlign
    if config.vertAlign <> invalid then label.vertAlign = config.vertAlign
    if config.wrap <> invalid then label.wrap = config.wrap

    ' Apply typography if provided
    if config.typographyFont <> invalid
      setTypographyOfLabel(label, config.typographyFont)
    end if
  end if

  return label
End Function


' Creates a poster with configurable properties
' @param uri - String, poster image URI
' @param config - AssocArray with optional properties:
'   - id: String, node ID (default: not set)
'   - width: Integer, poster width (default: not set)
'   - height: Integer, poster height (default: not set)
'   - translation: Array, [x, y] position (default: not set)
'   - loadDisplayMode: String, load display mode (default: not set)
'   - loadWidth: Integer, load width (default: not set)
'   - loadHeight: Integer, load height (default: not set)
' @return roSGNode - Configured Poster node
Function createPoster(uri, config = invalid) as Object
  poster = CreateObject("roSGNode", "Poster")

  ' Apply common config properties
  applyCommonConfig(poster, config)

  ' Apply poster-specific configuration if provided
  if config <> invalid
    if config.loadDisplayMode <> invalid then poster.loadDisplayMode = config.loadDisplayMode
    if config.loadWidth <> invalid then poster.loadWidth = config.loadWidth
    if config.loadHeight <> invalid then poster.loadHeight = config.loadHeight
  end if

  poster.uri = uri

  return poster
End Function


' Creates a layout group with configurable properties and children
' @param layoutDirection - String, "horiz" or "vert"
' @param config - AssocArray with required and optional properties:
'   - itemSpacings: Array, spacing between items (required)
'   - children: Array, child nodes to append (default: invalid)
'   - id: String, node identifier for testing (default: invalid)
'   - width: Integer, layout group width (default: not set)
'   - height: Integer, layout group height (default: not set)
'   - translation: Array, [x, y] position (default: not set)
'   - horizAlign: String, horizontal alignment (default: invalid)
'   - vertAlign: String, vertical alignment (default: invalid)
' @return roSGNode - Configured LayoutGroup node with children
Function createLayoutGroup(layoutDirection as String, config = invalid as Object) as Object
  layoutGroup = CreateObject("roSGNode", "LayoutGroup")
  layoutGroup.layoutDirection = layoutDirection

  ' Apply common config properties
  applyCommonConfig(layoutGroup, config)

  ' Apply layout-specific configuration if provided
  if config <> invalid
    if config.itemSpacings <> invalid then layoutGroup.itemSpacings = config.itemSpacings
    if config.horizAlign <> invalid then layoutGroup.horizAlign = config.horizAlign
    if config.vertAlign <> invalid then layoutGroup.vertAlign = config.vertAlign

    ' Append children if provided
    if isNonEmptyArray(config.children)
      layoutGroup.appendChildren(config.children)
    end if
  end if

  return layoutGroup
End Function


' Creates a rating descriptor badge with 9-patch background
' Used for displaying content descriptors like D (Sexual dialogue), L (Language), S (Sexual content), V (Violence), FV (Fantasy violence)
' @param code - String, the rating code text to display (e.g., "D", "L", "S", "V", "FV")
' @param config - AssocArray with required and optional properties:
'   - ratingSize: Integer, the width and height of the badge (required)
'   - labelFont: String, the typography ID for the label (required)
'   - labelColor: String, the color for the label text (required)
'   - blendColor: String, blend color for background (default: "0xFFFFFF1A")
' @return roSGNode - Group node containing the badge background and label
Function createRatingDescriptorBadge(code as String, config as Object) as Object
  ' Get required config values
  ratingSize = config.ratingSize
  labelFont = config.labelFont
  labelColor = config.labelColor

  ' Get optional blendColor with default
  blendColor = "0xFFFFFF1A"
  if config.blendColor <> invalid then blendColor = config.blendColor

  ' Create badge background using poster helper
  badgeBackground = createPoster("pkg:/images/rating-descriptor-bg-$$RES$$.9.png", {
    width: ratingSize
    height: ratingSize
    loadDisplayMode: "scaleToFit"
  })
  badgeBackground.blendColor = blendColor

  ' Create badge label using label helper
  codeLabel = createLabel(code, {
    width: ratingSize
    height: ratingSize
    color: labelColor
    typographyFont: labelFont
    horizAlign: "center"
    vertAlign: "center"
  })

  ' Create group and append children in batch
  codeBadge = CreateObject("roSGNode", "Group")
  codeBadge.appendChildren([badgeBackground, codeLabel])

  return codeBadge
End Function
