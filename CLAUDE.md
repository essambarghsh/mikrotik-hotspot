# Mikrotik Hotspot Auth UI - Project Understanding

## Project Overview
This is a **captive portal system** for Mikrotik RouterOS - think of it like a hotel's WiFi login page that appears before users can access the internet. It's written in Arabic (RTL layout) and provides a branded authentication interface.

## Key Technologies & Components

### Core Stack
- **HTML/CSS/JavaScript** - Standard web technologies
- **Mikrotik Template Variables** - Special `$(variable)` syntax that RouterOS replaces with dynamic values
- **MD5 Hashing** - For secure CHAP authentication (see `md5.js`)

### Authentication Methods
1. **Username/Password** - Standard login credentials
2. **Card Numbers** - Prepaid voucher system (like phone cards)
3. **CHAP Authentication** - Challenge-response for security

## Critical File Functions

### Authentication Flow Files
- `login.html` - Main login page with dual auth methods
- `alogin.html` - Arabic landing page with service shortcuts
- `status.html` - Shows user session info when logged in
- `logout.html` - Logout confirmation and session summary
- `error.html` - Displays authentication errors

### System Files
- `redirect.html` & `rlogin.html` - Handle 302 redirects and WISP compliance
- `radvert.html` - Advertisement popup system
- `api.json` - Captive portal API endpoint
- `errors.txt` - Error message definitions
- `md5.js` - Client-side password hashing

## Mikrotik Template Variables (Key Concept)
These `$(variable)` placeholders get replaced by RouterOS:

### Authentication Variables
- `$(username)`, `$(password)` - Login credentials
- `$(chap-id)`, `$(chap-challenge)` - Security tokens
- `$(link-login-only)`, `$(link-logout)` - System URLs

### Session Variables  
- `$(ip)`, `$(mac)` - Client identifiers
- `$(uptime)`, `$(session-time-left)` - Time tracking
- `$(bytes-in-nice)`, `$(bytes-out-nice)` - Data usage

### System Variables
- `$(hostname)`, `$(location-name)` - Network info
- `$(error)` - Error messages
- `$(logged-in)` - Authentication status

## Business Context
This appears to be for an Egyptian ISP offering:
- Internet packages with BeIN Sports and streaming ("المجلة")
- Prepaid card system
- Usage monitoring app
- Dealer/distributor network

## Development Guidelines

### When Working on This Project:
1. **Preserve Arabic RTL layout** - Don't break right-to-left text flow
2. **Maintain Mikrotik variables** - Never modify `$(variable)` syntax
3. **Keep authentication logic intact** - The MD5/CHAP flow is security-critical
4. **Test both auth methods** - Username/password AND card number flows
5. **Consider mobile responsiveness** - Users often connect via phones

### Common Tasks:
- **Styling changes** - Modify `css/app.css`
- **Content updates** - Edit HTML files (mind the template variables)
- **Feature additions** - Add to `app.js` 
- **Error handling** - Update `errors.txt` for new error messages

## Architecture Pattern
Think of it like a **three-layer cake**:
1. **Top layer (UI)** - HTML/CSS for user interface
2. **Middle layer (Logic)** - JavaScript + Mikrotik template processing  
3. **Bottom layer (System)** - RouterOS handles actual network authentication

The files you see are the "recipe" - RouterOS is the "oven" that bakes them into a working portal.