# Pool Water Engine - UI Integration

Diese Datei dokumentiert alle UI-Komponenten, die für die Engine-Integration benötigt werden.

---

## INPUTS - Was die UI liefern muss

### 1. Pool-Einstellungen (einmalig, in Settings)

| Feld | Typ | Beispiel | UI-Element |
|------|-----|----------|------------|
| `poolVolume_m3` | Double | 50.0 | Textfeld mit Stepper |
| `filterRuntime_hours_per_day` | Double | 8.0 | Slider (0-24h) |

### 2. Idealbereiche (einmalig, in Settings)

Target wird automatisch als Mitte des Bereichs berechnet.

| Feld | Typ | Beispiel | UI-Element |
|------|-----|----------|------------|
| Chlor min_ppm | Double | 0.5 | Slider oder Textfeld |
| Chlor max_ppm | Double | 1.5 | Slider oder Textfeld |
| pH min | Double | 7.0 | Slider oder Textfeld |
| pH max | Double | 7.4 | Slider oder Textfeld |

### 3. Letzte Messung (MessenSheet)

| Feld | Typ | Beispiel | UI-Element |
|------|-----|----------|------------|
| `freeChlorine_ppm` | Double | 1.2 | Slider/Stepper |
| `pH` | Double | 7.3 | Slider/Stepper |
| `timestampISO` | String | automatisch | Date() beim Speichern |

### 4. Wetter/Bedingungen (manuell, später WeatherKit)

Aktuell: `ManualWeatherProvider` verwenden
Später: Auf `WeatherKitProvider` umstellen (siehe `WeatherProvider.swift`)

| Feld | Typ | Quelle | UI-Element |
|------|-----|--------|------------|
| `temperature_c` | Double | manuell / WeatherKit | Textfeld oder automatisch |
| `uvIndex` | Double | manuell / WeatherKit | Slider (0-11) oder automatisch |
| `poolCovered` | Bool | manuell | Toggle |
| `batherLoad` | Enum | manuell | SegmentedControl (none/low/high) |

UV-Index wird automatisch gemappt:
- 0-2 → low
- 3-5 → medium
- 6+ → high

### 5. Dosierung (DosierenSheet)

Fixe Produkte (keine Konfiguration nötig):
- **Chlor** (chlorine) - Granulat, g
- **pH-Minus** (ph_minus) - Granulat, g
- **pH-Plus** (ph_plus) - Granulat, g

| Feld | Typ | Beispiel | UI-Element |
|------|-----|----------|------------|
| Produkt | Enum | chlorine, ph_minus, ph_plus | SegmentedControl oder Picker |
| `amount` | Double | 150 | Textfeld/Stepper |
| `timestampISO` | String | automatisch | Date() beim Speichern |

---

## OUTPUTS - Was die UI anzeigen muss

### 1. Geschätzter Wasserzustand (Dashboard/TrendBars)

| Feld | Anzeige | UI-Element |
|------|---------|------------|
| `freeChlorine_ppm` | "1.2 ppm" | VerticalTrendBar (links) |
| `pH` | "7.3" | VerticalTrendBar (rechts) |
| `nowTimestampISO` | "vor 2 Std" | Subtitle unter Wert |

### 2. Konfidenz-Indikator (Dashboard)

| Feld | Anzeige | UI-Element |
|------|---------|------------|
| `confidence` | high/medium/low | Icon-Farbe oder Badge |
| `reason` | "Messung 5 Stunden alt" | Tooltip oder Info-Sheet |

### 3. Dosier-Empfehlungen (Dashboard oder Sheet)

| Feld | Anzeige | UI-Element |
|------|---------|------------|
| `parameter` | "Chlor" / "pH" | Header |
| `action` | none -> Checkmark / dose -> Warning | Icon/Badge |
| `reasonCode` | IN_RANGE, TOO_LOW, TOO_HIGH | Farbcodierung |
| `productId` | "chlorine" / "ph_minus" / "ph_plus" | Text/Icon |
| `amount` | "150" | Prominente Zahl |
| `unit` | "g" | Einheit |
| `targetValue` | "-> 1.0 ppm" | Zielwert (Mitte des Idealbereichs) |
| `explanation` | "Chlor ist zu niedrig..." | Erklärungstext |

