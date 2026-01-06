---
description: Generate 9-patch rounded rectangle images for Roku
---

Generate 9-patch images with rounded corners using the rounded-rect-9patch library.

BEFORE STARTING: Check if rounded-rect-9patch is installed in package.json. If the command fails with a "command not found" error or if npx takes a long time downloading, suggest the user run `npm install` to install all dependencies including rounded-rect-9patch.

FIRST: Ask the user for these required parameters:
1. Name of the image file (without extension)
2. Corner radius in pixels (e.g., 3)
3. Fill color as hex code (e.g., #FFFFFF for white, #00000000 for transparent)
4. Border color as hex code (e.g., #000000 for black, #00000000 for transparent)
5. Border width in pixels (e.g., 0 for no border, 2 for a thin border)

Provide sensible defaults in your questions:
- Corner radius: suggest 3px
- Fill color: suggest #FFFFFF (white)
- Border color: suggest #00000000 (transparent)
- Border width: suggest 0

Requirements:
1. Change directory to src/channel/images/
2. Use npx rounded-rect-9patch with the parameters above
3. Rename generated files to: {name}-hd.9.png and {name}-fhd.9.png
4. Report the final file paths

Available options:
- --extraRadius: Space between corner and stretch line (default: 1)
- --stretchWidth: Width of black stretch lines (default: 4)
- --borderColor: Hex color of border (wrap in quotes, supports alpha)
- --fillColor: Hex color of fill (wrap in quotes, supports alpha)
- --borderWidth: Border width in pixels (default: 2)
- --paddingHeight: Height of padding block
- --paddingWidth: Width of padding block
- --paddingX: Offset of length padding block
- --paddingY: Offset of height padding block
- --res: Base resolution - fhd or hd (default: fhd)
- --output: Filename template (default: rounded-rect-{res}-{radius}px.9.png)
- --noScale: Create single image instead of scaling for multiple resolutions

IMPORTANT:
- Use npx rounded-rect-9patch to run the command without global installation
- Change directory to src/channel/images/ before generating
- The --output template MUST include both {res} AND {radius} template values (e.g., "{name}-{res}-{radius}px.9.png")
- Parse all provided options and pass them to the rounded-rect-9patch command
- The tool generates .9.png files (9-patch format for Roku)
- Multiple radius values will generate separate images for each radius
- Color values should be wrapped in quotes to prevent shell parsing issues
- Files are generated directly in the current directory when using --output
- Report the full paths of all generated files

Example command:
npx rounded-rect-9patch 6 --fillColor "#FFFFFF" --borderColor "#00000000" --borderWidth 0 --output "test-rounded-{res}-{radius}px.9.png"
