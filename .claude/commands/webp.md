---
description: Convert PNG image to WebP format and delete original
argument-hint: <image_path>
---

Convert the PNG image at the provided path to WebP format using the sharp library.

FIRST: Check if an image path was provided. If "{{$1}}" is empty, contains only "{{", or equals "{{$1}}", then output a clear error message:
"Error: No image path provided. Usage: /png-to-webp <path-to-image.png>"

BEFORE STARTING: Check if sharp is installed in package.json. If the conversion fails with a "cannot find module 'sharp'" error or sharp is not available, suggest the user run `npm install` to install all dependencies including sharp.

Requirements:
1. Take the image path as input (will be provided as an argument)
2. If the path is just a filename (no directory separators), prepend "./images/" to search in the images folder
3. If the path contains directory separators, use it as-is
4. Validate that the file exists and is a PNG file
5. Use sharp to convert the PNG to WebP with quality setting of 80
6. Save the WebP file with the same name but .webp extension in the same directory as the source
7. Delete the original PNG file after successful conversion
8. Report success with the new file path, or error if conversion fails

Image path: {{$1}}

IMPORTANT:
- Use Node.js with sharp library for the conversion
- Default to ./images/ folder if only a filename is provided (e.g., "logo.png" becomes "./images/logo.png")
- Use the provided path as-is if it contains "/" or "\" characters
- Ensure the conversion is successful before deleting the original
- Provide clear error messages if the file doesn't exist or isn't a PNG
