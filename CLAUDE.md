# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Lagoon is an iOS pool management app. This is a fresh SwiftUI project starting from scratch.

**Key Technologies:**
- SwiftUI for native iOS UI
- iOS 26.2+ deployment target
- Bundle ID: `com.marcel.Lagoon`

## Build Commands

```bash
# Build the project
xcodebuild -project Lagoon.xcodeproj -scheme Lagoon -configuration Debug build

# Clean build folder
xcodebuild clean -project Lagoon.xcodeproj -scheme Lagoon
```

**Running in Xcode:** Open `Lagoon.xcodeproj` and run the `Lagoon` scheme on iOS Simulator or device.

## Reference

The previous version of Lagoon is available at `/Users/marcelnicaeus/Github/Lagoon-v1` for reference. Key features from v1 included:
- SwiftData for persistence
- WeatherKit integration
- Chemistry prediction engine with coefficient learning
- Dosing recommendations
- Care task management

GitHub: github.com/MarcelNic/Lagoon-v1

## UI Design Guidelines (iOS 26 Liquid Glass)

Die App soll einen nativen iOS 26 Look mit Liquid Glass haben. Referenz: `/Users/marcelnicaeus/Github/Lagoon/Ressources/README.md`

### Kernprinzipien
- **Standard SwiftUI Komponenten** verwenden – diese erhalten Liquid Glass automatisch
- **Keine custom Backgrounds** bei Controls und Navigation – das System bestimmt das Erscheinungsbild
- **Liquid Glass sparsam** bei Custom Views einsetzen – nur für wichtige funktionale Elemente
- **Systemfarben** verwenden, die sich automatisch an Light/Dark anpassen

### Wichtige APIs

```swift
// Glass Effect auf Views
.glassEffect()
.glassEffect(in: .rect(cornerRadius: 16.0))
.glassEffect(.regular.tint(.orange).interactive())

// Button Styles
.buttonStyle(.glass)
.buttonStyle(.glassProminent)  // Für primäre Aktionen wie "Done"

// Container für mehrere Glass Effects (bessere Performance + Morphing)
GlassEffectContainer(spacing: 40.0) {
    // Views mit .glassEffect()
}

// Morphing Transitions
.glassEffectID("identifier", in: namespace)
.glassEffectUnion(id: "groupId", namespace: namespace)

// Navigation
NavigationSplitView { } detail: { }
.backgroundExtensionEffect()  // Hintergrund unter Sidebar erweitern
.tabBarMinimizeBehavior(.onScrollDown)  // Tab Bar beim Scrollen minimieren
Tab(role: .search) { }  // Semantische Search Tabs
```

### Best Practices
- Klare Navigationshierarchie – Content von Navigation trennen
- Toolbar Items logisch gruppieren (max. 3 Gruppen)
- Standard Back/Close Buttons verwenden
- Symbols statt Text in Toolbars bevorzugen
- Forms mit `.grouped` Style für automatische Layout-Metriken
- Section Headers in Title Case (nicht UPPERCASE)
- Mit Accessibility Settings testen (Reduce Transparency, Reduce Motion)
