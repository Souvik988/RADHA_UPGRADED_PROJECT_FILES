# Android Emulator Setup — Troubleshooting & Manual Runbook

A self-contained recipe for getting an Android emulator running on this Windows host so `mobile-mcp` can drive the RADHA Flutter app for manual testing. Use this when the automated install pipeline failed, partially completed, or you want to know what it actually did.

The pipeline has six layers, each one depending on the previous:

```
JDK 17  →  Android cmdline-tools  →  SDK packages  →  AVD  →  Emulator boot  →  mobile-mcp
```

If any layer breaks, the layers above it cannot work. Diagnose top-down.

For the Chrome web smoke path (which does **not** require any of this), see `MOBILE_SMOKE_TEST_RUNBOOK.md` Option A — that is the recommended path on a stock Windows machine. Use this document only when you specifically need an Android emulator (e.g. to test camera-bound flows like `mobile_scanner` or `google_mlkit_text_recognition`).

---

## 1. Overview

### What we are building
A working Android Virtual Device (AVD) on this Windows host running Android 14 (API 34) with Google APIs, x86_64 ABI. Once it boots, `adb` exposes it as `emulator-5554`, and `mobile-mcp` can drive the RADHA Flutter app (`com.radha.mobile`) end-to-end through accessibility events.

### Hardware / OS requirements
- Windows 10 (build 19041+) or Windows 11
- ~8 GB free disk space (cmdline-tools 200 MB, system image 1.5 GB, AVD 4–6 GB)
- 8 GB RAM minimum, 16 GB recommended
- Hardware virtualization (Intel VT-x / AMD-V) **enabled in BIOS** — see Section 3
- 64-bit CPU with SSE4.1 (any CPU from ~2012 onwards)

### Software stack (in install order)
| Layer | What it provides | Where it lives |
|---|---|---|
| JDK 17 (Temurin) | `java.exe` runtime for `sdkmanager` | `C:\Java\jdk-17\` |
| Android cmdline-tools | `sdkmanager.bat`, `avdmanager.bat` | `C:\Android\cmdline-tools\latest\bin\` |
| SDK packages | platform-tools (`adb`), platform 34, build-tools, emulator binary, system image | `C:\Android\` |
| AVD | The virtual device config + user data | `%USERPROFILE%\.android\avd\RadhaPixel.avd\` |
| Emulator process | The actual running VM | `emulator-5554` |
| mobile-mcp | Kiro's bridge from MCP tools to `adb` | restarted via Kiro UI |

---

## 2. Step-by-step manual install

Run these in order. Each step has an **Expected output** and an **If this fails** section. All commands are written for `cmd.exe` — paste them as-is.

### 2.1 Install JDK 17 (Adoptium Temurin)

The Android `sdkmanager.bat` requires Java 17 specifically. Java 8 fails with class-version errors; Java 11 sometimes works but is unsupported by current cmdline-tools.

Download the `.zip` (no installer needed):

```cmd
cmd /c "curl -L -o %TEMP%\jdk-17.zip https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse"
```

Extract to `C:\Java\jdk-17\`:

```cmd
cmd /c "powershell -NoProfile -Command Expand-Archive -Path $env:TEMP\jdk-17.zip -DestinationPath C:\Java\_jdk-stage -Force"
cmd /c "for /d %D in (C:\Java\_jdk-stage\jdk-17*) do move %D C:\Java\jdk-17"
cmd /c "rmdir /s /q C:\Java\_jdk-stage"
```

Verify:

```cmd
cmd /c "C:\Java\jdk-17\bin\java.exe -version"
```

Expected output:

```
openjdk version "17.0.x" 2024-xx-xx
OpenJDK Runtime Environment Temurin-17.0.x+xx (build 17.0.x+xx)
OpenJDK 64-Bit Server VM Temurin-17.0.x+xx (build 17.0.x+xx, mixed mode, sharing)
```

**If this fails:**
- `'java' is not recognized` — extraction landed in a nested folder. Re-run the `for /d %D` line and confirm `C:\Java\jdk-17\bin\java.exe` exists.
- The download URL serves a redirect; use `curl -L` (capital L) to follow it. Without `-L` you get a 0-byte file.

### 2.2 Install Android cmdline-tools

Exact URL used by the install pipeline:

```cmd
cmd /c "curl -L -o %TEMP%\cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
```

Verify the download is ~120 MB (anything under 50 MB is a redirect/HTML error page):

```cmd
cmd /c "dir %TEMP%\cmdline-tools.zip"
```

Extract to the **exact** path Google's tooling expects (`C:\Android\cmdline-tools\latest\`):

```cmd
cmd /c "powershell -NoProfile -Command Expand-Archive -Path $env:TEMP\cmdline-tools.zip -DestinationPath %TEMP%\cmdline-tools-stage -Force"
cmd /c "if not exist C:\Android\cmdline-tools mkdir C:\Android\cmdline-tools"
cmd /c "if exist C:\Android\cmdline-tools\latest rmdir /s /q C:\Android\cmdline-tools\latest"
cmd /c "move %TEMP%\cmdline-tools-stage\cmdline-tools C:\Android\cmdline-tools\latest"
```

The directory layout **must** end up as:

```
C:\Android\cmdline-tools\latest\
  bin\
    sdkmanager.bat
    avdmanager.bat
  lib\
  source.properties
