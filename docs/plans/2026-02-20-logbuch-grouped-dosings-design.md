# Design: Logbuch – Gruppierte Dosierungen & verbessertes Bearbeiten-Sheet

**Datum:** 2026-02-20
**Status:** Approved

---

## Problem

1. Wenn pH und Chlor gleichzeitig dosiert werden (via `saveAll()` in `MeasurementDosingSheet`), entstehen zwei `DosingEventModel`-Records mit identischem Timestamp. Diese erscheinen im Logbuch als zwei separate Einträge.

2. Das Bearbeiten-Sheet für Dosierungen (`EditDosierenSheet`) unterstützt nur ein einzelnes Produkt und orientiert sich nicht am Anpassen-Sheet aus dem MeasurementDosing-Flow.

---

## Feature 1: Gruppierte Dosierungen

### Datenmodell-Erweiterung (`LogbookEntry.swift`)

- Neues `struct DosingItem: Equatable` mit Feldern: `productId: String`, `productName: String`, `amount: Double`, `unit: String`
- `LogbookEntry` bekommt neues Feld: `var dosings: [DosingItem]`
- Bestehende Felder `product/amount/unit` werden entfernt
- `DosingEventModel.toLogbookEntry()` wird auf `dosings: [DosingItem(...)]` umgestellt
- Summary für Gruppeneinträge: `"50 g pH-Minus · 200 g Chlorgranulat"`
- Sample-Entries anpassen

### Laden & Gruppieren (`MeinPoolState.loadFromSwiftData`)

- Nach Fetch alle `DosingEventModel` nach **exakt gleichem Timestamp** gruppieren
- Pro Gruppe ein `LogbookEntry` mit allen `DosingItem`s
- Sortierung bleibt: neueste zuerst

### Löschen (`MeinPoolState.deleteFromSwiftData(.dosieren)`)

- Statt nur ersten Treffer: **alle** `DosingEventModel` mit dem Timestamp löschen

---

## Feature 2: Bearbeiten-Sheet

### Layout (orientiert an `bearbeitenSections` aus `MeasurementDosingSheet`)

```
Toolbar: [✕ xmark]   "Dosierung bearbeiten"   [✓ checkmark]

Section – pH (nur wenn dosings einen pH-Eintrag enthält):
  ┌─ HStack: "pH"  ———————————————  DosingFormatter.format(...)
  ├─ Segmented Picker: [pH-] [pH+]
  └─ Slider(value: $editedPHAmount, in: 0...maxPHAmount, step: stepSize)

Section – Chlor (nur wenn dosings einen Chlor-Eintrag enthält):
  ┌─ HStack: "Chlor"  —————————————  DosingFormatter.format(...)
  └─ Slider(value: $editedChlorineAmount, in: 0...maxChlorineAmount, step: stepSize)

Section – Zeitpunkt:
  └─ DatePicker("Zeitpunkt", ...)
```

### State

- `@AppStorage("dosingUnit")` + `@AppStorage("cupGrams")` für Formatierung
- `@State var editedPHAmount: Double` (aus dosings)
- `@State var editedChlorineAmount: Double` (aus dosings)
- `@State var phType: PHType` (.minus / .plus aus productId)
- `@State var editedDate: Date` (aus entry.timestamp)

### Speichern

- `saveEntry()` aktualisiert in-memory `entries` array
- Auch SwiftData updaten: per Timestamp + productId die passenden `DosingEventModel`-Records finden und `amount` aktualisieren

---

## Nicht geändert

- `LogbookEntryRow` – summary-Anzeige funktioniert weiterhin
- `LogbookListView` – routing zu `showDosierenSheet` bleibt gleich
- Präsentation: `.presentationDetents([.medium])`
