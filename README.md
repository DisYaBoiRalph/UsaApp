# OffChat

Peer-to-peer messaging for nearby devices, built with Flutter. OffChat lets you spin up an ad-hoc chat without relying on the internet or a backend service.

## Features

- **Guided onboarding** that walks through the required location, Wi-Fi, Bluetooth, and storage permissions and verifies device readiness before the first chat.
- **Peer-to-peer session manager** where users decide to host a hotspot or join an advertised session, with live discovery, connection state, and troubleshooting feedback.
- **Real-time messaging UI** including delivery banners, automatic scroll to latest messages, sender attribution, and conversation metadata sharing between peers.
- **Conversation library** that stores history locally, allows creating, renaming, deleting chats, and viewing full transcripts even after the P2P session ends.
- **Identity and settings** page to configure the display name, review device code, and trigger permission/service setup checks at any time.
- **Offline-first storage** backed by `shared_preferences`, persisting conversations, onboarding status, peer identities, and session preferences between app launches.

## Architecture Highlights

- Modular `lib/src/features/*` structure separating onboarding, chat, settings, and P2P logic with dedicated controllers and pages.
- `AppDependencies` bootstrapper that wires repositories, controllers, and shared services (chat persistence, peer identity, P2P transport).
- Custom `P2pSessionController` on top of `flutter_p2p_connection` orchestrates Wi-Fi Direct hosting, device discovery, and text payload exchange.
- `ConversationStore` and chat use-cases (`SendMessage`, `WatchMessages`) provide a clean interface for persisting and streaming chats to the UI.
- Centralized `OnboardingService` decides the initial route and tracks completion, while `SettingsController` keeps permission/service status in sync.

## Getting Started

1. Install [Flutter](https://docs.flutter.dev/get-started/install) 3.9.0 or newer.
2. From the project root run `flutter pub get`.
3. Connect an Android device (Wi-Fi Direct APIs are Android-only with the current dependencies) and enable developer mode.
4. Launch the app with `flutter run`.

> On first launch, the onboarding flow will request the permissions needed for Wi-Fi Direct, Bluetooth, and local storage. You can revisit these checks later under Settings.

## Running Tests

Execute the widget and feature tests with:

```
flutter test
```

## Key Packages

- `flutter_p2p_connection` – Wi-Fi Direct and BLE discovery/transport.
- `permission_handler` – granular runtime permission management.
- `shared_preferences` – lightweight local persistence for chats and identity.

## Project Layout

- `lib/main.dart` – app bootstrap, dependency initialization, routing entry point.
- `lib/src/features/chat/` – conversation data sources, controllers, and chat UI.
- `lib/src/features/p2p/` – session controller and service bindings for host/client roles.
- `lib/src/features/onboarding/` – onboarding flow UI and first-launch setup.
- `lib/src/features/settings/` – settings screen, display name management, and permission checks.
- `test/` – widget and feature tests covering onboarding, chat flows, and services.

## Roadmap Ideas

- File attachment support during sessions.
- Multi-device synchronization strategy once the host leaves.
- iOS support when peer-to-peer transport plugins become available.
