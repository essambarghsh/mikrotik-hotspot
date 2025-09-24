# Mikrotik Hotspot Auth UI

![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Arabic](https://img.shields.io/badge/language-Arabic%20(RTL)-orange.svg)

A modern, Arabic-language captive portal system for Mikrotik RouterOS with dual authentication methods, automated configuration tools, and responsive design.

## 🌟 Features

### Authentication Methods
- **Username/Password Authentication** - Standard login credentials
- **Prepaid Card System** - Voucher-based authentication ("كروت فكة")
- **CHAP Security** - Challenge-response authentication with MD5 hashing
- **Mikrotik Integration** - Full RouterOS template variable support

### User Interface
- **Arabic RTL Layout** - Native right-to-left text flow
- **Responsive Design** - Mobile-first approach
- **Service Shortcuts** - Quick access to popular websites and services
- **Pricing Plans Display** - Automated plan configuration from JSON
- **POS Locations** - Point-of-sale dealer locations with filtering
- **Animated Elements** - AOS (Animate On Scroll) integration

### Developer Tools
- **Automated Build System** - Scripts for plans, shortcuts, POS, and components
- **JSON-Driven Configuration** - Easy content management without HTML editing
- **Component System** - Reusable HTML components with compression
- **Backup Management** - Automatic backups during updates

## 🚀 Quick Start

### Installation
1. Clone the repository:
```bash
git clone https://github.com/essambarghsh/mikrotik-hotspot.git
cd mikrotik-hotspot
```

2. Make scripts executable:
```bash
chmod +x *.sh
```

3. Build the project:
```bash
npm run build
```

### Development
For rapid development with limited content:
```bash
npm run dev
```

This builds with only the first 3 items in each category for faster testing.

## 📁 Project Structure

```
mikrotik-hotspot/
├── 📄 Authentication Pages
│   ├── login.html          # Main login page
│   ├── alogin.html         # Arabic landing page
│   ├── status.html         # User session status
│   └── logout.html         # Logout confirmation
├── 🎨 Styling & Assets
│   ├── css/
│   │   ├── app.css         # Main stylesheet
│   │   └── page.css        # Page-specific styles
│   ├── img/                # Images and icons
│   └── fonts/              # Noto Kufi Arabic fonts
├── ⚙️ Configuration
│   ├── plans.json          # Internet pricing plans
│   ├── shortcuts.json      # Website shortcuts
│   ├── pos.json           # Point-of-sale locations
│   └── errors.txt         # Error message definitions
├── 🔧 Build Tools
│   ├── configure-plans.sh     # Plan configuration script
│   ├── configure-shortcuts.sh # Shortcuts configuration script
│   ├── configure-pos.sh       # POS configuration script
│   └── components.sh          # Component injection script
└── 📋 System Files
    ├── md5.js             # Client-side MD5 hashing
    ├── app.js             # Main JavaScript functionality
    └── api.json           # Captive portal API endpoint
```

## 🛠️ Configuration

### Adding Pricing Plans
Edit `plans.json` and run:
```bash
./configure-plans.sh --file login.html
```

Example plan structure:
```json
{
  "price": "100 جنية",
  "data_limit": "40 جيجا", 
  "badge": "40GB",
  "extra_badge": "الأكثر شيوعاً",
  "css_classes": ["featured"],
  "speeds": ["1 ميجا", "2 ميجا", "5 ميجا"]
}
```

### Adding Website Shortcuts  
Edit `shortcuts.json` and run:
```bash
./configure-shortcuts.sh
```

### Adding POS Locations
Edit `pos.json` and run:
```bash
./configure-pos.sh --file alogin.html
```

### Component Management
Inject components with HTML compression:
```bash
./components.sh comp footer.html file alogin.html
```

## 🎯 Key Concepts

### Mikrotik Template Variables
RouterOS replaces `$(variable)` placeholders with dynamic values:

- `$(username)`, `$(password)` - User credentials
- `$(chap-id)`, `$(chap-challenge)` - Security tokens  
- `$(link-login-only)`, `$(link-logout)` - System URLs
- `$(ip)`, `$(mac)` - Client identifiers
- `$(uptime)`, `$(bytes-in-nice)` - Session data

**⚠️ Never modify these variables - they're managed by RouterOS!**

### Authentication Flow
Think of it like a **three-layer security system**:
1. **UI Layer** - HTML forms and JavaScript validation
2. **Processing Layer** - MD5 hashing and template variables  
3. **RouterOS Layer** - Actual network authentication

## 📱 Responsive Design

The interface adapts across devices:
- **Mobile** - Simplified layout, touch-friendly buttons
- **Tablet** - Grid layouts for plans and shortcuts
- **Desktop** - Full feature set with animations

## Dynamic Theming

Automatic color palette cycling with smooth transitions:
- Default Blue, Purple Dream, Sunset Orange, Rose Pink
- 5-second intervals with 0.2s smooth transitions
- Customizable palettes in `app.js`

## 🔧 Build Scripts

| Command | Description |
|---------|-------------|
| `npm run build` | Full production build |
| `npm run dev` | Development build (limited items) |
| `npm run plans` | Update pricing plans |
| `npm run shortcuts` | Update website shortcuts |
| `npm run pos` | Update POS locations |
| `npm run components` | Inject components |

## 📄 Available Scripts

### Validation
```bash
./configure-plans.sh --validate      # Validate plans.json
./configure-shortcuts.sh --validate  # Validate shortcuts.json  
./configure-pos.sh --validate        # Validate pos.json
```

### Limited Processing (Development)
```bash
./configure-plans.sh --limit 3       # Process only first 3 plans
./configure-shortcuts.sh --limit 5   # Process only first 5 shortcuts
```

### Backup Management
```bash
./configure-plans.sh --list-backups  # List available backups
```

## 🎨 Customization

### Adding New Color Palettes
```javascript
colorChanger.addPalette("Custom Theme", {
  "--primary-color": "#your-color",
  "--primary-dark-color": "#darker-shade", 
  "--primary-light-color": "#lighter-shade",
  "--primary-extra-light-color": "#lightest-shade",
  "--body-bg-color": "#background-color"
});
```

### Custom Error Messages
Edit `errors.txt` with Arabic translations:
```
invalid-username = اسم المستخدم او كلمة السر خاطئة
account-expired = عفوا الاشتراك منتهى
```

## 🌐 Browser Support

- ✅ Chrome/Edge (Modern)
- ✅ Firefox
- ✅ Safari  
- ✅ Mobile browsers
- ⚠️ IE11+ (Limited features)

## 🔒 Security Features

- **CHAP Authentication** - Challenge-response security
- **MD5 Password Hashing** - Client-side security
- **Input Validation** - XSS prevention
- **Template Variable Protection** - RouterOS integration safety

## 📈 Performance

- **Font Preloading** - Faster Arabic text rendering
- **CSS Optimization** - Minimal render blocking
- **Component Compression** - Reduced HTML size
- **Lazy Loading** - AOS animations on demand

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Test with development build: `npm run dev`
4. Commit changes: `git commit -m 'Add new feature'`
5. Push to branch: `git push origin feature/new-feature`
6. Submit a pull request

### Development Guidelines
- Preserve Arabic RTL layout
- Maintain Mikrotik template variables
- Test both authentication methods
- Follow mobile-first responsive design
- Add appropriate animations for new elements

## 📞 Support

For technical support or customization requests, contact the developer.

## 👨‍💻 Developer

**Essam Barghsh**  
🌐 [ashwab.com](https://www.ashwab.com)  
📧 Contact via website

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Noto Kufi Arabic font family
- AOS (Animate On Scroll) library
- Mikrotik RouterOS documentation
- Arabic web development community

---

Made with ❤️ for the Arabic-speaking networking community