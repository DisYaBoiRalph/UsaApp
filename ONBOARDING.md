# OffChat - P2P Setup Guide

## Overview

OffChat now includes a comprehensive onboarding screen that appears on first launch. This screen:

1. Welcomes users to the app
2. Explains why each permission is needed
3. Guides users through the P2P setup process
4. Only shows once - subsequent launches go straight to the home screen

## What Was Added

### 1. Onboarding Screen (`lib/src/features/onboarding/presentation/pages/onboarding_page.dart`)
- **3-page flow**: Welcome → Permissions Explanation → Setup
- **Permission requests**: Storage, P2P (WiFi Direct), Bluetooth, and Location  
- **Service enablement**: WiFi, Location, and Bluetooth
- **Progress tracking**: Shows setup status and completion

### 2. P2P Service (`lib/src/features/p2p/data/services/p2p_service.dart`)
- Wraps all `flutter_p2p_connection` functionality
- Provides methods to check and request permissions
- Provides methods to check and enable services
- Centralized logging for debugging

### 3. Settings Controller (`lib/src/features/settings/presentation/controllers/settings_controller.dart`)
- Manages P2P setup state
- Tracks permission and service status
- Provides reactive UI updates

### 4. Updated Settings Page
- Shows real-time P2P setup status
- Interactive "Setup" buttons for permissions and services
- Visual indicators (green checkmarks when ready)
- Success message when P2P is fully configured

## How It Works on First Launch

1. **App opens** → Onboarding screen appears
2. **Page 1**: Welcome message explaining the app
3. **Page 2**: Lists all required permissions with explanations
4. **Page 3**: "Start Setup" button triggers:
   - Permission requests (Storage, P2P, Bluetooth)
   - Service enablement prompts (WiFi, Location, Bluetooth)
   - Status updates as each step completes
5. **Setup complete** → "Get Started" button becomes active
6. **Tap "Get Started"** → Navigate to home screen
7. **Future launches** → Skip directly to home screen

## Manual Setup (via Settings)

Users can also manage P2P setup later:

1. Navigate to **Settings** from the home screen
2. See **P2P Connection Setup** section
3. Tap "Setup" on **Permissions** card to grant permissions
4. Tap "Setup" on **Services** card to enable WiFi/Location/Bluetooth
5. Green success banner appears when everything is ready

## For Development

### Testing the Onboarding
Currently, onboarding state is stored in memory. To test it again:
- Restart the app (hot restart)
- The onboarding will show again on first run

### Making Onboarding Persistent
To make the onboarding state persist across app restarts:

1. Add `shared_preferences` to `pubspec.yaml`
2. Uncomment TODOs in `lib/src/core/services/onboarding_service.dart`
3. Replace in-memory storage with SharedPreferences

```dart
// In onboarding_service.dart, replace:
static bool _hasCompletedOnboarding = false;

// With:
final prefs = await SharedPreferences.getInstance();
return prefs.getBool('has_completed_onboarding') ?? false;
```

## Files Modified/Created

### Created:
- `lib/src/features/onboarding/presentation/pages/onboarding_page.dart`
- `lib/src/features/p2p/data/services/p2p_service.dart`
- `lib/src/features/settings/presentation/controllers/settings_controller.dart`
- `lib/src/core/services/onboarding_service.dart`

### Modified:
- `lib/src/app/offchat_app.dart` - Routes to onboarding on first launch
- `lib/src/app/routes/app_router.dart` - Added onboarding route
- `lib/src/app/di/app_dependencies.dart` - Initialize P2P service
- `lib/src/features/settings/presentation/pages/settings_page.dart` - P2P setup UI
- `android/app/build.gradle.kts` - Set minSdk to 28 (Android 9.0+)

## Next Steps

- [ ] Add SharedPreferences for persistent onboarding state
- [ ] Implement actual P2P device discovery
- [ ] Connect P2P to chat functionality
- [ ] Add error handling for permission denials
- [ ] Test on physical Android devices (API 28+)