```

If you extract into `C:\Android\cmdline-tools\` directly without the `latest\` rename, `sdkmanager` will refuse to run (it inspects its own path to discover the SDK root).

**If this fails:**
- "Cannot find sdkmanager.bat" — your zip extracted with a different inner folder. List `%TEMP%\cmdline-tools-stage` and move the actual `cmdline-tools\` folder, not its parent.
- "Access denied" creating `C:\Android\` — open `cmd` as Administrator once to create the folder, then chmod ownership to your user.

### 2.3 Set environment variables

`JAVA_HOME` must point to JDK 17. `ANDROID_HOME` and `ANDROID_SDK_ROOT` must point to the SDK root (the parent of `cmdline-tools\`). PATH must include three SDK subdirectories.

```cmd
cmd /c "setx JAVA_HOME C:\Java\jdk-17"
cmd /c "setx ANDROID_HOME C:\Android"
cmd /c "setx ANDROID_SDK_ROOT C:\Android"
```

PATH additions (the install pipeline reads the existing user PATH and appends only entries that are not already present, to avoid blowing away existing PATH entries):

```cmd
cmd /c "for /f \"skip=2 tokens=2,*\" %A in ('reg query HKCU\Environment /v Path') do setx PATH \"%B;C:\Java\jdk-17\bin;C:\Android\cmdline-tools\latest\bin;C:\Android\platform-tools;C:\Android\emulator\""
```

Open a **new** `cmd` window (so the PATH refreshes) and verify:

```cmd
cmd /c "echo %JAVA_HOME%"
cmd /c "echo %ANDROID_HOME%"
cmd /c "where sdkmanager"
cmd /c "where adb"
```

Expected:

```
C:\Java\jdk-17
C:\Android
C:\Android\cmdline-tools\latest\bin\sdkmanager.bat
C:\Android\platform-tools\adb.exe
```

(`adb` will not exist until step 2.4; that's expected.)

**If this fails:**
- `setx` truncates PATH to 1024 chars on older Windows. If your existing PATH is long, use the System Properties → Environment Variables UI instead, or move PATH entries to the system PATH.
- `where sdkmanager` returns nothing — you didn't open a new cmd window. `setx` only affects new processes.

### 2.4 Install SDK packages

This is the slowest step (~1.5 GB total download). Run from a fresh `cmd` window so PATH is refreshed:

```cmd
cmd /c "sdkmanager --install \"platform-tools\" \"platforms;android-34\" \"build-tools;34.0.0\" \"emulator\" \"system-images;android-34;google_apis;x86_64\""
```

Expected output (final lines):

```
[=======================================] 100% Computing updates...
done
```

Each package lands in:
- `C:\Android\platform-tools\` — `adb.exe`, `fastboot.exe`
- `C:\Android\platforms\android-34\` — `android.jar`
- `C:\Android\build-tools\34.0.0\` — `aapt2.exe`, `apksigner.bat`
- `C:\Android\emulator\` — `emulator.exe`
- `C:\Android\system-images\android-34\google_apis\x86_64\` — the actual VM disk image

**If this fails:**
- "Unable to access android sdk add-on list" — this is the canonical "JDK is wrong" error. See Section 4.1.
- "Warning: File ... has different content than expected" — partial download. Delete `%LOCALAPPDATA%\Temp\PackageOperation*` and re-run.
- Stalls at 0% for >5 minutes — corporate proxy. Set `JAVA_OPTS=-Dhttp.proxyHost=... -Dhttp.proxyPort=...` or run from a non-corporate network.
- "java.lang.UnsupportedClassVersionError" — JAVA_HOME is JDK 8/11. Re-run step 2.1.

### 2.5 Accept SDK licenses

You **must** accept licenses interactively (or pipe `y` to every prompt) before the emulator and AVD will work:

```cmd
cmd /c "yes | sdkmanager --licenses"
```

On Windows where `yes` doesn't exist:

```cmd
cmd /c "powershell -NoProfile -Command \"for ($i=0; $i -lt 20; $i++) { 'y' } | & sdkmanager --licenses\""
```

Expected output:

```
All SDK package licenses accepted
```

**If this fails:**
- "8 of 8 SDK package license not accepted" — licenses file `C:\Android\licenses\` is read-only. `attrib -r C:\Android\licenses\*` then re-run.

### 2.6 Create the AVD

```cmd
cmd /c "echo no | avdmanager create avd -n RadhaPixel -k \"system-images;android-34;google_apis;x86_64\" -d pixel_5"
```

The `echo no` answers the "Do you wish to create a custom hardware profile?" prompt with the device defaults. Use `pixel_5` (a sensible 6-inch portrait phone profile that matches what RADHA was designed against).

Expected output:

```
Auto-creating user on first run.
Loading local repository...
[========================================] 100% Fetch remote repository...
Created AVD 'RadhaPixel' based on Google APIs system image, ...
```

The AVD lands at `%USERPROFILE%\.android\avd\RadhaPixel.avd\`. Verify:

```cmd
cmd /c "avdmanager list avd"
```

Expected: a single entry named `RadhaPixel`, target `Google APIs (Google Inc.)`, ABI `google_apis/x86_64`.

**If this fails:**
- "Package path is not valid" — system image not installed. Re-run step 2.4 with the exact `system-images;android-34;google_apis;x86_64` string.
- "PANIC: Cannot find AVD system path" — see Section 4.2.

### 2.7 Boot the emulator

This is the one step that **must** run in a long-lived terminal — the emulator process stays attached to the launching console. Open a new `cmd` window dedicated to the emulator:

```cmd
cmd /c "emulator -avd RadhaPixel -no-snapshot-save -no-boot-anim"
```

Flags worth knowing:
- `-no-snapshot-save` — don't save state on shutdown. Cleaner for repeated test runs.
- `-no-boot-anim` — skip the boot animation. Saves ~10 seconds.
- `-no-window` — headless mode. Useful for CI but you cannot visually verify the boot.
- `-verbose` — print every Qt/Vulkan/HAXM message. Use this when boot fails silently.
- `-gpu swiftshader_indirect` — force software rendering when GPU passthrough is broken (slow but works on hosts without proper graphics drivers).

Expected console output (~30s on warm disk, up to 3 min on a slow HDD):

```
INFO         | Storing crashdata in: ...
INFO         | Android emulator version 34.x.x.x
INFO         | Found systemPath C:\Android\system-images\android-34\google_apis\x86_64\
HAX is working and emulator runs in fast virt mode
INFO         | boot completed
```

**If this fails:**
- "PANIC: HAX is not installed on this machine" / "x86 emulation currently requires hardware acceleration" — see Section 3.
- "Emulator process finished with exit code 1" — see Section 4.4.
- Window appears but stays black for >5 minutes — see Section 4.5.

### 2.8 Verify with adb

In a **separate** `cmd` window (do not close the emulator window):

```cmd
cmd /c "adb devices"
```

Expected output:

```
List of devices attached
emulator-5554   device
```

If `device` shows `offline` instead, wait 30–60 seconds — Android is still finishing first boot. If after 5 minutes it's still `offline`, see Section 4.5.

Confirm the device is actually responsive:

```cmd
cmd /c "adb -s emulator-5554 shell getprop sys.boot_completed"
```

Expected: `1`. If empty or `0`, boot is still in progress.

---

## 3. Hardware virtualization (the most common failure)

The x86_64 system image runs as a real virtual machine. Without virtualization extensions, the emulator either refuses to launch or crawls along at unusable speed. On Windows, the emulator uses one of three accelerators:

1. **Hyper-V / WHPX** (Windows Hypervisor Platform) — preferred on Windows 10/11
2. **HAXM** (Intel HAXM) — deprecated and unsigned on modern Windows; avoid
3. **AEHD** (Android Emulator Hypervisor Driver) — Google's HAXM replacement

### 3.1 Check current status

```cmd
cmd /c "systeminfo | findstr /C:\"Hyper-V\""
cmd /c "bcdedit | findstr hypervisorlaunchtype"
```

Expected output (a healthy Win 11 host with Hyper-V on):

```
Hyper-V Requirements:      VM Monitor Mode Extensions: Yes
                           Virtualization Enabled In Firmware: Yes
                           Second Level Address Translation: Yes
                           Data Execution Prevention Available: Yes
