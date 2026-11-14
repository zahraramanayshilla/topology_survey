# Topo Survey (Android / Flutter)

Alat survei topografi dari HP Android: titik ketinggian (barometer diferensial) +
posisi (multilaterasi BLE diperkuat/fusi GPS), minimal 3 HP Anchor + 1 Rover.

## Struktur
lib/
  algorithms/  trilateration (3 anchor, bentuk tertutup), multilateration (>=3, Gauss-Newton),
               gps_fusion (LocalFrame, Barometry, fusi BLE+GPS, PositionEstimator)
  models/      device_data (paket BLE anchor), survey_point
  services/    ble_service (scan + advertise), gps_service (GPS + barometer), database_service (SQLite + CSV)
  screens/     dashboard (shell), devices (anchor & kalibrasi), survey, map, history
  widgets/     coordinate_card, device_status_card

## CI
Push ke `main` -> build APK -> tag `v1.0.<run>` -> GitHub Release + APK.
