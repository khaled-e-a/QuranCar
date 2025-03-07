# QuranCar iOS App Structure

## Documentation
- `Documentation/`
  - `file-structure.md` - Documentation of the app's file structure
  - `prd.md` - Product Requirements Document

## Testing
- `api_test/`
  - `api_test.py` - API testing script

## Main App (QuranCar/)
### Configuration
- `Config.xcconfig` - App configuration and environment variables

### Managers
- `Managers/`
  - `TokenManager.swift` - Handles authentication tokens management
  - `QuranAuthManager.swift` - Manages user authentication

### Services
- `Services/`
  - **API/**
    - `QuranAPIService.swift` - Handles API communication with backend
  - **Audio/**
    - `AudioManager.swift` - Manages audio playback functionality
  - **Storage/**
    - `QuranDataStore.swift` - Handles local data persistence

## Directory Structure Overview
