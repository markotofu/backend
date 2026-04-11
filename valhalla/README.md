# Valhalla (Routing) – Local Server

This folder runs a free, self-hosted routing server (Valhalla) that your Flutter app can call to get the **shortest** driving route and avoid incident points.

## Prereqs
- Docker Desktop (Windows)

## Start the server
From repo root:

```powershell
cd Valhalla
docker compose up -d
```

First run will download the PBF and build routing tiles (can take a while + lots of disk).

## Health check

In Windows PowerShell, `curl` is an alias of `Invoke-WebRequest`, so prefer `curl.exe`:

```powershell
curl.exe http://localhost:8002/status
# or
Invoke-RestMethod http://localhost:8002/status
```

### Important: first build is not instantly ready
On first run, the container downloads the OSM PBF and builds routing tiles. While that is happening, the container may be **Up** in `docker compose ps` but `/status` can return:
- `curl: (52) Empty reply from server`
- or connections that close early

That just means tiles are still being built.

Watch logs until you see the build finish and the service start serving requests:

```powershell
docker logs -f valhalla_davao
```

### If you see "Connection closed before full header was received"
That almost always means the Valhalla container is **restarting/crashing** (often due to high RAM/disk usage while building tiles), or something is blocking port 8002.

Check container + logs:

```powershell
cd Valhalla
docker compose ps
docker logs --tail 200 valhalla_davao
```

If `curl.exe http://localhost:8002/status` works on your laptop but Flutter (emulator) fails to reach `http://10.0.2.2:8002`, add a Windows Firewall inbound rule for **TCP 8002** (or allow Docker Desktop).

## Test (route)

```powershell
curl.exe -X POST http://localhost:8002/route `
  -H "Content-Type: application/json" `
  -d "{\"locations\":[{\"lat\":7.0731,\"lon\":125.6128},{\"lat\":7.1907,\"lon\":125.4553}],\"costing\":\"auto\",\"costing_options\":{\"auto\":{\"shortest\":true,\"disable_hierarchy_pruning\":true}},\"format\":\"osrm\",\"shape_format\":\"geojson\"}"
```

## Avoid incidents
Valhalla supports `exclude_locations` which maps each point to the nearest road(s) and excludes them.

Example:

```json
{
  "locations": [
    {"lat": 7.0731, "lon": 125.6128},
    {"lat": 7.1907, "lon": 125.4553}
  ],
  "exclude_locations": [
    {"lat": 7.1000, "lon": 125.6000, "radius": 50}
  ],
  "costing": "auto",
  "costing_options": {"auto": {"shortest": true, "disable_hierarchy_pruning": true}},
  "format": "osrm",
  "shape_format": "geojson"
}
```

## Davao-only behavior

Even if Valhalla is built from a larger OSM extract, the Flutter UI limits selection to Davao City (see `FlutterEXAM/lib/map_page.dart`). This means routing in the app will effectively be Davao-only.

Valhalla itself can only route where tiles exist. If you build tiles from the full Philippines extract, Valhalla can route anywhere in that coverage, but the app will still restrict user inputs to Davao.

## Using on a physical phone
- Run the Valhalla container on your laptop.
- Put phone + laptop on the same Wi-Fi.
- Use `http://<YOUR_LAPTOP_LAN_IP>:8002` as the base URL.
- In Flutter run:

```powershell
flutter run --dart-define=VALHALLA_URL=http://<YOUR_LAPTOP_LAN_IP>:8002
```

### Android emulator note
From the Android emulator, `http://10.0.2.2:8002` points to your host machine.
