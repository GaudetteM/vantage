# App Icon Assets

The built-in generator creates three PNG files here:

## icon.png  (required)
- **Size:** 1024 × 1024 px
- **Background:** transparent (or `#0D0D1A` dark fill)
- **Content:** full bleed — the diamond logo centred with some padding (~10 %)
- Used for: web, macOS, Windows, and as the Android legacy icon fallback

## icon_foreground.png  (required for Android adaptive icon)
- **Size:** 1024 × 1024 px
- **Background:** fully transparent
- **Content:** logo artwork only — keep it inside the **safe zone** (centre 66 %, ~680 × 680 px)
  because Android adaptive icons are cropped to various shapes by the launcher
- The background colour (`#0D0D1A`) is set in `pubspec.yaml` via `adaptive_icon_background`

## icon_ios.png  (generated for iOS)
- **Size:** 1024 × 1024 px
- **Background:** fully opaque `#0D0D1A`
- **Content:** same logo as `icon.png`, but flattened with no alpha so App Store/iOS icon generation is safe

---

## Design notes
The logo is the 4-dot diamond from the HUD indicator:
- North dot — green  `#81C784`
- East dot  — amber  `#FFC857`
- South dot — red    `#E57373`
- West dot  — purple `#7C4DFF`
- Centre dot — cyan  `#00E5FF`

Suggested export: Figma / Illustrator at 1024 × 1024 → PNG-24 with transparency.

---

## Generating icons on macOS

You can generate the source PNGs with the built-in Swift tool in this repo.
No Figma or extra design app is required.

```bash
swift generate_icons.swift
dart run flutter_launcher_icons
```

This will:
- create `assets/images/icon.png`
- create `assets/images/icon_foreground.png`
- create `assets/images/icon_ios.png`
- generate all platform icon sizes automatically

Note: iOS uses `icon_ios.png` directly, which is generated as a fully opaque
image and avoids the black-icon issue caused by alpha flattening.
