# Life-Empire
Life Empire is a 2D life simulation and business tycoon game built with Godot 4. Build your career, start businesses, manage properties, grow your wealth, and create your own empire in India and around the world.

An offline-first Android **life simulator + business tycoon**, built in **Godot 4.3** with GDScript.
Start at 18 with a family background, study, work, build businesses, borrow, save, buy property —
and age one year at a time.

Currency is Indian Rupees (₹), formatted in Lakh / Crore.

---

## Status — Version 1

Playable today:

| System | State |
|---|---|
| Character creation (name, gender, age, family background) | Working |
| Year-by-year life progression from 18 | Working |
| Education (6 degrees, cost + duration + smarts) | Working |
| Careers (8 jobs, government / private / military / business) | Working |
| Salary, performance and promotion | Working |
| Business empire (8 business types, 12 levels each) | Working |
| Bank: savings at 6%, loans at 11%, auto repayment | Working |
| Property & lifestyle (houses, cars, yacht, jet) | Working |
| Health, happiness, smarts, fitness, reputation | Working |
| Random life events (12 weighted events) | Working |
| Achievements, XP and levels | Working |
| Death and end-of-life summary | Working |
| Offline save / load (JSON, atomic, with backup) | Working |

Not in V1 (planned): farming and dairy depth, airline route management, stock market,
dating/marriage/children, next-generation inheritance, world map, sound.

There is **no APK in this repository**. The project was validated by running Godot 4.3
headless (import, 40-year simulation, save round trip, all 7 screens). See
[Building the Android APK](#building-the-android-apk) — you build it on your machine in
about five minutes once the Android SDK is set up.

---

## Running it

1. Install **Godot 4.3** (standard build, not .NET).
2. Open `project.godot`.
3. Press **F5**.

The window is set to a 1080×1920 portrait viewport with `canvas_items` stretch, so it
scales to any Android screen and to the desktop window.

## Running the tests

```
godot --headless --path . res://tools/TestSim.tscn
```

Exits 0 on pass, 1 on failure. It checks a new game, simulates 40 years with automated
choices, verifies the save/load round trip preserves net worth, constructs all seven
screens, and proves the simulation is deterministic: the same seed must produce the same
life twice.

---

## Project layout

```
project.godot           Godot config: portrait 1080x1920, GL Compatibility, autoloads
autoload/
  EventBus.gd           Global signals — the only way screens and model talk
  Database.gd           All balance data: backgrounds, degrees, jobs, businesses, events
  SaveManager.gd        Atomic JSON save to user:// with .bak fallback
  GameState.gd          The life model: every number and every yearly rule
ui/
  LETheme.gd            Blue / purple / gold theme, built in code
  UI.gd                 Widget factory (cards, stat bars, pills, buttons)
scenes/
  Main.tscn/.gd         App shell: theme, screen routing, bottom navigation
  screens/*.gd          One screen per file, built programmatically
tools/
  TestSim.tscn/.gd      Headless soak test
```

Screens are built in code rather than as `.tscn` files: there is no scene to merge, the
whole UI is one diffable GDScript file per screen, and the widget factory keeps spacing
and colour consistent.

## How a year resolves

`GameState.advance_year()` runs, in order:

1. age +1
2. education progress (degree completes, smarts rise)
3. job salary paid, performance drifts, promotion if performance ≥ 60 and enough years
4. business income minus 15% upkeep
5. savings interest at 6%, loan interest at 11% with automatic repayment
6. living costs (35% of your annual income, minimum ₹48,000, plus ₹24,000 per property)
7. health decay, fitness decay, happiness drifting toward 55
8. one weighted random event
9. achievement checks
10. XP and level
11. death check (health ≤ 0, or age ≥ lifespan)

The result is written to the event log, saved, and emitted as `EventBus.year_report`.

## Balance

Cost to take a business from level `n` to `n+1`:

```
cost(n) = base_cost × cost_exp^n        cost_exp ≈ 1.45 – 1.62
income(n) = base_income × 1.35^(n-1)
```

Because cost grows faster than income, every level costs more than the last and the
player has to keep reinvesting. Job salary grows at `growth^level` (1.06 for delivery
work up to 1.18 for a business unit head), so careers with a degree out-earn early jobs.

Living costs scale with income (35%, floor ₹48,000 a year), so an 18-year-old with
₹50,000 is not bankrupted in year one, while a tycoon does not keep every rupee. If cash
cannot cover a charge, the shortfall becomes an emergency loan rather than a silently
negative balance — debt is always visible in the Bank screen and counted in net worth.

All of these numbers live in `autoload/Database.gd` and the constants at the top of
`autoload/GameState.gd` — two files, no code changes needed.

## Reproducible balance runs

`GameState.use_seed(n)` seeds every random source in the game — lifespan, performance
drift and random events. Two runs with the same seed produce an identical life, so a
balance change can be measured against a fixed baseline instead of noise.

---

## Building the Android APK

This needs a machine with Godot and the Android toolchain. Steps:

1. **Export templates** — in Godot: `Editor → Manage Export Templates → Download and Install`.
2. **JDK 17** — install it (e.g. Temurin 17).
3. **Android SDK** — install Android Studio or the command-line tools, then in the SDK
   Manager add *Android SDK Platform 34*, *Android SDK Build-Tools*, *Platform-Tools* and
   *Command-line Tools*.
4. **Point Godot at them** — `Editor → Editor Settings → Export → Android`:
   set **Android SDK Path** and **Java SDK Path**.
5. **Debug keystore** — same screen: set **Debug Keystore** to
   `~/.android/debug.keystore` (alias `androiddebugkey`, password `android`).
   For a release build, create your own keystore with `keytool` and keep it out of git.
6. **Export preset** — `Project → Export → Add… → Android`, then set:
   - Package name: `com.yourstudio.lifeempire` (must be unique on Play)
   - Min SDK `24`, Target SDK `34`
   - Architectures: tick **arm64-v8a** and **armeabi-v7a**
   - Texture format: **ETC2/ASTC**
   - Screen orientation: **Portrait**
   - Export path: `build/life-empire.apk`
7. **Export** — `Export Project…`, untick *Export With Debug* for a release build.
8. **Install** — `adb install -r build/life-empire.apk`

`build/`, `*.apk`, `*.aab` and `*.keystore` are already in `.gitignore`.

## Design decisions

- **Manual year advance, not a real-time clock.** The player chooses when a year passes,
  so nothing happens while the app is closed and there is no offline drift to reconcile.
- **Money is an `int` in whole rupees.** No float accumulation across thousands of
  transactions.
- **Saves are written to a temp file and renamed** so an Android process kill mid-write
  cannot corrupt the save; a `.bak` copy is kept.
- **Data lives in `Database.gd`, not in scenes.** Rebalancing is a one-file edit.
