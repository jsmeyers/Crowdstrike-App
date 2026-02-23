# CrowdStrike Falcon Endpoint Manager

A native iOS/iPadOS app for monitoring and managing CrowdStrike Falcon endpoints and alerts on the go.

## Features

### Endpoints Management
- View all enrolled endpoints with detailed information
- Filter endpoints by status (Online, Offline, Containment, Sensor Disabled)
- Filter endpoints by platform (Windows, macOS, Linux, etc.)
- Pull-to-refresh to update endpoint data
- Detailed endpoint view including:
  - Network information (IP addresses, MAC address, gateway)
  - System details (manufacturer, model, serial number)
  - OS and Falcon agent version
  - Location and organizational data
  - Host groups and tags
  - Copy-to-clipboard for important fields

### Alerts Monitoring
- View security alerts from your CrowdStrike environment
- Real-time alert refresh
- Progress tracking during data loads

### Settings & Configuration
- **Authentication Methods**
  - OAuth2 (Client ID + Client Secret)
  - Direct Bearer Token
- **Region Selection**: Pre-configured CrowdStrike regions (US-1, US-2, EU-1, etc.)
- **Custom Base URL**: Support for custom API endpoints
- **Network Settings**: Configurable request and connection timeouts
- **Proxy Support**: HTTP/HTTPS proxy with optional authentication
- **Alert Filtering**: Option to filter third-party alerts
- **Endpoint Display**: Hide stale endpoints (configurable threshold)
- **Debug Mode**: Verbose logging for troubleshooting

## Requirements

- iOS 17.0+ / iPadOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- CrowdStrike Falcon API credentials

## Getting Started

### Prerequisites
1. A CrowdStrike Falcon account with API access
2. API Client ID and Client Secret (or a Bearer Token)
3. Appropriate API scopes assigned to your API client

### Installation
1. Clone the repository
2. Open `Crowdstrike-App.xcodeproj` in Xcode
3. Build and run on your target device or simulator

### Configuration
1. Launch the app and navigate to **Settings**
2. Select your **Authentication Method**:
   - **OAuth2**: Enter your Client ID and Client Secret
   - **Bearer Token**: Enter a pre-obtained access token
3. Select your **Region** or enter a custom base URL
4. Tap **Save Credentials**
5. Return to **Endpoints** or **Alerts** to start viewing data

## API Scopes Required

The following CrowdStrike API scopes are required:

| Scope | Permission Level |
|-------|-----------------|
| Hosts | Read |
| Alerts | Read |

## Architecture

- **UI Framework**: SwiftUI with NavigationStack
- **Data Persistence**: SwiftData
- **Architecture Pattern**: MVVM (Model-View-ViewModel)
- **Networking**: Native URLSession with async/await
- **Minimum Deployment**: iOS 17.0

## Project Structure

