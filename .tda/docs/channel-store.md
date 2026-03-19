# channel-store

## Purpose

Contains the marketing and branding assets required for the Roku Channel Store listing. These include the channel poster images, screenshots, and search icons displayed on the Roku Channel Store page.

## Structure

- `channel-store-poster-en-540x405.png` - English channel poster for the store listing
- `channel-store-poster-es-540x405.png` - Spanish channel poster
- `channel-store-poster-fr-540x405.png` - French channel poster
- `channel-store-poster-staging-540x405.png` - Staging channel poster (used for the staging/beta channel)
- `screenshots-fhd/` - Full HD screenshots for the Channel Store listing
- `search-icons/` - Search result icons

## Architecture

- **Static Assets**: These are static marketing images maintained by the design/product team and submitted as part of the Roku Channel Store certification process.

## Working with this Code

### Things to Watch Out For

- Image dimensions must match Roku's Channel Store requirements exactly (540x405 for posters).
- Staging vs. production posters must be visually distinct to avoid confusion when multiple channels are installed on a device.
