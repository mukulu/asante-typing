# Asante Typing Tutor

Asante Typing Tutor is a clean, data-driven typing practice app built with **Flutter**.  
Lessons (titles, guides, images, and sub-units) are defined in a single JSON file, so content can be edited without touching code.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Download](#download)
  - [Run (Debug)](#run-debug)
  - [Build (Release)](#build-release)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
  - [Assets](#assets)
  - [Lesson Data (`units.json`)](#lesson-data-unitsjson)
- [How It Works](#how-it-works)
- [Development Standards](#development-standards)
- [Quality & Linting](#quality--linting)
- [Documentation](#documentation)
- [Repository](#repository)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Ready-to-type on load**
  - Automatically selects **Unit 1 → first sub-unit**, focuses the typing box, and starts in a ready stance.
  - When switching units, the **last active sub-unit** is restored (if visited).
- **Clear navigation & context**
  - The **selected unit** and **sub-unit** are visibly highlighted.
  - The top bar shows a dynamic, real-time title such as  
    **“Unit 1: asdf jkl; – Grip”**.
- **Data-driven UI (no hard-coding)**
  - Guide text and image(s) are rendered **from `assets/units.json`**.
  - **No limit on sub-units**—_all_ sub-units in JSON are rendered in the order provided.
- **Live metrics**
  - Progress (typed vs total), live **WPM** and **CPM** indicators, error count, and elapsed time.
  - Visual elements include a filling progress bar and simple gauges (speedometer-like feel).
- **Inline session summary**
  - When a sub-unit is completed, results appear **below** the real-time metrics (no modal pop-ups).
- **Consistent theming**
  - Palette:
    - Yellow `#f4b233`
    - Green `#1f5f45`
    - Red `#7a1717` (accent)
  - Header & footer in green; left panel in yellow; key text accents in red.
- **Footer**
  - Centered copyright:
    ```
    Asante Typing Tutor © John Francis Mukulu SJ 2025 - mukulu.org
    ```

---

## Tech Stack

- **Flutter** (Dart)
- Pure Flutter widgets (no native plugins required)

---

## Getting Started

### Prerequisites

- Flutter **3.x** (or newer)
- Dart SDK (bundled with Flutter)
- A connected device or emulator/simulator

Verify your setup:

```bash
flutter --version
flutter doctor
```

### Download

```bash
git clone https://github.com/mukulu/asante-typing.git
cd asante-typing
# (optional) check out the active branch
git checkout feat/unified-layout
```

### Run (Debug)

```bash
flutter pub get
flutter run
```

Run on web:

```bash
flutter run -d chrome
```

### Build (Release)

```bash
# Web
flutter build web

# Android
flutter build apk

# iOS (on macOS with Xcode)
flutter build ios
```

---

## Project Structure

```
asante-typing/
├─ assets/
│  ├─ img/                 # JPG images used by lessons
│  └─ units.json           # All lesson data (titles, guides, images, sub-units)
├─ lib/
│  ├─ models/
│  │  └─ units.dart        # Units/Sub-units data model
│  ├─ screens/
│  │  └─ tutor_page.dart   # Main screen (unified layout, metrics, visuals)
│  └─ utils/
│     └─ typing_utils.dart # Helpers (e.g., formatDuration)
├─ pubspec.yaml
└─ README.md
```

---

## Configuration

### Assets

Declare assets in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/units.json
    - assets/img/
```

* Use **JPG** images in `assets/img/`.
* In `units.json`, image paths can be either `"img/file.jpg"` or `"assets/img/file.jpg"` (both are supported).

### Lesson Data (`units.json`)

A minimal example:

```json
{
  "main": [
    {
      "title": "asdf jkl;",
      "guide": "<p>Intro and hand placement tips…</p>",
      "images": ["img/home-row.jpg"],
      "subunits": {
        "Grip": "aaaa ssss dddd ffff jjjj kkkk llll ;;;;",
        "Word": "as as as sa sa sa …",
        "Control": "…",
        "Sentence": "…",
        "Test": "…"
      }
    }
  ]
}
```

Notes:

* **title**: Displayed next to the unit number (e.g., “Unit 1: asdf jkl;”).
* **guide**: HTML allowed; rendered as plain text for clarity.
* **images**: The **first** image is used as the lesson’s diagram.
* **subunits**: Keys become clickable chips. Include **any number** of sub-units; they render in JSON order.

---

## How It Works

* On first launch, the app auto-selects **Unit 1 → first sub-unit** and focuses the input field.
* Switching units restores the **last visited sub-unit** (or defaults to the first).
* The timer starts on the first keystroke; **metrics** update every second.
* When the typed text reaches the target length, the **Session Summary** appears **inline** under the live metrics.

---

## Development Standards

* Prefer modern APIs (e.g., **`color.withValues(alpha: …)`** instead of deprecated `withOpacity`).
* Avoid unnecessary local type annotations; rely on inference where clear.
* Keep constructors **before** other class members.
* Avoid non-null assertions (`!`) where receivers cannot be null.
* Ensure files end with a trailing newline.
* Do not hard-code sub-unit lists or assume a fixed count (use `units.json`).

---

## Quality & Linting

Run analysis and formatting before committing:

```bash
flutter analyze
dart format --set-exit-if-changed .
```

Recommended rules (already reflected in code):

* No deprecated APIs.
* No unnecessary type annotations.
* Constructors before non-constructor members.
* No unused imports or dead code.

---

## Documentation

* All lesson authoring lives in **`assets/units.json`** (see example above).
* To add a lesson:

  1. Add JPGs under `assets/img/`.
  2. Add the new lesson object to `assets/units.json`.
  3. Keep sub-unit keys in your desired display order.
  4. Run `flutter pub get` (if new assets) and start the app.

---

## Repository

* Main repo: [https://github.com/mukulu/asante-typing](https://github.com/mukulu/asante-typing)
* Active feature branch: `feat/unified-layout`

---

## Contributing

1. Fork and clone the repository.

2. Create a feature branch from `feat/unified-layout`:

   ```bash
   git checkout feat/unified-layout
   git checkout -b feat/your-feature
   ```

3. Make changes and run:

   ```bash
   flutter analyze
   dart format .
   # flutter test   # (enable when tests are added)
   ```

4. Commit with clear messages and open a Pull Request.

Please avoid:

* Re-introducing deprecated APIs.
* Hard-coding sub-unit lists or counts.
* Adding SVGs (use JPGs in `assets/img/`).
* UI color drift from the palette: `#f4b233`, `#1f5f45`, `#7a1717`.

---

# License — GNU General Public License v3.0

This repository is licensed under the **GNU General Public License, version 3 (GPL-3.0)**.  
You can read the full text from `LICENSE` at the root of this project.

Copyright © **John Francis Mukulu SJ**, 2025 — [https://mukulu.org](https://mukulu.org)