# 🚇 Cairo Metro Route Finder

A Flutter mobile application for planning routes across Cairo's metro network. Select your origin and destination stations, and the app calculates the optimal route with fare, travel time, directions, and transfer information across all three metro lines.

---

## Screenshots

| Home Screen | Route Result | Transfer Route |
|:-----------:|:------------:|:--------------:|
| ![Home](screenshots/home.png) | ![Route](screenshots/route.png) | ![Transfer](screenshots/transfer.png) |


---

## Features

- **Route Planning** — Find the optimal route between any two stations across Lines 1, 2, and 3
- **Fare Calculation** — Automatic ticket price based on the number of stations
- **Transfer Detection** — Identifies transfer stations when crossing between lines with direction guidance before and after the exchange
- **Visual Route Timeline** — Color-coded route display matching actual Cairo Metro line colors (Red, Yellow, Green)
- **Nearest Station (GPS)** — Uses device location to find the closest metro station and opens it on the map
- **Address Lookup** — Enter any address to find the nearest metro station using geocoding
- **Open in Maps** — Tap the map button to open any selected station's location in your default map app
- **Station Search** — Filter and search through 80+ stations with an inline searchable dropdown

---

## Metro Lines Covered

| Line | Route | Stations | Color |
|------|-------|----------|-------|
| Line 1 | Helwan ↔ New El-Marg | 35 | 🔴 Red |
| Line 2 | El Mounib ↔ Shubra El-Kheima | 20 | 🟡 Yellow |
| Line 3 | Adly Mansour ↔ Rod El-Farag Corridor | 34 | 🟢 Green |

**Transfer Stations:** Sadat, Al-Shohadaa, Attaba, Gamal Abdel Nasser

---

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── homePage.dart             # Main UI screen
├── metroStation.dart         # MetroStation model class
├── metro_data.dart           # Station data with coordinates for all 3 lines
├── metro_service.dart        # Route-finding logic and fare calculation
└── route_result.dart         # RouteResult model class
```

---

## Tech Stack

- **Flutter** — Cross-platform mobile framework
- **Dart** — Programming language
- **GetX** — Reactive state management and snackbar notifications
- **Geolocator** — GPS location services
- **Geocoding** — Address to coordinates conversion
- **URL Launcher** — Open station locations in external map apps

---

## Getting Started

### Prerequisites

- Flutter SDK (3.x or later)
- Android Studio / VS Code with Flutter extensions
- Android or iOS device/emulator

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/cairo-metro-app.git
cd cairo-metro-app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.6
  geolocator: ^10.1.0
  geocoding: ^2.1.0
  url_launcher: ^6.2.0
  collection: ^1.18.0
```

### Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

## How It Works

1. **Same-line routes** — Calculates the direct path between two stations on the same line
2. **Cross-line routes** — Finds the nearest intersection/transfer station, splits the journey into two segments, and combines them
3. **Fare logic** — Based on total stations traveled:

   | Stations | Fare |
   |----------|------|
   | 1–9 | 8 EGP |
   | 10–16 | 10 EGP |
   | 17–23 | 15 EGP |
   | 24+ | 20 EGP |

4. **Nearest station** — Uses `Geolocator.distanceBetween()` to compare the user's GPS coordinates against all station coordinates

---

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -m 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Open a Pull Request

---

## License

This project is open source and available under the [MIT License](LICENSE).

---

## Acknowledgments

- Station coordinates and metro network data based on Cairo Metro's official line maps
- Built as a learning project to practice Flutter development and mobile app architecture
