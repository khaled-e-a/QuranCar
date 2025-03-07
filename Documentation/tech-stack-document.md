# QuranCar Technical Stack Documentation

This document outlines the complete technical architecture, frameworks, libraries, and APIs used in the QuranCar iOS application.

## Development Environment

### Requirements
- Xcode 14.0 or later
- iOS 16.0+ deployment target
- Swift 5.7+
- macOS Ventura 13.0+ (for development)

### Project Configuration
- SwiftUI and UIKit hybrid approach
- MVVM (Model-View-ViewModel) architecture
- Swift Package Manager for dependency management

## Core iOS Frameworks

### UIKit and SwiftUI
- UIKit for CarPlay interface components
- SwiftUI for iPhone app UI
- Combination approach for maximum compatibility and performance

Documentation:
- [UIKit Documentation](https://developer.apple.com/documentation/uikit)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

### CarPlay Framework
- `CarPlay.framework` for car interface integration
- `CPTemplateApplicationScene` for CarPlay app initialization
- `CPNowPlayingTemplate` for audio playback interface
- Custom CarPlay templates for memorization UI

Documentation:
- [CarPlay Framework Documentation](https://developer.apple.com/documentation/carplay)
- [CarPlay App Programming Guide](https://developer.apple.com/carplay/documentation/CarPlay-App-Programming-Guide.pdf)

### AVFoundation
- Core audio playback capabilities
- Background audio session configuration
- Audio asset management

Documentation:
- [AVFoundation Documentation](https://developer.apple.com/documentation/avfoundation)

### CoreData
- Local storage of user preferences
- Offline data caching
- Memorization progress tracking

Documentation:
- [CoreData Documentation](https://developer.apple.com/documentation/coredata)

## Third-Party Dependencies

### Audio Playback and Processing
- `AudioKit` - Advanced audio processing capabilities (optional)

### Networking
- `Alamofire` - Simplified networking and API calls (optional)
- `Kingfisher` - Image downloading and caching (for reciter profile images, optional)

### Storage
- `Realm` - Alternative to CoreData for enhanced performance (optional)

## External APIs

### Quran Audio API
- Endpoint: `https://api.quran.com/api/v4/`
- Provides access to recitation audio files from various reciters
- Documentation: [Quran.com API Documentation](https://quran.api-docs.io/v4/getting-started/introduction)

### Quran Text and Metadata API
- Provides surah information, verse counts, and text
- Used for displaying surah lists and verse information

## Services and Managers

### QuranAPIService
- Handles all network requests to external Quran APIs
- Manages caching of API responses
- Implements error handling and retry logic

### AudioManager
- Controls audio playback functionality
- Manages background audio session
- Handles interruptions (calls, Siri, etc.)
- Implements chunking repetition logic

### QuranDataStore
- Manages local persistence of Quran data
- Handles offline access to previously downloaded content
- Stores user preferences and settings

### TokenManager
- Manages authentication tokens if needed for API access
- Handles token refresh and expiration

## Development Tools

### Version Control
- Git/GitHub for source control
- Branch strategy: feature/fix/hotfix branches with main and development branches

### Testing
- XCTest for unit and UI testing
- Python scripts (`api_test.py`) for API endpoint testing

### Continuous Integration
- Xcode Cloud or GitHub Actions for CI/CD pipeline
- Automated testing on pull requests

## Architecture Overview

### MVVM Pattern
- **Models**: Data structures representing Quran surahs, verses, reciters
- **Views**: SwiftUI views and UIKit controllers for user interface
- **ViewModels**: Business logic connecting models and views

### CarPlay Integration
- Separate scenes and templates for CarPlay interface
- Shared data model between iPhone and CarPlay interfaces
- State synchronization between devices

### Data Flow
1. Configuration selected on iPhone app
2. Settings stored in QuranDataStore
3. AudioManager loads appropriate audio files via QuranAPIService
4. Playback syncs between iPhone and CarPlay interfaces

## Security Considerations

- User data stored locally, minimal cloud integration in initial version
- No sensitive user information collected
- Standard iOS security practices for local storage

## Future Technical Considerations

- Backend integration for user accounts and progress syncing
- Expanded offline capabilities with smart caching
- Enhanced CarPlay integration with custom templates
- Voice command capabilities using Speech framework

## Build and Deployment

### Debug vs Release Configuration
- Configuration settings managed in Config.xcconfig
- Development and production API endpoints separated
- Debug logging disabled in release builds

### App Store Submission Requirements
- CarPlay entitlement requirement
- Background audio mode capability
- Network access permissions
