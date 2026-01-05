# SafeNet VPN - Flutter Application

A cross-platform VPN client built with Flutter that supports both WireGuard and IKEv2 protocols, providing secure and private internet access across multiple platforms (Android, iOS, Windows, macOS, Linux).

## 🏗️ Architecture Overview

### Project Structure
```
lib/
├── data/                 # Data layer
│   └── services/        # API and VPN services
│       ├── ikeav2Services.dart
│       └── wireguardServices.dart
├── domain/              # Domain models
│   └── models/          # Data models
│       ├── plan.dart
│       ├── server.dart
│       ├── subscription.dart
│       └── user.dart
├── services/            # App services
│   └── analytics_service.dart
├── ui/                  # UI layer
│   ├── core/           # Core UI components
│   │   └── ui/         # Screens
│   │       ├── account/
│   │       ├── assistant/
│   │       ├── auth/
│   │       ├── bottomnav/
│   │       ├── premium/
│   │       ├── server/
│   │       ├── settings/
│   │       ├── splash/
│   │       └── vpnScreen/
│   └── widgets/        # Reusable widgets
├── utils/              # Utility classes
│   └── utils.dart
├── view_model/         # ViewModels (State Management)
│   ├── cipherGateModel.dart
│   └── homeGateModel.dart
├── firebase_options.dart
└── main.dart
```

## 🔧 Technology Stack

### Core Framework
- **Flutter** ^3.8.1 - Cross-platform UI framework
- **GetX** ^4.6.6 - State management, dependency injection, and navigation

### VPN Implementation
- **flutter_vpn** (local package) - Custom VPN implementation for IKEv2/IPSec
- **wireguard_flutter** ^0.1.3 - WireGuard protocol implementation
- **dart_ping** ^9.0.1 - Network latency testing

### API & Networking
- **http** ^1.5.0 - HTTP client for API communication
- **cached_network_image** ^3.4.1 - Image caching

### Storage & Persistence
- **shared_preferences** ^2.5.3 - Local data storage

### UI & Design
- **google_fonts** ^6.3.1 - Typography
- **eva_icons_flutter** ^3.1.0 - Icon pack
- **percent_indicator** ^4.2.5 - Progress indicators

### Analytics
- **firebase_core** ^4.3.0
- **firebase_analytics** ^12.1.0

### Desktop Support
- **window_manager** ^0.4.3 - Window management for desktop platforms

## 🚀 How the VPN Works

### 1. Protocol Support

#### WireGuard Protocol
- Implemented via `wireguard_flutter` package
- Managed by `Wireguardservices` class
- Configuration fetched from server API
- Supports fast, modern VPN connections

#### IKEv2/IPSec Protocol
- Implemented via custom `flutter_vpn` package
- Managed by `Ikeav2EngineAndIpSecServices` class
- Supports kill switch and split tunneling
- Compatible with more legacy systems

### 2. Connection Flow

1. **Authentication**
   - User login via `/api/login` endpoint
   - Credentials stored securely using SharedPreferences
   - JWT token maintained for API requests

2. **Server Selection**
   - Fetch server list from `/api/servers`
   - Display servers with latency information
   - Support for server filtering and search

3. **User Registration on VPS**
   - Before connection, user is registered on selected VPS
   - Unique client credentials generated per platform
   - API endpoint: `http://[server]:5000/api/clients/generate`

4. **VPN Connection**
   
   **For WireGuard:**
   - Fetch configuration from server
   - Initialize WireGuard interface
   - Start VPN with configuration
   
   **For IKEv2:**
   - Initialize IKEv2 engine
   - Connect with username/password
   - Support for kill switch and app blocking

5. **State Management**
   - Real-time connection state monitoring
   - Speed monitoring and display
   - Automatic reconnection on failure

### 3. Key Features

#### Security Features
- Kill Switch (blocks internet if VPN disconnects)
- Split Tunneling (selective app routing)
- Protocol selection (WireGuard/IKEv2)
- Secure credential storage

#### Monitoring & Analytics
- Connection success/failure tracking
- Server usage statistics
- Session duration monitoring
- Platform-specific analytics
- Firebase Analytics integration

#### User Experience
- Server latency testing
- Auto-connect on app launch
- Quick server selection
- Real-time speed indicators
- Multi-language support ready

## 📱 Platform Support

### Mobile Platforms
- **Android**: Full feature support
- **iOS**: Full feature support

### Desktop Platforms
- **Windows**: Window management, fixed size (480x750)
- **macOS**: Native window management
- **Linux**: Window management support

## 🔐 API Integration

### Base URL
```
https://psvpn-portal.protocolshield.com/api/
```

### Key Endpoints
- Authentication: `/login`, `/signup`
- Servers: `/servers`, `/vps-servers`
- Plans: `/plans`, `/purchase/status`
- User: `/user`, `/user/update`
- Support: `/feedback/store`, `/ticket/create`

## 🎯 State Management (GetX)

### HomeGateModel
- Server management and selection
- VPN connection state
- Protocol switching
- Speed monitoring
- Subscription status

### CipherGateModel
- User authentication
- Profile management
- Settings persistence

## 📊 Analytics Implementation

Comprehensive Firebase Analytics tracking:
- App opens and user sessions
- VPN connections (success/failure)
- Server usage patterns
- Protocol preferences
- Platform distribution
- Payment and subscription events

## 🛠️ Development Setup

1. **Prerequisites**
   - Flutter SDK ^3.8.1
   - Dart SDK compatible with Flutter version
   - Platform-specific development tools

2. **Installation**
   ```bash
   git clone <repository-url>
   cd safenetvpn
   flutter pub get
   ```

3. **Firebase Setup**
   - Add `google-services.json` for Android
   - Add `GoogleService-Info.plist` for iOS
   - Configure Firebase Analytics

4. **Run Application**
   ```bash
   flutter run
   ```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Windows
```bash
flutter build windows --release
```

### macOS
```bash
flutter build macos --release
```

### Linux
```bash
flutter build linux --release
```

## 🔧 Configuration

### Environment Variables
- API endpoints configured in `utils/utils.dart`
- Firebase configuration in `firebase_options.dart`
- Window settings in `main.dart`

### Platform-Specific Configurations
- Android: `android/app/build.gradle`
- iOS: `ios/Runner/Info.plist`
- Windows: `windows/runner/CMakeLists.txt`
- macOS: `macos/Runner/Info.plist`

## 🚨 Security Considerations

1. **Credential Storage**
   - User credentials encrypted using SharedPreferences
   - JWT tokens securely stored

2. **VPN Security**
   - WireGuard uses modern cryptography
   - IKEv2 with strong encryption algorithms
   - Kill switch prevents data leaks

3. **API Security**
   - HTTPS for all API communications
   - Token-based authentication
   - Request validation and sanitization

## 🐛 Troubleshooting

### Common Issues
1. **VPN Connection Fails**
   - Check server availability
   - Verify user registration on VPS
   - Check network permissions

2. **Kill Switch Issues**
   - Ensure VPN permissions granted
   - Check app blocking settings
   - Restart application

3. **Speed Issues**
   - Test server latency
   - Switch protocols
   - Check network connection

## 📄 License

This project is proprietary software. All rights reserved.

## 🤝 Support

For support and issues:
- In-app feedback system
- Email: support@safenetvpn.com
- Knowledge base: https://safenetvpn.com/help

---

**Note**: This VPN client is designed to provide secure and private internet access. Always ensure compliance with local laws and regulations when using VPN services.
