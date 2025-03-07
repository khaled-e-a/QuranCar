# QuranCar - Product Requirements Document

## App Overview
QuranCar is an iOS application designed to provide users with an intuitive way to memorize the Quran while driving or traveling. The memorization achieved by splitting the Quran into small chunks and repeating them.
The app offers a distraction-free, driver-friendly interface through CarPlay by allowing users to safely repeat the memorization chunks, go to the next or previous chunk, without taking their attention off the road using the steering wheel buttons.

The app supports configuration of the memorization chunks, by selecting the surahs and the number of verses per chunk, either through the phone or through the CarPlay interface.

## User Flow

1. **Initial Setup**
   - User opens app for the first time on their iPhone
   - Brief introduction explaining the Quran memorization concept

2. **Memorization Configuration (iPhone)**
   - User selects surahs they want to memorize
   - User configures chunk size (number of verses per memorization segment)
   - User selects preferred reciter for memorization

3. **CarPlay Integration**
   - User connects iPhone to CarPlay-enabled vehicle
   - QuranCar automatically appears in the CarPlay interface
   - Large, simple controls display current memorization chunk information
   - Show the current memorization chunk information on the CarPlay screen

4. **In-Car Memorization Experience**
   - Playback begins with current memorization chunk
   - Each chunk repeats according to user settings
   - User navigates between chunks using steering wheel controls:
     - Next/Previous buttons to move between chunks
     - Play/Pause to control playback
     - Long-press to repeat current chunk again

5. **Adjusting Settings**
   - User can modify chunk size and selection on iPhone
   - Quick settings accessible through CarPlay for on-the-go adjustments
   - Audio settings (volume, speed) controllable through car's standard controls

## Tech Stack & APIs

### Frontend
- Swift/SwiftUI for iOS native development
- UIKit for custom UI components
- AVFoundation for audio processing
- CoreData for local storage

### Backend (planned for future release)
- RESTful API architecture
- Authentication and user management
- Cloud storage for user preferences and bookmarks

### Third-Party APIs
- Quran database API for text and audio
- Apple App Store Connect for analytics and crash logs

## Core Features

1. **CarPlay Integration**
   - Seamless integration with Apple CarPlay
   - Optimized interface for in-car viewing
   - Compatible with steering wheel controls for navigation

2. **Chunk-Based Memorization System**
   - Customizable verse chunking (select number of verses per segment)
   - Automatic repetition of current memorization chunk
   - Easy navigation between memorization chunks

3. **Recitation Library**
   - Multiple renowned Quran reciters to choose from
   - High-quality audio recordings of all 114 surahs
   - Offline storage of selected surahs for uninterrupted use

4. **Distraction-Free Driver Interface**
   - Minimal interaction required during driving sessions
   - Current chunk information clearly displayed
   - Interaction during driving using steering wheel buttons

5. **Memorization Configuration**
   - Surah selection for memorization sessions
   - Adjustable chunk size for personalized learning pace
   - Reciter preference settings

6. **Offline Functionality**
   - Complete offline access to downloaded surahs
   - No internet connection required during drives
   - Audio caching for reliable playback
   - Local storage of user preferences and settings

## In-scope & Out-of-scope

### In-scope
- iOS application with optimized interface for in-car use
- Audio playback of Quranic recitations
- Voice command control system
- Offline playback capabilities
- Background audio and lock screen controls
- Multiple reciters
- Basic analytics for app usage and performance

### Out-of-scope (planned for future release)
- Bookmarking and history features
- User account management and preferences
- Configure playback speed and pauses between repetitions
- Auto-launch when iPhone connects to car
- Android version
- In CarPlay: status indicators show progress through selected surahs
- Full Quran text display and tafsir (interpretation)
- Social features like sharing or communities
- In-app purchases or subscription model
- Custom recitation recording functionality
- Integration with car infotainment systems (beyond standard audio connections)
- Push notification services
- Progress Tracking & Management
   - Quick access to frequently memorized sections
   - App tracks completed memorization sessions
   - Progress syncs between CarPlay and iPhone app
   - iPhone app shows statistics and heatmap of memorization activity
   - Recommendations for review of previously memorized chunks
   - Option to mark chunks as "mastered" or "needs review"