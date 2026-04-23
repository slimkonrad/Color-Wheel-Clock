# Color Wheel Clock 🎨🕰️

This application was created as a project for CPSC at **CSUF - California State University, Fullerton**. This repository will temporarily be public and will be private again when the grading period is over.

### Overview
A mobile application that moves away from traditional digital/analog clock faces and instead represents time through the visual spectrum of a color wheel. Instead of reading numbers, the user perceives time through shifting hues, saturation, and brightness.

# Deployment Instructions

## Requirements
- macOS with Xcode 15+ installed
- iOS 17.0+ simulator (built into Xcode) or a physical iPhone
- Swift 6
- For running on a real device, an Apple ID added to Xcode for code signing

# Setting Up The Project

- Download or clone the repository
- Open `Color Wheel Clock.xcodeproj` in Xcode
- In the Xcode toolbar, select the **Color Wheel Clock** target
- Verify that the target iOS version in Deployment Info is set to **iOS 17.0+**

# Deploying To A Simulator

- In Xcode, pick an iOS Simulator from the device dropdown (e.g. iPhone 17 Pro)
- Press **⌘ + R** or click the Run button
- Xcode will build the app and automatically launch it in the simulator

# How To Use The Application

## Clock

### How It Works
Time is mapped to the HSL (Hue, Saturation, Lightness) color model:

- **Hours (0–12)** → Hue (0°–360°) — a full color spectrum cycle every 12 hours
- **Minutes (0–60)** → Saturation — desaturated early in the hour, vivid toward the end
- **Seconds (0–60)** → Brightness — a subtle sine-wave pulse on the second hand

### Reading The Clock
- The **color wheel ring** displays the full spectrum and reflects the current time's hue
- The **hour and minute hands** are white, styled like a minimal analog clock
- The **second hand** is colored to match the current time's hue and pulses subtly
- A **digital readout** beneath the face shows the exact time in `hh:mm:ss` format

## Timer

### Setting A Timer
- Tap **"set time"** in the center of the timer ring
- Use the scroll wheels to select **minutes** and **seconds**
- Tap **"start"** to confirm and begin the countdown

### Reading The Timer
- The **color sweep arc** drains clockwise as time counts down
- The arc color shifts from **green → red** as time runs out, giving an immediate visual sense of urgency
- The remaining time is displayed numerically in the center
- A **"done"** label appears when the timer reaches zero

### Controls
- **Play/Pause** — start or pause the countdown
- **Reset (↺)** — return to the full duration
- **+ button** — add one minute to the current timer

## Switching Between Modes
- Swipe left/right or use the **clock / timer** pill buttons at the bottom of the screen to switch between the two modes

# The Team
- **Konner Rigby**
- **Oscar Sanchez**

---
*Developed for CSUF Computer Science — April 2026*
