# VisionTag

A QR code-based clothing information system for people with visual impairments, built with Flutter.

## Overview

VisionTag helps visually impaired individuals with offline shopping and wardrobe management. Using QR codes, users can scan a garment and receive a text-to-speech description of its properties, including color, material, and texture.

## Features

- **Home Mode**: Manage clothing inventory, update item status, and remove items
- **Retail Mode**: Scan clothing items while shopping to get detailed information
- **QR Code Scanning**: Quick and accessible scanning of clothing tags
- **Text-to-Speech**: Audio feedback for all information
- **Accessible UI**: High-contrast interface with large touch targets
- **Offline Operation**: Works without internet connection

## Prerequisites

- Flutter SDK (2.17.0 or later)
- Dart SDK (2.17.0 or later)
- Android Studio or VS Code
- Android/iOS device or emulator

## Setup Instructions

### 1. Install Flutter

If you haven't installed Flutter yet, follow the [official Flutter installation guide](https://flutter.dev/docs/get-started/install).

### 2. Clone the Repository

```bash
git clone https://github.com/yourusername/visiontag.git
cd visiontag
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Running on IDX (Integrated Development Experience)

1. Open [Google's IDX platform](https://idx.dev/)
2. Create a new project or use an existing one
3. Open a terminal within IDX
4. Clone or upload the VisionTag project
5. Run the following commands:

```bash
cd visiontag
flutter pub get
flutter run
```

### 5. Running on Physical Device or Emulator

To run on a connected device or emulator:

```bash
flutter run
```

For specific device:

```bash
flutter devices  # List available devices
flutter run -d device_id  # Run on specific device
```

### 6. Build Release Version

For Android:

```bash
flutter build apk --release
```

For iOS:

```bash
flutter build ios --release
```

## Project Structure

- `lib/main.dart` - Entry point for the application
- `lib/models/` - Data models
- `lib/providers/` - State management
- `lib/screens/` - UI screens
- `lib/services/` - TTS and other services
- `lib/utils/` - Utility functions

## Usage

### Home Mode

- **Scan Item**: Scan QR codes on clothing to add to your wardrobe
- **My Wardrobe**: Browse and get information about your clothing items
- **Update Status**: Mark items as clean or needing washing
- **Remove Item**: Delete items from your wardrobe

### Retail Mode

- Tap the screen to scan QR codes while shopping
- Get detailed information about the clothing item, including:
  - Color with visual representation
  - Price and discount calculation
  - Material and texture
  - Laundry care instructions
  - Manufacturer and collection information

## Accessibility Features

- Text-to-speech feedback for all actions
- High contrast UI elements
- Large touch targets
- Clear, simple navigation

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter and Dart teams
- Contributors to the open-source packages used


## To do
- 2 items in the update status each covers half of the one at bottom one at top side - needs to fill screen
- 2 items in the remove status each covers half of the one at bottom one at top side - needs to fill screen
- 2 items in the wardrobe each covers half of the one at bottom one at top side - needs to fill screen
- Copy "add item" functionality from qr code to wardrobe same as retail mode, they should be basically the same.

- it needs to indicate if it is clean or needs washing in the wardrobe -done
- 1 tap reads only basic properties and double tap reads details in the wardrobe -done
- 4 items in the wardrobe each at one corner to go to next page scroll - done
- Retail mode divide screen in to two llike the main screen - done

- it shouldnt automatically save the clothes to wardrobe should ask to user



##  More to do
## Feedback
- 

## Multiple mode of output
- Supports speech, text and icons


## Homepage
- Speech: explicitly state tell the user how many modes are available, and which one is currently selected.
- Pinch to close the application.
- Remove swipe gestures from the home mode. Click once to read out selected, double tap to open.
- My wardrobe, read: current page number, item count on page, total count for both items and pages.
- Remove camera selfie camera option.
- When scanning for qr code: provide hints; qr code not found, how to close “swipe left maybe”.
- Go to previous opage gesture
- Assign icons to items in the wardrobe and remove item screens.
- Status can only be changed when item is selected.
- Confirm deletion, single tap select, double tap delete, and double tap again to confirm, cancel swipe left.

## Retail mode
- Triple tap doesn’t work, remove.
- Add navigation gestures to landing screen.
- Read out field names, create retail qr code.

## Gestures 
- Swipe left to go back
- Swipe right to go forward
- Single tap to read out selected
- Double tap to open
- Hold help
- Shake repeat previous

## NB for the presentation.
- Retail mode qr code creation is designed for slightly visually impaired or not impaired at all.

## Future work: 
- Make camera light aware so it will open the flash automatically if its dark.
- Make it adaptable: assign own gesture.

##  Icon credits
- eye qr code by Template from <a href="https://thenounproject.com/browse/icons/term/eye-qr-code/" target="_blank" title="eye qr code Icons">Noun Project</a> (CC BY 3.0)


##  useful commands
- setting new app icon -> flutter pub get then flutter pub run flutter_launcher_icons:main
