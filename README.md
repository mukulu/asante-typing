# Asante Typing Tutor

Asante Typing Tutor is a clean, data‑driven typing practice application built with **Flutter**.  The app teaches proper touch‑typing technique through a series of units and sub‑units and provides real‑time feedback on speed and accuracy.

All lesson content – titles, guides, images and exercises – is defined in a single JSON file (`assets/units.json`), making it easy to author new lessons without changing any Dart code.  The UI is composed of small, reusable widgets to aid maintainability and readability.

---

## Features

* **Ready‑to‑type on launch** – When the app starts it automatically selects the first unit and its first sub‑unit and focuses the typing box.
* **Smart navigation** – Selected units and sub‑units are highlighted.  Each unit remembers the last sub‑unit you practised and restores it when you return.
* **Data‑driven UI** – Lessons are rendered from `assets/units.json`.  There is no hard‑coded limit on the number of sub‑units; the app iterates over whatever keys appear in the JSON.
* **Guide and image support** – Each lesson can display one or more images along with introductory guide text.  The guide text is HTML but rendered as plain text in the app.
* **Real‑time metrics** – A progress bar shows how much of the text has been typed, while gauges display words per minute (WPM) and characters per minute (CPM).  Errors and elapsed time are updated every second.
* **Inline session summary** – When you finish typing a sub‑unit, a summary panel appears below the metrics showing length, typed characters, errors, WPM, CPM, accuracy and total time.
* **Modular architecture** – The UI is broken into smaller widgets such as `LeftNav`, `SubunitChips`, `MetricsPanel`, `SessionSummary`, and `Footer`.  Each widget lives in its own file under `lib/widgets` and is documented with Dart doc comments.
* **Consistent theming** – A three‑colour palette (yellow `#f4b233`, green `#1f5f45`, red `#7a1717`) is applied throughout the app.  The header and footer are green, the navigation panel is yellow and accent text is red.
* **GPL‑3.0 licensing** – The project is licensed under the GNU General Public License v3.0 or later.  See the `LICENSE` file for details.

---

## Tech Stack

* [Flutter](https://flutter.dev/) / [Dart](https://dart.dev/)
* Pure Flutter widgets (no platform channels)
* JSON for lesson data

---

## Getting Started

### Prerequisites

* Flutter **3.x** (or newer).  Use `flutter --version` to check your installation.
* A device or emulator/simulator to run the app.

### Installation

```bash
git clone https://github.com/mukulu/asante-typing.git
cd asante-typing
git checkout feat/unified-layout # or the branch you wish to run
flutter pub get
```

### Running

```bash
# Run on a connected device or emulator
flutter run

# Run in the Chrome browser
flutter run -d chrome
```

### Building Release Binaries

```bash
flutter build apk    # Android release
flutter build ios    # iOS release (requires macOS and Xcode)
flutter build web    # Web release
```

---

## Project Structure

```
asante-typing/
├─ assets/
│  ├─ img/                # JPG images used by lessons
│  └─ units.json          # All lesson data (titles, guides, images, sub‑units)
├─ lib/
│  ├─ models/
│  │  └─ units.dart       # Data models for lessons and units
│  ├─ utils/
│  │  └─ typing_utils.dart# Helper functions (formatting, image fallback)
│  ├─ widgets/
│  │  ├─ footer.dart      # Footer bar widget
│  │  ├─ gauge.dart       # Reusable circular gauge widget for metrics
│  │  ├─ left_nav.dart    # Left navigation panel showing units
│  │  ├─ metrics_panel.dart# Real‑time metrics and visualisations
│  │  └─ subunit_chips.dart# Chips for sub‑unit selection
│  ├─ screens/
│  │  └─ tutor_page.dart  # Main page that composes widgets into layout
│  └─ main.dart           # Entry point of the Flutter application
├─ test/
│  └─ typing_utils_test.dart # Unit tests for utilities
├─ pubspec.yaml           # Flutter package configuration and asset list
├─ LICENSE                # GPL‑3.0 or later license text
└─ README.md              # This file
```

### Note on `units.json`

The `assets/units.json` file is the single source of truth for all lessons.  Each entry in the `main` array defines a lesson with the following structure:

```json
{
  "title": "asdf jkl;",
  "guide": "<p>Place fingers on the home row…</p>",
  "images": ["img/home-keys-position.jpg"],
  "subunits": {
    "Grip": "asdf ;lkj asdf ;lkj …",
    "Words": "a a a; as as as; …",
    "Control": "d da dad; a al…",
    "Sentences": "ask sall; ask sall; …",
    "Test": "as all alfalfa; …"
  }
}
```

* The **title** appears in the navigation list and as part of the dynamic page title.
* The **guide** is HTML but rendered as plain text by the app.
* The **images** array lists diagrams associated with the lesson.  Only the first image is shown by default.
* The **subunits** object contains any number of practice sections; keys become tab labels in the UI.

Feel free to add new lessons by editing this file and adding corresponding JPG images under `assets/img/`.

---

## Development Standards

The codebase follows several conventions to improve readability and maintainability:

* Files and classes are organised by concern: models (`lib/models`), utility functions (`lib/utils`), widgets (`lib/widgets`), and screens (`lib/screens`).
* Each public class, function and method is documented with Dart doc comments (`///`) to enable API documentation generation.
* Constructors are declared before other instance members.
* The Dart formatter is applied (`dart format .`) to ensure consistent style.
* Imports are sorted: `package:` imports before relative `../` imports.
* No deprecated APIs are used – colour transparencies are set via `withValues(alpha: …)` rather than the deprecated `withOpacity()`.
* Each Dart file ends with a newline character.

To verify code quality, run:

```bash
flutter analyze
dart format --set-exit-if-changed .
```

---

## Generating Documentation

You can generate API documentation using Dart doc tools.  For example:

```bash
dart doc --output docs/html
```

This command produces HTML documentation in the `docs/html` directory.  The doc comments in each file provide descriptions of classes, methods and parameters.

---

## Contributing

We welcome contributions!  To submit a change:

1. Fork and clone the repository.
2. Create a feature branch based off `feat/unified-layout`:

   ```bash
   git checkout feat/unified-layout
   git checkout -b your-feature-branch
   ```

3. Make your changes.  Please keep code modular and documented.
4. Run formatting and analysis:

   ```bash
   dart format .
   flutter analyze
   ```

5. Commit with a clear message and open a Pull Request targeting `feat/unified-layout`.

When adding features, avoid hard‑coding lesson data or number of subunits.  Always refer to `units.json`.  Maintain the colour palette and ensure no deprecated APIs are introduced.

---

## License

This project is licensed under the **GNU General Public License v3.0 or later (GPL‑3.0‑or‑later)**.

You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

Copyright © **John Francis Mukulu SJ**, 2025
