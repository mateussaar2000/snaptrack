# SnapTrack iOS

A polished, native iOS calorie and macro tracker built on top of the beautiful Dime UI. Snap a meal, get AI-analyzed nutrition, and track your daily goals with cards, charts, and a custom number pad.

> **Note:** This is a derivative work of [Dime](https://github.com/rarfell/dimeApp) by Rafael Soh and Jeffrey Chia, licensed under GPL v3.0. See [`NOTICE.md`](NOTICE.md) for attribution and license details.

## What makes it different from Dime

- **Calorie & macro tracking** instead of expenses and budgets.
- **Supabase backend** for auth, meal storage, and AI analysis, shared with the existing SnapTrack web app.
- **AI food logging** powered by the SnapTrack `analyze` Edge Function and patterns from Fud AI.
- **Daily calorie goals + macro subgoals** with Dime’s gorgeous gauges and summary tiles.

## Project layout

```
snaptrack-dime/
├── app/
│   ├── dime.xcodeproj          # Main Xcode project (being migrated to SnapTrack)
│   ├── dime/                   # SwiftUI app sources
│   ├── ExpenditureWidget/      # Widget extensions
│   ├── BudgetIntent/           # Siri/App Intents extensions
│   └── Localizations/          # String catalogs
├── LICENSE                     # GPL v3.0 (from Dime)
├── NOTICE.md                   # Attribution and derivative-work notice
└── README.md                   # This file
```

## Build & run

### Requirements
- macOS with **Xcode 15+**
- **iOS 16+** target device or simulator
- An Apple Developer account for physical-device builds

### Steps

1. Open the project:
   ```bash
   open snaptrack-dime/app/dime.xcodeproj
   ```

2. Resolve Swift Package Manager dependencies:
   ```bash
   # In Xcode: File > Packages > Resolve Package Versions
   ```

3. Select the **SnapTrack** target and an iPhone simulator.

4. Build and run with signing disabled for the simulator:
   ```bash
   xcodebuild -project snaptrack-dime/app/dime.xcodeproj \
              -scheme SnapTrack \
              -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
              CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
   ```

## Secrets

Do not commit API keys or provider secrets. Place them in a local `Secrets.xcconfig` or Xcode environment variables. The Supabase project URL and anon key are the same as the existing SnapTrack web app and can live in `Config.swift` because they are already public in the client.

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for the full text.
