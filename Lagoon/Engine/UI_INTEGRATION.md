# Pool Water Engine - UI Integration

Diese Datei dokumentiert alle UI-Komponenten, die für die Engine-Integration benötigt werden.

---

## INPUTS - Was die UI liefern muss

### 1. Pool-Einstellungen (einmalig, in Settings)

| Feld | Typ | Beispiel | UI-Element |
|------|-----|----------|------------|
| `poolVolume_m3` | Double | 50.0 | Textfeld mit Stepper |

### 2. Produkt-Konfiguration (einmalig, in Settings)

| Feld | Typ | Beispiel | UI-Element |
|------|-----|----------|------------|
| `productId` | String | "chlor-granulat" | Textfeld |
| `kind` | Enum | chlorine, ph_minus, ph_plus | Picker |
| `unit` | String | "g" | Textfeld |
| `ppmChangePerUnit_per_m3` | Double | 1.0 | Textfeld (nur Chlor) |
| `pHChangePerUnit_per_m3` | Double | 0.01 | Textfeld (nur pH) |

Liste von Produkten verwalten (hinzufügen, bearbeiten, löschen)

### 3. Zielbereiche (einmalig, in Settings)

| Feld | Typ | Beispiel | UI-Element |
|------|-----|----------|------------|
| Chlor min_ppm | Double | 0.5 | Slider oder Textfeld |
| Chlor max_ppm | Double | 1.5 | Slider oder Textfeld |
| Chlor target_ppm | Double | 1.0 | Slider oder Textfeld |
| pH min | Double | 7.0 | Slider oder Textfeld |
| pH max | Double | 7.4 | Slider oder Textfeld |
| pH target | Double | 7.2 | Slider oder Textfeld |

### 4. Letzte Messung (MessenSheet)

| Feld | Typ | Beispiel | UI-Element |
|------|-----|----------|------------|
| `freeChlorine_ppm` | Double | 1.2 | Slider/Stepper |
| `pH` | Double | 7.3 | Slider/Stepper |
| `timestampISO` | String | automatisch | Date() beim Speichern |

### 5. Aktuelle Bedingungen (automatisch oder manuell)

| Feld | Typ | Quelle | UI-Element |
|------|-----|--------|------------|
| `waterTemperature_c` | Double | WeatherKit / manuell | Textfeld oder automatisch |
| `uvExposure` | Enum | WeatherKit / manuell | SegmentedControl (low/medium/high) |
| `poolCovered` | Bool | manuell | Toggle |
| `batherLoad` | Enum | manuell | SegmentedControl (none/low/high) |
| `filterRuntime_hours_per_day` | Double | Settings | Textfeld/Stepper |

### 6. Dosier-Verlauf (DosierenSheet)

| Feld | Typ | Beispiel | UI-Element |
|------|-----|----------|------------|
| `productId` | String | aus Liste | Picker |
| `amount` | Double | 150 | Textfeld/Stepper |
| `unit` | String | aus Produkt | automatisch |
| `kind` | Enum | aus Produkt | automatisch |
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
| `productId` | "Chlor-Granulat" | Text |
| `amount` | "150" | Prominente Zahl |
| `unit` | "g" | Einheit |
| `targetValue` | "-> 1.0 ppm" | Zielwert |
| `explanation` | "Chlor ist zu niedrig..." | Erklärungstext |

---

## PERSISTENZ (SwiftData)

### Zu speichernde Entitäten

1. **PoolSettings** - Volumen, Filterzeit, Zielbereiche
2. **Product** - Liste der konfigurierten Produkte
3. **Measurement** - Historische Messungen
4. **DosingEvent** - Historische Dosierungen

---

## AUFGABENLISTE

### Phase 1: Settings & Konfiguration

- [ ] PoolSettingsView erstellen (Volumen, Filterzeit)
- [ ] TargetRangesView erstellen (Chlor/pH Zielbereiche)
- [ ] ProductListView erstellen (Produkte verwalten)
- [ ] SwiftData Models für Persistenz

### Phase 2: Daten-Eingabe

- [ ] MessenSheet erweitern (Chlor + pH Eingabe)
- [ ] DosierenSheet erweitern (Produkt wählen, Menge eingeben)
- [ ] ConditionsView erstellen (Temperatur, UV, Abdeckung, Badegäste)

### Phase 3: Dashboard-Integration

- [ ] Engine mit TrendBars verbinden (geschätzte Werte anzeigen)
- [ ] Konfidenz-Indikator im Dashboard
- [ ] Empfehlungs-Anzeige (Karten oder Badges)

### Phase 4: Automatisierung (optional)

- [ ] WeatherKit für Temperatur/UV integrieren
- [ ] Automatische Bedingungen basierend auf Tageszeit