hypervisorlaunchtype    Auto
```

Or open Task Manager → **Performance** tab → **CPU** — the **Virtualization** field at the bottom right should read **Enabled**.

### 3.2 Enable virtualization (three layers, all required)

**Layer 1 — BIOS/UEFI:**
1. Reboot the laptop.
2. Tap `F2` / `F10` / `Del` (depends on vendor) at boot to enter UEFI.
3. Find a setting called **Intel Virtualization Technology** (Intel) or **SVM Mode** / **AMD-V** (AMD) — usually under "Advanced", "CPU Configuration", or "Security".
4. Set to **Enabled**.
5. Save and exit (`F10` on most boards).

**Layer 2 — Windows Features:**

Open `optionalfeatures` from `Win+R` and tick:
- ☑ Hyper-V Platform → **Hyper-V Hypervisor**
- ☑ Windows Hypervisor Platform
- ☑ Virtual Machine Platform

Or via PowerShell as Administrator:

```cmd
cmd /c "powershell -NoProfile -Command \"Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform,VirtualMachinePlatform -All -NoRestart\""
```

**Layer 3 — Reboot.** Hyper-V loads at boot; without a reboot, the emulator still cannot accelerate.

After reboot, re-run step 2.7. The boot output should now include `HAX is working` (or on Hyper-V hosts: `WHPX (10.0.x) is installed and usable`).

### 3.3 Hyper-V is incompatible (older CPUs / nested virtualization off)

Some scenarios where Hyper-V genuinely cannot be used:
- CPU lacks SLAT (any pre-2010 CPU)
- Running inside another VM (VirtualBox, VMware) without nested virtualization
- Enterprise device with virtualization-based security locked by IT policy

Fallback: use the **arm64-v8a** system image with software rendering. It does not need Hyper-V because it runs in pure software emulation. It is much slower (10–20× boot time, sluggish UI) but functional for smoke tests.

```cmd
cmd /c "sdkmanager --install \"system-images;android-34;google_apis;arm64-v8a\""
cmd /c "avdmanager create avd -n RadhaPixelArm -k \"system-images;android-34;google_apis;arm64-v8a\" -d pixel_5"
cmd /c "emulator -avd RadhaPixelArm -gpu swiftshader_indirect"
```

Expect 5–10 minute boot times. Plan accordingly.

---

## 4. Common failure patterns + fixes

### 4.1 "Unable to access android sdk add-on list"

What it really means: `sdkmanager` could not start its JVM, or started a JVM that's the wrong version.

Diagnose:

```cmd
cmd /c "echo %JAVA_HOME%"
cmd /c "%JAVA_HOME%\bin\java.exe -version"
```

Fixes:
- `JAVA_HOME` empty → re-run step 2.3.
- `java -version` reports `1.8.x` or `11.x` → installed JDK is wrong. Set `JAVA_HOME=C:\Java\jdk-17` and re-run.
- `java -version` works at the path but `sdkmanager` still fails → `sdkmanager.bat` only looks at `JAVA_HOME`, not `PATH`. Make sure `JAVA_HOME` is set, not just PATH.

### 4.2 "PANIC: Cannot find AVD system path"

What it really means: `emulator.exe` resolved an `ANDROID_AVD_HOME` (or `%USERPROFILE%\.android`) that doesn't actually contain `RadhaPixel.avd\config.ini`.

Diagnose:

```cmd
cmd /c "dir %USERPROFILE%\.android\avd"
```

Should list `RadhaPixel.ini` (a one-liner pointer file) **and** a `RadhaPixel.avd\` directory containing `config.ini`. If only the `.ini` exists, the AVD was half-created.

Fixes:
- Delete and recreate: `cmd /c "avdmanager delete avd -n RadhaPixel"` then re-run step 2.6.
- If `ANDROID_AVD_HOME` is set to a custom path, either unset it (`setx ANDROID_AVD_HOME ""`) or move the `.avd` folder there.

### 4.3 "INSTALL_FAILED_NO_MATCHING_ABIS"

What it really means: the APK was compiled for a CPU architecture that doesn't match the AVD.

Diagnose: check the AVD's ABI:

```cmd
cmd /c "avdmanager list avd"
```

Look for the `Tag/ABI` line. RADHA's Flutter build defaults to `x86_64` and `arm64-v8a`. If your AVD is `armeabi-v7a` (32-bit ARM, very old), it won't accept the modern build.

Fix: recreate the AVD with `google_apis;x86_64` (preferred) or `google_apis;arm64-v8a` (fallback). The system image string in step 2.4 must match the AVD's ABI.

### 4.4 "Emulator process finished with exit code 1" (no further details)

What it really means: the emulator crashed during early init and didn't get to print a useful error.

Diagnose by re-running with verbose flags:

```cmd
cmd /c "emulator -avd RadhaPixel -verbose -show-kernel"
```

Look for the **last** non-info line before exit. Common patterns:
- `Vulkan emulation: failed to initialize` → add `-gpu swiftshader_indirect`
- `cannot add library ... vulkan-1.dll` → outdated GPU driver. Update graphics drivers.
- `Hax is disabled. Reason: hyper-v` → see Section 3.
- `AVD already running` → another instance is alive. Kill it (`taskkill /im qemu-system-x86_64.exe /f`) and retry.

### 4.5 "adb: device offline" (or stays offline forever)

What it really means: the emulator's `adbd` daemon is up but hasn't completed boot, or `adb` on the host is talking to a stale daemon.

Fixes (try in order):

```cmd
cmd /c "adb kill-server"
cmd /c "adb start-server"
cmd /c "adb devices"
```

Then wait. Cold boot on a slow HDD or a low-spec laptop can take 3–5 minutes for the device to flip from `offline` to `device`. Confirm progress:

```cmd
cmd /c "adb -s emulator-5554 shell getprop sys.boot_completed"
```

`1` means done. Empty output means still booting.

If it's still offline after 5 minutes:
- The AVD's user-data partition may be corrupt — `cmd /c "emulator -avd RadhaPixel -wipe-data"`
- Antivirus is intercepting `adb.exe` (Defender flags it as a debugging tool) — add `C:\Android\platform-tools\` to exclusions

### 4.6 mobile-mcp returns an empty devices list

What it really means: the `mobile-mcp` Node process inherits an old PATH that doesn't include `C:\Android\platform-tools\`, so it cannot find `adb`.

Diagnose:

```cmd
cmd /c "where adb"
```

If this returns the path, your `cmd` shell can find `adb` but `mobile-mcp` cannot — because it was started with the PATH from before you ran `setx`.

Fix: **restart `mobile-mcp` from the Kiro UI.** Open the MCP server panel, find `mobile-mcp`, and use the "Restart server" action. The new process will inherit the updated user PATH that includes `platform-tools`.

After restart, re-call:

```text
mcp_mobile_mcp_mobile_list_available_devices
```

Expected: at least one entry of the form `{ id: 'emulator-5554', name: 'RadhaPixel', platform: 'android' }`.

### 4.7 Emulator boots but Flutter app crashes on launch

Not strictly an Android setup issue, but covers the layer above. If `mobile-mcp` lists the device and you launch `com.radha.mobile` but it crashes:

```cmd
cmd /c "adb -s emulator-5554 logcat *:E | findstr /I radha"
```

The first `FATAL EXCEPTION` line tells you the actual error. Common ones:
- `Connection refused (10.0.2.2:3000)` — backend not running on host. Start `pnpm server:dev` and wait for it to bind port 3000.
- `MissingPluginException(No implementation found for method ...)` — Flutter plugin missing native binary; rerun `flutter clean && flutter pub get`.

---

## 5. mobile-mcp + emulator workflow

Once `adb devices` shows `emulator-5554 device` and `mobile-mcp` has been restarted, Kiro can drive the app entirely through MCP tool calls. No mouse, no keyboard.

### 5.1 First, install the APK

`mobile-mcp` does not build the Flutter app — that's the Flutter toolchain's job. From a `cmd` window:

```cmd
cd apps\mobile
cmd /c "C:\src\flutter\bin\flutter.bat install -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1"
```

(`10.0.2.2` is the Android emulator's loopback alias for the host's `localhost`. Do **not** use `127.0.0.1` from inside the emulator — that points to the emulator itself.)

### 5.2 Verify mobile-mcp can see the device

```text
mcp_mobile_mcp_mobile_list_available_devices
```

Expected response shape:

```json
[
  { "deviceId": "emulator-5554", "platform": "android", "name": "RadhaPixel" }
]
```

If empty, see Section 4.6.

### 5.3 The 10-step smoke flow (mirrors `MOBILE_SMOKE_TEST_RUNBOOK.md` Option A)

This is the same checklist as the Chrome path, adapted for `mobile-mcp`'s tool surface. Each step is a tool call; each "Expected" is what `mcp_mobile_mcp_mobile_list_elements_on_screen` should report after that step.

| # | Goal | Tool call(s) | Expected after |
|---|---|---|---|
| 1 | Launch app | `mcp_mobile_mcp_mobile_launch_app({device:'emulator-5554', packageName:'com.radha.mobile'})` | Splash screen — emerald RADHA wordmark |
| 2 | Wait for splash → onboarding | `mcp_mobile_mcp_mobile_take_screenshot` (after ~2s) | Onboarding page 1 with "Continue" button visible |
| 3 | Advance onboarding | `mcp_mobile_mcp_mobile_list_elements_on_screen` → find "Continue" → `mcp_mobile_mcp_mobile_click_on_screen_at_coordinates` × 2 | Onboarding page 3 with 6 segment cards |
| 4 | Pick segment + continue | Click a segment card, then "Get started" | Sign in screen with phone input |
| 5 | OTP request | Type `9999912345` via `mcp_mobile_mcp_mobile_type_keys`, click "Send OTP" | Either OTP entry screen or 500 error toast (MSG91 may not be configured) |
| 6 | Skip auth (if backend OTP unavailable) | Inject session via `adb shell` deep link, or use a test build with auth bypass | Home dashboard with bento grid |
| 7 | Bottom nav sweep | Click each of the 5 tabs (Home, Scan, Expiry, Tasks, Profile) | Each tab renders without crashing |
| 8 | Quick action | From Home, click "Add Expiry" tile | Expiry create form with date picker |
| 9 | Scan path | Switch to Scan tab — camera should open (the emulator simulates a fake camera feed) | Scanner overlay or manual EAN entry fallback |
| 10 | Subscription page | Navigate to `/subscription` via deep link or profile menu | Plan compare table with 4 columns |

Capture a screenshot at each step:

```text
mcp_mobile_mcp_mobile_take_screenshot({device:'emulator-5554', filename:'smoke-step-NN.png'})
```

Save them under `.mobile-mcp/` (create the folder if needed) so the test artefacts are alongside the `.playwright-mcp/` web artefacts.

### 5.4 Driving without seeing the screen

`mcp_mobile_mcp_mobile_list_elements_on_screen` is the equivalent of Playwright's accessibility tree. It returns coordinates and labels for every tappable element. Always use it before clicking — coordinates from a stale screenshot will miss the target after even a small layout shift (e.g. an animated banner pushing content down).

---

## 6. Cleanup and restart

### 6.1 Stop the emulator cleanly

Do **not** click the X on the emulator window — that leaves a stale `qemu-system-x86_64.exe` process and a locked AVD. Instead:

```cmd
cmd /c "adb -s emulator-5554 emu kill"
```

Within 2 seconds the emulator window closes, the QEMU process exits, and the AVD lock is released.

If you forgot and the window is already gone but a stale process remains:

```cmd
cmd /c "tasklist | findstr qemu-system"
cmd /c "taskkill /im qemu-system-x86_64.exe /f"
```

### 6.2 Wipe AVD state (when user data corrupts)

Symptoms: app stuck on splash, settings frozen, `pm install` returns `INSTALL_FAILED_INSUFFICIENT_STORAGE` despite disk space.

```cmd
cmd /c "emulator -avd RadhaPixel -wipe-data"
```

This boots the emulator **once** with a factory-reset user partition. After that boot, shut down (`adb -s emulator-5554 emu kill`) and continue normally.

### 6.3 Delete and recreate the AVD

When `-wipe-data` doesn't help (the config itself is corrupt):

```cmd
cmd /c "avdmanager delete avd -n RadhaPixel"
cmd /c "avdmanager create avd -n RadhaPixel -k \"system-images;android-34;google_apis;x86_64\" -d pixel_5"
```

The system image (~1.5 GB) is preserved — you only re-create the lightweight AVD wrapper.

### 6.4 Full reinstall (nuclear option)

When the SDK itself is broken (mismatched packages, half-applied updates):

```cmd
cmd /c "rmdir /s /q C:\Android"
cmd /c "rmdir /s /q %USERPROFILE%\.android"
```

Then start over from Section 2.2. JDK 17 (`C:\Java\jdk-17`) does not need to be reinstalled.

---

## 7. Alternative paths (if the Android emulator just won't work)

### 7.1 Real Android device over USB

Identical `adb` and `mobile-mcp` flow, no emulator needed:

1. On the phone, **Settings → About phone → tap Build number 7 times** to enable Developer Options.
2. **Developer Options → USB debugging: ON**.
3. Connect via USB. The phone will prompt "Allow USB debugging from this computer?" — accept and check "Always".
4. Verify:

   ```cmd
   cmd /c "adb devices"
   ```

   Expected: a line like `R58M12345AB    device`.
5. Install RADHA pointing at your laptop's LAN IP:

   ```cmd
   cmd /c "C:\src\flutter\bin\flutter.bat install -d <device-id> --dart-define=API_BASE_URL=http://<your-laptop-lan-ip>:3000/api/v1"
   ```

   The phone needs network reach to your laptop. If your network blocks LAN traffic, expose the backend via `ngrok http 3000` and use the public URL.

`mobile-mcp` will see the physical device the same way it sees an emulator — list, launch, screenshot, click all work identically.

### 7.2 Chrome web smoke test (recommended for most cases)

If you don't specifically need camera or notification testing, the Chrome path is faster, lighter, and already proven on this host. See `MOBILE_SMOKE_TEST_RUNBOOK.md` Option A. Playwright MCP drives it through the browser.

### 7.3 Third-party emulators (last resort, unofficial)

**BlueStacks** and **NoxPlayer** are consumer Android emulators that bypass Hyper-V by using their own hypervisor stack. They expose `adb` over `localhost:5555` (BlueStacks) or `localhost:62001` (Nox).

```cmd
cmd /c "adb connect localhost:5555"
cmd /c "adb devices"
```

Caveats — these are **unofficial** for development:
- They run forks of Android with custom skins and pre-installed bloatware. Behaviour will not match a stock AOSP device.
- They sometimes block `pm install -r` for security reasons; you may need to install via their UI.
- Performance characteristics are wildly different — what's fast on BlueStacks may be slow on a real Pixel.

Use only when both Section 2's official emulator and Section 7.1's USB path are unavailable.

---

## Quick reference card

```cmd
:: Boot the emulator (in a dedicated cmd window)
cmd /c "emulator -avd RadhaPixel -no-snapshot-save -no-boot-anim"

:: Verify
cmd /c "adb devices"
cmd /c "adb -s emulator-5554 shell getprop sys.boot_completed"

:: Install RADHA against the host backend
cd apps\mobile
cmd /c "C:\src\flutter\bin\flutter.bat install -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1"

:: Stop cleanly
cmd /c "adb -s emulator-5554 emu kill"

:: Wipe and re-boot (when user data corrupts)
cmd /c "emulator -avd RadhaPixel -wipe-data"

:: Delete and recreate AVD (when config corrupts)
cmd /c "avdmanager delete avd -n RadhaPixel"
cmd /c "avdmanager create avd -n RadhaPixel -k \"system-images;android-34;google_apis;x86_64\" -d pixel_5"
```

When in doubt, work top-down through the layers:

```
JDK 17 → cmdline-tools → SDK packages → AVD → emulator boot → adb → mobile-mcp
```

Each is a hard dependency on the next. If `mobile-mcp` doesn't see the device, the failure is somewhere in that chain — not in `mobile-mcp` itself.
