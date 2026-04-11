# QUICK START (from clone to running)

This repo contains:
- `FlutterEXAM/` → Flutter app
- `backend/` → Supabase SQL scripts (schema + triggers + RLS)
- `Valhalla/` → optional local routing server (Docker)

## 0) Prerequisites

Install these first:
- **Git** (to clone)
- **Flutter SDK** (stable)
- **Android Studio** (Android SDK + emulator) or a physical Android device
- **Docker Desktop** (optional, only if you want routing via Valhalla)

Verify Flutter:

```powershell
flutter doctor -v
```

## 1) Get the code

### Option A: Clone with Git

```powershell
git clone <REPO_URL>
cd finalflutterproject
```

### Option B: Download ZIP

1. Download ZIP from GitHub
2. Extract
3. Open a terminal in the extracted folder

## 2) Open the project correctly

Open the **repo root** folder in VS Code:

- `finalflutterproject/`

The Flutter project lives in:
- `finalflutterproject/FlutterEXAM/`

## 3) Install Flutter dependencies

```powershell
cd FlutterEXAM
flutter pub get
```

## 4) Supabase setup (database + auth)

### 4.1 Configure Supabase URL / anon key

The app initializes Supabase in `FlutterEXAM/lib/main.dart` using:
- `FlutterEXAM/lib/supabase_config.dart`

If you are using your **own** Supabase project, replace:
- `SupabaseConfig.supabaseUrl`
- `SupabaseConfig.supabaseAnonKey`

> Note: **Anon keys are meant for client apps**. Never commit a service-role key.

### 4.2 Run the backend SQL scripts (required for traffic/incidents)

In Supabase Dashboard → **SQL Editor**, run these files from `backend/`:

1. `05_setup_accounts_table.sql`
2. `06_accounts_trigger_on_signup.sql`
3. `07_fix_accounts_autocreate.sql`
4. `09_zones_traffic_incidents.sql`

These create:
- `public.accounts` auto-created from `auth.users`
- `zones`, `traffic`, `incidents`, `traffic_log` (+ enums)
- RLS policies for reading/reporting

### 4.3 (Optional) Set roles for testing

To test incident reporting:
- set your row in `public.accounts.role` to `ADMIN` or `CTTMO`

Regular `User` accounts can only report traffic.

## 5) (Optional) Start routing server (Valhalla + Docker)

Routing uses Valhalla at port `8002`.

```powershell
cd ..
cd Valhalla
docker compose up -d
```

### 5.1 Wait for first-time tile build

First run downloads OSM data and builds tiles. During this, the container may be "Up" but `/status` can return an empty reply.

Watch logs:

```powershell
docker logs -f valhalla_davao
```

### 5.2 Health check

PowerShell note: `curl` is an alias of `Invoke-WebRequest`, so use `curl.exe`:

```powershell
curl.exe http://localhost:8002/status
# or
Invoke-RestMethod http://localhost:8002/status
```

### 5.3 Point the Flutter app to Valhalla

- **Android emulator**: default is `http://10.0.2.2:8002` (already set)
- **Physical phone (same Wi-Fi)**:

```powershell
cd ..
cd FlutterEXAM
flutter run --dart-define=VALHALLA_URL=http://<YOUR_LAPTOP_LAN_IP>:8002
```

If the emulator can’t reach Valhalla, allow inbound TCP **8002** in Windows Firewall / Docker Desktop.

## 6) Run the app

From `FlutterEXAM/`:

```powershell
flutter devices
flutter run
```

## 7) Quick smoke test

1. Sign up / sign in
2. Confirm `public.accounts` row was created for the user
3. Open **Dashboard** → zones should group traffic/incidents
4. Open **Reporting** → drop a pin and submit a traffic report
5. Open **Map** → tap 2 points within Davao and route
   - Green polyline = original
   - Yellow polyline = alternative (avoid hazard pins), best-effort

## Troubleshooting

### "No devices"

```powershell
flutter devices
```
Start an emulator in Android Studio if needed.

### Routing errors

- `Empty reply from server` / connection closed: Valhalla is likely still building tiles (check logs)
- `impossible route between points`: try points closer to roads

### Supabase pins not loading

- Ensure you ran `backend/09_zones_traffic_incidents.sql`
- Ensure you are logged in (RLS may block anonymous access)

### Build issues

```powershell
cd FlutterEXAM
flutter clean
flutter pub get
flutter run
```