---

## PERSISTENZ (SwiftData)

### Zu speichernde Entitäten

1. **PoolSettings** - Volumen, Filterzeit, Idealbereiche
2. **Measurement** - Historische Messungen (Chlor, pH, Timestamp)
3. **DosingEvent** - Historische Dosierungen (Produkt, Menge, Timestamp)
4. **WeatherInput** - Manuelle Wettereingaben (Temperatur, UV-Index)

---

## AUFGABENLISTE

### Phase 1: Datenmodell & Settings

- [x] PoolSettingsView erstellen (Volumen, Filterzeit) ✅
- [x] IdealRangesView erstellen (Chlor/pH min/max) ✅ (ChemistrySettingsView)
- [ ] SwiftData Models erstellen (PoolSettings, Measurement, DosingEvent)

### Phase 2: Messungen & Dosierungen

- [x] MessenSheet erweitern (pH, Chlor, Temperatur Slider, Nutzung, Datum/Zeit) ✅
- [x] DosierenSheet erweitern (Produkt-Picker: Chlor/pH+/pH-, Menge, Datum/Zeit) ✅
- [ ] MessenSheet: Speichern in SwiftData
- [ ] DosierenSheet: Speichern in SwiftData

### Phase 3: Wetter/Bedingungen

- [x] WeatherSettingsView erstellen (UV-Index Slider, manuelle Eingabe) ✅
- [x] Abdeckung Toggle in PoolSettingsView ✅
- [x] Badegäste im MessenSheet ✅

### Phase 4: Dashboard-Integration

- [ ] Engine mit SwiftData verbinden (Messungen + Dosierungen laden)
- [ ] TrendBars mit geschätzten Werten verbinden
- [ ] Konfidenz-Indikator anzeigen
- [ ] Empfehlungs-Karten oder Badges

### Phase 5: WeatherKit (optional, später)

- [ ] WeatherKit Capability aktivieren
- [ ] WeatherKitProvider implementieren (siehe Placeholder in WeatherProvider.swift)
- [ ] Location-Permission anfragen
- [ ] Automatische Wetterdaten abrufen

---

## Code-Beispiel: Engine verwenden

```swift
// Einfachste Variante mit Defaults
let input = PoolWaterEngineInput.create(
    poolVolume_m3: 50.0,
    lastChlorine_ppm: 1.2,
    lastPH: 7.3,
    lastMeasurementISO: ISO8601DateFormatter().string(from: lastMeasurement.date),
    waterTemperature_c: 28.0,
    uvExposure: .high,
    poolCovered: false,
    batherLoad: .low,
    filterRuntime: 8.0,
    dosingHistory: dosingEvents  // aus SwiftData
)

let engine = PoolWaterEngine()
let output = engine.process(input)

// Ergebnisse
output.estimatedState.freeChlorine_ppm  // Geschätzter Chlorwert
output.estimatedState.pH                 // Geschätzter pH
output.confidence.confidence             // .high, .medium, .low
output.recommendations[0].action         // .none oder .dose
output.recommendations[0].amount         // Dosiermenge in g
```

---

## Architektur-Hinweis: WeatherKit-Umstellung

Die `WeatherProvider.swift` enthält:
- `WeatherData` - Wetterdaten-Struct
- `WeatherProvider` - Protocol
- `ManualWeatherProvider` - Manuelle Eingabe (aktuell)
- `WeatherKitProvider` - Placeholder (auskommentiert)

Später einfach:
1. WeatherKit Capability aktivieren
2. `WeatherKitProvider` auskommentieren
3. Statt `ManualWeatherProvider` den `WeatherKitProvider` verwenden
