# QuranCar App Flow Document

## iPhone App Flow

### First Launch Experience

When a user opens QuranCar for the first time, they see a welcome screen with the app logo and a brief introduction. The user taps "Get Started" to proceed to a short tutorial explaining the core concept of Quran memorization through chunking. After the tutorial, the app requests necessary permissions for media access. The user is then directed to the main configuration screen.

### Main Configuration Screen

The main configuration screen is the central hub of the iPhone app. From here, the user can:

- View their currently selected surahs for memorization
- See their current chunk size setting
- Access the surah selection screen by tapping "Select Surahs"
- Access the starting verse configuration by tapping "Starting Verse"
- Access the chunk size configuration by tapping "Number of Verses"
- Access the reciter selection by tapping "Choose Reciter"
- View the CarPlay connection status
- Access app settings from the navigation bar

### Surah Selection Screen

When the user taps "Select Surahs" from the main configuration screen, they enter the surah selection screen. This displays all 114 surahs of the Quran in a scrollable list. Each surah entry shows:

- Surah number
- Surah name in Arabic and English
- Number of verses

The user then selects the surah they want to memorize from the list.

### Starting Verse Configuration Screen

The starting verse configuration screen allows the user to select the verse they want to start memorizing from.

### Chunk Size Configuration Screen

Under the "Number of Verses" section, the user can select the number of verses they want to memorize at a time.

### Reciter Selection Screen

The reciter selection screen presents a list of available Quran reciters with high-quality recordings.

The user can select the reciter they want to use for memorization.

### Settings Screen

The settings for the first launch only contains a message about upcoming features and a link to the privacy policy.


## CarPlay App Flow

### CarPlay Home Screen

When the iPhone is connected to a CarPlay-enabled vehicle, QuranCar appears on the CarPlay home screen as an app icon. Tapping this icon launches the QuranCar CarPlay interface.

### CarPlay Main Screen

The CarPlay main screen is minimalist and driver-friendly. It displays:

- Current surah name and chunk information (e.g., "Al-Baqarah: Verses 1-5")
- A large play/pause button in the center
- Next chunk and previous chunk buttons

All text is large and high-contrast for easy viewing while driving.

### CarPlay Playback Experience

When playback begins, the current chunk plays completely and then repeats according to user settings. The user can:

- Press play/pause to control audio playback
- Press next/previous buttons (or use steering wheel controls) to navigate between chunks
- Return to the CarPlay home by pressing the home button
- Once a chunk is completed, the chunk is replayed automatically

The interface remains simple to minimize driver distraction.

### CarPlay Quick Settings

A small settings icon on the CarPlay main screen opens a simplified settings view with limited options:

- Adjust number of verses
- Select surah
- Select starting verse

These quick settings are designed for minimal interaction and safe use while driving.

## Transitions and States

### iPhone to CarPlay Transition

When the user connects their iPhone to a CarPlay-enabled vehicle:
1. The iPhone app detects the CarPlay connection
2. The app state synchronizes between devices
3. QuranCar becomes available on the CarPlay interface
4. The current memorization session transfers to CarPlay

### Background Audio State

When the user exits the app but audio is playing:
1. Playback continues in the background
2. Lock screen controls show the current surah and chunk
3. Control Center provides audio controls
4. If the phone is connected to CarPlay, the CarPlay interface remains active

### App Resume State

When returning to the app after closing:
1. The app reopens to the main configuration screen
2. Current selections and configurations remain as previously set
