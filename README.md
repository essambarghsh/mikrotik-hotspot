# HA WiFi Hotspot Portal

A captive portal solution for a WiFi hotspot service with subscription management, user authentication, and content delivery.

## Overview

This project provides a complete frontend interface for a WiFi hotspot service called "HA Network." It offers users the ability to:

- Log in using subscription credentials or prepaid cards
- Browse available internet packages and pricing
- Find authorized distributors/service points
- Access premium content (streaming services, sports channels)
- Monitor data usage

The portal is fully responsive and optimized for both mobile and desktop devices, with an Arabic-language interface.

## Features

- **User Authentication**: Login with username/password or prepaid card number
- **Package Management**: Display of available internet packages with details and pricing
- **Service Points**: Map of authorized distributors with their services and locations
- **Premium Content Access**: Direct links to streaming services and sports channels
- **Event-Based Content**: Special UI elements for holidays (Eid, Ramadan, New Year)
- **Mobile App Integration**: QR code for downloading companion mobile app

## Technologies

- HTML5, CSS3, JavaScript
- TailwindCSS 4.0
- MikroTik RouterOS captive portal integration
- JSON for data storage

## Project Structure

```
├── components/           # Reusable UI components
├── css/                  # Compiled CSS files
├── events/               # Event-specific content
├── img/                  # Image assets
├── src/                  # Source CSS files for Tailwind
├── support/              # Support pages
├── .vscode/              # VSCode configuration
├── *.html                # Main HTML pages
├── *.js                  # JavaScript files
└── *.json                # Configuration and data files
```

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/essambarghsh/mikrotik-hotspot.git
   cd mikrotik-hotspot.git
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. For development (with live CSS updates):
   ```
   npm run dev
   ```

4. Build for production:
   ```
   npm run build
   ```

## Deployment

To deploy this portal to a MikroTik router:

1. Build the project for production
2. Upload all files to the MikroTik router's hotspot directory
3. Configure the router's hotspot settings to use the custom HTML files

## Customization

### Plans and Pricing
Edit the `plans.json` file to modify available internet packages, prices, and features.

### Service Points/Distributors
Edit the `pos.json` file to update the list of distributors, their locations, and available services.

### Events
Seasonal events and promotions can be configured in the `settings.json` file and corresponding templates in the `events/` directory.

## Credits

- Development: Ashwab, Essam Barghsh
- Icons and resources from various sources

## License

All rights reserved - HA Network