# new_project

Flutter mobile app for Aesthetic CRM.

## Visits API Connection

`Visits`, `Today's Visits`, and `My Visits` now load from your website API route:

- `GET /api/visit-schedule`

The app uses runtime config from `--dart-define`:

- `API_BASE_URL` (required for real backend)
- `API_AUTH_TOKEN` (required if your backend expects bearer auth)

Example run command:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://your-crm-domain.com \
  --dart-define=API_AUTH_TOKEN=your_mobile_token_here
```

For Android emulator local backend, use:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

## Important Auth Note

Your Next.js endpoint uses `requireDatabaseRoles(...)` with Clerk auth. That means mobile requests must be authenticated, otherwise the API returns `401` / `403`.

Recommended production approach:

1. Use Clerk Flutter SDK for sign-in on mobile.
2. Send Clerk token to backend in `Authorization: Bearer ...`.
3. Update backend auth middleware to validate bearer tokens for mobile requests.

Alternative approach:

1. Build a dedicated mobile gateway endpoint (server-to-server).
2. Keep website auth as-is.
3. Mobile calls only that gateway.

## Project Status

- Visit API layer added at `lib/data/visits/visit_api_service.dart`.
- Visit model added at `lib/data/visits/visit.dart`.
- API runtime config added at `lib/config/app_config.dart`.
- Screens connected to API:
  - `lib/screens/visit_team/visits_screen.dart`
  - `lib/screens/visit_team/today_visits_screen.dart`
  - `lib/screens/visit_team/my_visits_screen.dart`
