# System Overview (Flutter + Supabase + Valhalla)

This repository is a **Davao City traffic/incident reporting + routing** app built with:
- **Flutter** (UI + map)
- **Supabase** (Auth + Postgres + Row Level Security)
- **Valhalla (optional)** via Docker (routing + alternative route that avoids hazards)

If you want “how to run it”, see: `QUICK_START.md`.

---

## 1) Main components

### Flutter app (`FlutterEXAM/`)
**Navigation** is in `FlutterEXAM\lib\home_screen.dart` with these screens:
- **Dashboard** (`dashboard_page.dart`) – grouped list of zones that currently have active traffic/incidents
- **Map** (`map_page.dart`) – pick Point A/B and request routes; show hazard pins; tap pins to view details
- **Reporting** (`reporting_page.dart`) – drop a pin, fill a form, submit a traffic/incident report
- **Details** (`details_page.dart`) – project info page
- **My Account** (`my_account_page.dart`) – user/account info page

### Supabase (Auth + DB)
- Auth users live in `auth.users`
- App-level profiles live in `public.accounts` (role, username, active flag)
- Reporting data lives in `public.zones`, `public.traffic`, `public.incidents`, `public.traffic_log`

### Valhalla routing server (`Valhalla/`)
Optional Docker service. The Flutter app calls:
- `GET /status` (health)
- `POST /route` (OSRM-style response with GeoJSON line)

Docs: `Valhalla\README.md`

---

## 2) Database schema (what the app expects)

### A) Accounts (created automatically on signup)
**Goal:** Every `auth.users` row should have a matching row in `public.accounts`.

Implemented in:
- `backend\06_accounts_trigger_on_signup.sql`

How it works:
- A trigger runs **AFTER INSERT ON auth.users**
- It inserts into `public.accounts(auth_user_id, username)`
- The table defaults handle:
  - `role` default (User)
  - `isActive` default (true)

Username is derived from:
1) `raw_user_meta_data.username`
2) email prefix
3) `user<timestamp>` fallback

### B) Zones + Traffic + Incidents (pins)
Implemented in:
- `backend\09_zones_traffic_incidents.sql`

Tables:
- `public.zones`
  - `zone_id` (PK)
  - `district_name`, `latitude`, `longitude`
- `public.traffic`
  - `traffic_id` (PK)
  - `zone_id` (FK → zones)
  - `traffic_status` (Light/Moderate/Heavy/Blocked)
  - `reported_at`, `cancelled_at`, `description`
- `public.incidents`
  - `incident_id` (PK)
  - `incident_type` (Accident, Flooding, …)
  - `incident_status` (Reported/In Progress/Resolved/Cancelled)
  - `reported_at`, `resolved_at`, `cancelled_at`, `description`
  - `cancelled_by` (FK → accounts.id)
  - `zone_id` (FK → zones)
  - `deleted_at`
- `public.traffic_log`
  - `traffic_log_id` (PK)
  - `traffic_id` (FK → traffic)
  - `updated_by` (FK → accounts.id)
  - `updated_at`

---

## 3) Security & permissions (RLS)

RLS is enabled in `backend\09_zones_traffic_incidents.sql`.

Key rules:
- Any authenticated user can **read** zones/traffic/incidents/log.
- Any authenticated user can **insert**:
  - `zones`
  - `traffic`
- Only **CTTMO** or **ADMIN** can **insert** `incidents`.
- `traffic_log` insert requires `updated_by = public.current_account_id()`.

The UI also enforces this rule (but the DB is the real authority).

---

## 4) How pins are loaded (Map, Reporting, Dashboard)

Pins are represented by the `Incident` model:
- `FlutterEXAM\lib\incident.dart`

Data loading happens in:
- `FlutterEXAM\lib\incident_service.dart` → `fetchActiveHazards()`

It fetches:
- **Active traffic**: `traffic.cancelled_at IS NULL`
- **Active incidents**: `incidents.deleted_at IS NULL` AND `incident_status IN ('Reported','In Progress')`

