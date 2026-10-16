# ZenjiGO Driver

Flutter Driver app for **ZenjiGO** — fully wired to the ZenjiGO backend API.

## Integrated flows (live API)

| Flow | Endpoint(s) |
|------|-------------|
| Send OTP | `POST /auth/driver/send-otp` |
| Login | `POST /auth/driver/login` |
| Multi-step registration + document upload | `POST /driver/register` (multipart) |
| Profile restore on launch | `GET /driver/me` |
| Go online / offline | `PATCH /driver/online` |
| Ride requests | `GET /driver/ride-requests` |
| Accept ride | `POST /driver/rides/:id/accept` |
| Ride status (arriving → arrived → started → completed) | `PATCH /driver/rides/:id/status` |
| Finance / settlement status | `GET /driver/finance` |
| Create settlement | `POST /driver/settlements` |
| Autopay toggle | `POST /driver/autopay` |
| Withdrawal / payout request | `POST /driver/payout` |
| Chat conversations | `GET /driver/chat` |
| Sign out | clears tokens + `POST /auth/logout` |
| Token refresh | automatic on 401 via `POST /auth/refresh` |

## Still UI-assisted (no hardware dependency in this package)

- Map rendering uses an in-app mock map widget (swap for Google Maps / Mapbox when you add the SDK key)
- GPS coordinates are not streamed continuously (call `DriverApi.updateLocation` from a geolocator timer when you add the package)
- In-conversation chat messages remain local until you connect Socket.IO or poll `DriverApi.messages`
- FCM push requires Firebase project wiring (`DriverApi.registerFcmToken`)

## Configure API base URL

Default: `http://localhost:5000/api/v1`

Override at build time:

```bash
flutter run --dart-define=ZENJIGO_API_URL=http://10.0.2.2:5000/api/v1
```

- Android emulator → `http://10.0.2.2:5000/api/v1`
- iOS simulator → `http://localhost:5000/api/v1`
- Physical device → your machine LAN IP

## Run

```bash
# Backend must be running first
cd ../ZenjiGOAdmin/backend   # or your backend path
npm install && npm run migrate && npm run seed && npm run dev

# Driver app
cd zenjigodriver
flutter pub get
flutter run --dart-define=ZENJIGO_API_URL=http://10.0.2.2:5000/api/v1
```

## Auth flow

1. Register (or use an admin-approved driver account)
2. Sign in with phone → OTP (Twilio Verify when configured)
3. JWT access + refresh tokens stored in SharedPreferences

## Theme

Dark mode is the default. English / Kiswahili toggle is available in Settings.
