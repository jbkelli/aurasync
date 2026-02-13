# AuraSync 🌟

**A proximity-based device discovery app using BLE + Ultrasonic Audio Verification**

---

## 🎯 What is AuraSync?

AuraSync is a **zero-configuration local networking app** that uses **"Dual-Verify" technology** to securely connect nearby devices:

1. **BLE Scanning** - Discovers devices via Bluetooth Low Energy
2. **Audio Verification** - Confirms physical proximity using 18kHz ultrasonic chirps
3. **Auto-Connect** - Only connects when BOTH signals are detected

> Think of it as "bump to connect" but without the bump! 🤝

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Latest Stable) |
| State Management | `flutter_riverpod` (Notifier providers) |
| BLE | `flutter_blue_plus` |
| Audio Input | `mic_stream` |
| Audio Analysis | `fftea` (FFT for frequency detection) |
| Permissions | `permission_handler` |
| Architecture | Feature-first folder structure |

---

## 📂 Project Structure

```
lib/
├── main.dart                        # App entry + Riverpod setup
├── core/
│   ├── models/
│   │   └── device_model.dart       # DiscoveredDevice entity
│   ├── constants/
│   │   └── ble_constants.dart      # BLE UUID constants
│   └── services/
│       ├── permission_service.dart # Cross-platform permissions
│       ├── dual_verify_service.dart# Dual-verify logic ✨
│       └── connection_manager.dart # Connection lifecycle ✨
└── features/
    ├── radar/                       # Phase 1 ✅
    │   ├── providers/
    │   ├── screens/
    │   └── widgets/
    ├── permissions/                 # Phase 2 ✅
    │   ├── providers/
    │   ├── screens/
    │   └── widgets/
    ├── audio/                       # Phase 3 ✅
    │   ├── providers/
    │   ├── services/
    │   └── widgets/
    └── ble/                         # Phase 4 ✅
        ├── providers/
        ├── services/
        └── widgets/
```

---

## 🚀 Development Phases

### ✅ Phase 1: Foundation & UI Shell - **COMPLETE**
- [x] Feature-first architecture
- [x] Beautiful dark-mode radar UI
- [x] Mock device data with animations
- [x] State management with Riverpod
- [x] Color-coded device states

**Demo:** Run `flutter run` to see the spinning radar!

---

### ✅ Phase 2: Permissions & Hardware Setup - **COMPLETE**
- [x] PermissionService implementation
- [x] AndroidManifest.xml configuration
- [x] Info.plist configuration
- [x] Permission request UI
- [x] Cross-platform support (Android + iOS)
- [x] Beautiful permission flow

**Demo:** First launch shows permission request screen!

---

### ✅ Phase 3: Audio Layer - **COMPLETE**
- [x] AudioTransmitter (18kHz sine wave generator)
- [x] AudioReceiver (FFT analysis in Isolate)
- [x] AudioDetectionProvider (global audio state)
- [x] Audio Control Panel UI
- [x] Integration with radar screen
- [x] Real-time detection indicator

**Demo:** Tap the control button to start audio system!

---

### ✅ Phase 4: BLE Layer - **COMPLETE**
- [x] BLE Service (scanning & advertising)
- [x] BleStateProvider (global BLE state)
- [x] BLE UUID constants
- [x] Integration with device discovery
- [x] BLE Control Panel UI
- [x] Real-time device list with RSSI
- [x] Distance estimation from RSSI

**Demo:** Tap the Bluetooth button to control BLE operations!

---

### ✅ Phase 5: Integration & Dual-Verify Logic - **COMPLETE** 🎉
- [x] DualVerifyService coordinator
- [x] ConnectionManager service
- [x] Confidence score calculation
- [x] Auto-connect logic (triggers at 70% confidence)
- [x] Enhanced DeviceCard widget with rich UI
- [x] Vertical scrolling device list
- [x] Connection state management
- [x] Real-time dual-verify status updates

**Demo:** Watch devices auto-connect when both BLE and audio are detected!

**What is Dual-Verify?**
- **BLE Signal** confirms device identity
- **18kHz Audio** confirms physical proximity (~3m range)
- **Both Required** = High confidence connection ✓
- **Auto-Connect** when confidence ≥ 70%

See [PHASE5_SUMMARY.md](PHASE5_SUMMARY.md) for detailed technical documentation!

---

### 🔮 Future Enhancements (Phase 6+)
- [ ] Native BLE advertising (platform channels)
- [ ] Real-time messaging over connections
- [ ] File sharing between devices
- [ ] End-to-end encryption
- [ ] Group proximity sessions
- [ ] Audio beamforming for directional detection

---

## 🎨 UI Preview

**Current Radar Screen:**

```
┌─────────────────────────────────┐
│       ✧ AuraSync ✧            │
│   Scanning for nearby...       │
│  [Dual:1] [BLE:1] [Audio:1]   │
├─────────────────────────────────┤
│            🎯                   │
│         Spinning Radar          │
│     with animated dots          │
│                                 │
├─────────────────────────────────┤
│  [Device Cards Scrolling]       │
└─────────────────────────────────┘
```

**Color Coding:**
- 🟢 **Green**: Dual-Verified (BLE + Audio) ✓
- 🔵 **Blue**: BLE Only
- 🟣 **Magenta**: Audio Only

---

## 🏃 Quick Start

### Prerequisites
- Flutter SDK (3.11.0+)
- Android Studio / Xcode
- Physical device (BLE + Microphone required)

### Install & Run
```bash
# Clone the repo
git clone <your-repo-url>
cd aurasync

# Get dependencies
flutter pub get

# Run on device
flutter run
```

---

## 🧠 Core Logic (The "Brain")

### The Dual-Verify Algorithm

```dart
// Pseudo-code for Phase 5
if (device.isBleVisible && audioDetectionProvider.isDetected) {
  deviceManager.autoConnect(device);
}
```

**Why this matters:**
- BLE alone can be spoofed
- Audio verification proves physical proximity
- Dual verification = secure local connection

---

## 📖 Documentation

- **[PHASE_1_COMPLETE.md](PHASE_1_COMPLETE.md)** - Detailed Phase 1 breakdown
- **[Architecture Guide](docs/ARCHITECTURE.md)** - Coming soon
- **[API Reference](docs/API.md)** - Coming soon

---

## 🤝 Contributing

This is an MVP project following a strict phased approach. **Please wait for Phase 5 completion before contributing.**

---

## 📜 License

MIT License - See [LICENSE](LICENSE) file

---

## 🙏 Acknowledgments

Built with ❤️ using:
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
- [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus)
- [fftea](https://pub.dev/packages/fftea)
- [mic_stream](https://pub.dev/packages/mic_stream)

---

**Status:** 🟢 Phase 1, 2 & 3 Complete | 🔄 Phase 4 Starting  
**Last Updated:** February 2026