Both queries join to `zones` to get the **pin coordinates**.

Note: there’s a fallback path for older DBs (legacy `public.incidents` with `is_active`) if the new schema isn’t installed.

---

## 5) Reporting flow (create a pin + report)

Screen: `FlutterEXAM\lib\reporting_page.dart`

Flow:
1) Load current user’s account profile (`AuthService.getUserProfile()`) to get:
   - `role` (User / ADMIN / CTTMO)
   - `accountId` (accounts.id)
2) User taps on the map to drop a **report pin** (must be inside Davao bounds)
3) On submit:
   - Insert a new `zones` row using pin lat/lon + district name
   - If report type is **traffic**:
     - Insert `traffic` row
     - Insert `traffic_log` row (best-effort)
   - If report type is **incident**:
     - Insert `incidents` row (DB policy allows only CTTMO/ADMIN)
4) Refresh pins so the new report appears immediately

Role rule:
- **User**: traffic only
- **CTTMO/ADMIN**: traffic + incidents

---

## 6) Map routing flow (original + alternative route)

Screen: `FlutterEXAM\lib\map_page.dart`

Behavior:
- User taps to set **Point A** and **Point B** (must be inside Davao bounds)
- App draws hazard pins (traffic + incidents)
- On “Route”:
  1) Compute **original route** (green) with no excludes
  2) If hazards exist, compute **alternative route** (yellow) that avoids hazards

Routing implementation:
- `FlutterEXAM\lib\valhalla_routing_service.dart`

Key ideas:
- Uses Valhalla `exclude_locations` generated from hazard pins.
- Increases snapping radius for tapped points (`radius: 200`) so slightly-off-road taps still route.

Valhalla base URL configuration:
- `FlutterEXAM\lib\routing_config.dart`
- Uses `--dart-define=VALHALLA_URL=http://...` (default: emulator `http://10.0.2.2:8002`)

---

## 7) Davao-only map behavior + no rotation

Both Map and Reporting screens:
- Constrain camera to a Davao bounding box via `cameraConstraint: contain(bounds: ...)`
- Reject taps outside Davao bounds
- Disable map rotation while keeping pan/zoom:
  - `InteractiveFlag.all & ~InteractiveFlag.rotate`

---

## 8) Dashboard behavior (grouping + auto reload)

Screen: `FlutterEXAM\lib\dashboard_page.dart`

What it shows:
- A list of **zones that have active traffic/incidents**.
- If multiple zone rows share the same `district_name` (ex: “Sasa”), they are **collapsed into one category** by case-insensitive name.

Reload-on-open:
- `HomeScreen` increments `reloadToken` whenever “Dashboard” is selected.
- `DashboardPage.didUpdateWidget` detects token changes and refreshes.

---

## 9) Authentication overview (Email, Guest, Google)

Auth logic:
- `FlutterEXAM\lib\auth_service.dart`

Supported sign-in methods:
- Email/password
- Guest (creates a Supabase auth user with generated email/password + metadata)
- Google Sign-In → Supabase `signInWithIdToken`

Important for Google:
- The app requires an **ID token** (not just access token).
- You must run with: `--dart-define=GOOGLE_WEB_CLIENT_ID=<your web client id>`
  - Otherwise you’ll see: **“Missing Google ID token”**

---

## 10) Common troubleshooting

### Valhalla: `/status` returns empty reply / connection closes
Usually tiles are still building on first run. See `Valhalla\README.md`.

### Valhalla: `impossible route between points`
Try tapping closer to roads (snapping helps, but can’t solve all cases).

### Supabase insert fails for incidents
Expected if user role is not CTTMO/ADMIN (RLS policy blocks it).

### “Missing account profile” on reporting
Usually means the `public.accounts` trigger/backfill hasn’t been run yet.
Run `backend\05_setup_accounts_table.sql` then `backend\06_accounts_trigger_on_signup.sql`.
