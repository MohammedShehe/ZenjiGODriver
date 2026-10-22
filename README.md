# ZenjiGO Driver — Flutter

Flutter driver app aligned with the driver portal in `ZenjiGOWeb`.

## Driver flow

- Sign in using the registered email address only. No phone number is requested or phone verification performed. The app sends `email` and `purpose: "login"` to `POST /auth/driver/send-otp`, then sends `email` and `code` to `POST /auth/driver/login`. Empty or malformed email values are blocked by form validation. The backend must support email-only driver login on these existing endpoints.
- Restore the authenticated driver profile.
- Go online/offline through `PATCH /driver/online`.
- Receive real requests by polling `GET /driver/ride-requests`; accept using `POST /driver/rides/:id/accept`.
- Ride status actions follow the portal sequence: `arriving` → `arrived` → `started` → `completed`, through `PATCH /driver/rides/:id/status`.
- During online availability and active rides, device GPS is read with the platform location APIs and sent to `POST /driver/location`.
- The map uses the native Google Maps SDK and displays the driver's current position plus pickup/drop-off/request markers only when real coordinates are returned by the backend.
- Finance, settlements, payout, profile, history and chat use the same `/api/v1` driver routes as the web portal.

## API base URL

Set the backend URL at build/run time. It must be reachable from the device:

```bash
flutter pub get
# Android emulator talking to backend on the host machine:
flutter run --dart-define=ZENJIGO_API_URL=http://10.0.2.2:5000/api/v1
# Physical Android device: use your computer's LAN IP, e.g. 192.168.x.x
# iOS simulator: typically http://127.0.0.1:5000/api/v1
```

For production, use the deployed HTTPS API base, e.g. `--dart-define=ZENJIGO_API_URL=https://YOUR-BACKEND-HOST/api/v1`.
The backend must allow the app's network origin where relevant and the URL must be reachable from the device. The code uses the same route paths as `ZenjiGOWeb/js/api.js`.

## Google Maps and GPS

The web portal's Google Maps browser key is currently wired as the native map key in:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/AppDelegate.swift`

Google Cloud API keys may be restricted by platform. For a production app, create/authorize a native key with **Maps SDK for Android** and **Maps SDK for iOS** enabled, apply Android package/SHA restrictions and iOS bundle restrictions, and replace the key in those two files. Do not use an HTTP-referrer-only browser key for native apps. Enable location permission prompts in Android/iOS settings if the device has denied access. GPS sharing is best-effort while the device has a valid location fix and network connection.

## Endpoints used

| Purpose | Endpoint |
|---|---|
| Send driver email OTP (email-only login) | `POST /auth/driver/send-otp` |
| Login | `POST /auth/driver/login` |
| Register driver + documents | `POST /driver/register` (multipart) |
| Profile | `GET /driver/me` |
| Online/offline | `PATCH /driver/online` |
| Current location | `POST /driver/location` |
| Ride requests | `GET /driver/ride-requests` |
| Accept ride | `POST /driver/rides/:id/accept` |
| Ride status | `PATCH /driver/rides/:id/status` |
| Ride history | `GET /driver/rides?limit=50` |
| Finance / earnings | `GET /driver/finance`, `GET /driver/earnings` |
| Settlement | `GET/POST /driver/settlements`, `GET /driver/settlements/:id` |
| Payout | `POST /driver/payout` |
| Chat | `GET /driver/chat`, `POST /driver/chat/:id/messages` |

## Login contract note

This build intentionally removes phone verification from driver sign-in. If the backend login controller currently requires `phone` in `/auth/driver/login`, update its validation and driver lookup to authenticate by email plus OTP; the mobile client will not submit a phone number. Registration may still request a phone number as driver profile data, but it is not used for login verification.

## Important verification note

This ZIP contains source code, not a signed release build. It was updated in this environment but could not be compiled or exercised against your deployed backend because Flutter tooling and live backend credentials were unavailable here. Before release, run `flutter pub get`, `flutter analyze`, and test each ride status transition with your staging backend. Payment-provider settlement, push notifications, and rider reporting still depend on the backend/provider being configured.
