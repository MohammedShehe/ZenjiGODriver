# ZenjiGO Driver Frontend

A complete Flutter frontend prototype for **ZenjiGO Driver**, designed for drivers providing Boda, Bajaji and Taxi ride services.

## Implemented flows

- Onboarding / About ZenjiGO with English / Kiswahili preference UI
- Location and updates permissions UI
- Multi-step driver registration
- Phone and email OTP verification UI
- Vehicle information
- Driver license, national ID, insurance, up to 5 vehicle photos and driver photo upload UI
- Manual application tracking: Pending → Under Review → Approved / Rejected → Active
- Four-tab shell: Home, Earnings, Chat and Profile
- Driver online/offline state
- Nearby ride request presentation and accept/reject flow
- Active ride: pickup, arrived, start ride, live-progress map simulation, end ride and fare summary
- Rider profile, call/chat actions, report rider confirmation and ZenjiGO support options
- Earnings charts, commission breakdown, incentives and wallet history
- Withdrawal flow for M-Pesa, YAS and bank transfer with required payout details
- WhatsApp-inspired chats with support pinned first, edit/reply/delete message interactions and translation toggle
- Driver profile, ratings/reviews, verified document management
- Admin-reviewed profile update requests
- License / insurance renewal requests with upload and review status messaging
- English / Kiswahili preference, dark/light mode and emergency/support screen
- Responsive layouts and Android back-navigation handling
- Loading indicators for primary asynchronous-style actions
- ZenjiGO branding, logos and app icon across Android, iOS, web and Windows

## Theme

Dark mode is the initial app mode. Both supplied `logo_dark.png` and `logo_light.png` are used according to the current brightness.

## Backend integration notes

This package intentionally contains **frontend only**. Network calls, real OTP, real file picker/upload, real map/GPS, payment withdrawals, phone/email intents, push notifications and chat transport are represented by complete UI states and clearly marked integration points. Replace the mock delays/data with your services when the backend is ready.

For production integration, typical Flutter packages can include a map provider, geolocation/permission package, image/file picker, HTTP client, secure storage, push notification service and WebSocket/chat transport.

## Run locally

```bash
flutter pub get
flutter analyze
flutter run
```

The supplied template targets Dart SDK `^3.10.4`.
