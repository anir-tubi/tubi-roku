---
description: Generate 9-patch rounded rectangle images for Roku
---

Generate 9-patch images with rounded corners using the rounded-rect-9patch library.

BEFORE STARTING: Check if rounded-rect-9patch is installed in package.json. If the command fails with a "command not found" error or if npx takes a long time downloading, suggest the user run `npm install` to install all dependencies including rounded-rect-9patch.

## How to get parameters:

The user can invoke this command in two ways:

### Option 1: With inline parameters (PREFERRED)
```
/9patch name=button-bg radius=36 fill=#FFFFFF border=#00000000 borderWidth=0
```

Parse the inline parameters from the command message. If all required parameters are provided, use them directly without asking questions.

### Option 2: Ask the user in plain conversation
If parameters are NOT provided inline, ask the user to provide them in a single plain text message. DO NOT use the AskUserQuestion tool due to bugs with custom value handling.

**Required parameters:**
1. **name**: Image file name (without extension) - e.g., "button-background"
2. **radius**: Corner radius in pixels - e.g., 3, 10, 30, 36
3. **fill**: Fill color as hex code - e.g., "#FFFFFF" for white, "#00000000" for transparent
4. **border**: Border color as hex code - e.g., "#000000" for black, "#00000000" for transparent
5. **borderWidth**: Border width in pixels - e.g., 0 for no border, 2 for thin border

**Defaults to suggest:**
- radius: 10
- fill: #FFFFFF (white)
- border: #00000000 (transparent)
- borderWidth: 0

When asking the user, say something like:
"Please provide the parameters in this format: name=button-bg radius=36 fill=#FFFFFF border=#00000000 borderWidth=0

Or just tell me the values and I'll use sensible defaults for any you don't specify."

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

## Example usage:

User invokes: `/9patch name=button-bg radius=36 fill=#FFFFFF border=#00000000 borderWidth=0`

You execute:
```bash
cd src/channel/images
npx rounded-rect-9patch 36 --fillColor "#FFFFFF" --borderColor "#00000000" --borderWidth 0 --output "button-bg-{res}-{radius}px.9.png"
mv button-bg-fhd-36px.9.png button-bg-fhd.9.png
mv button-bg-hd-36px.9.png button-bg-hd.9.png
```
