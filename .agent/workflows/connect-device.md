---
description: Set up ADB reverse port forwarding to connect a physical Android device to the local Flask server
---

# Connect Physical Device to Local Server

Run this workflow each time you reconnect your phone via USB to enable the mobile app to reach the backend server.

## Steps

// turbo
1. Set up ADB reverse port forwarding so the phone can reach the Flask server through USB:
```powershell
C:\Users\fatimetou\AppData\Local\Android\Sdk\platform-tools\adb.exe reverse tcp:3000 tcp:3000
```

2. Verify the Flask server is running on port 3000:
```powershell
netstat -an | findstr ":3000"
```
You should see `0.0.0.0:3000 LISTENING`.

3. Hot-restart the Flutter app (press `R` in the Flutter terminal or rebuild the app).

## Troubleshooting

- If step 1 fails with "no devices found", make sure USB debugging is enabled on your phone and the phone is connected.
- If the server isn't listening, start it with `python app.py` from the `OngWeb` directory.
- The `api_constants.dart` file should have `_physicalDeviceBaseUrl` set to `http://127.0.0.1:3000/api` for this to work.
