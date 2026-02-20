# Logbuch: Gruppierte Dosierungen & Anpassen-Sheet Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Dosierungen die gleichzeitig gespeichert wurden (pH + Chlor) als einen kombinierten Logbuch-Eintrag zeigen, und das Bearbeiten-Sheet analog zum Anpassen-Sheet gestalten (mit Slidern, ohne SlideToConfirm/Zurück).

**Architecture:** `LogbookEntry` bekommt ein `dosings: [DosingItem]`-Array statt einzelner `product/amount/unit` Felder. `loadFromSwiftData()` gruppiert `DosingEventModel`-Records mit identischem Timestamp zu einem Eintrag. `EditDosierenSheet` wird auf die neue Datenstruktur umgestellt und das Layout vom `bearbeitenSections`-Block aus `MeasurementDosingSheet` übernommen.

**Tech Stack:** SwiftUI, SwiftData, `DosingFormatter` (bestehend), `PHType` enum (aus `MeasurementDosingSheet`)

---

### Task 1: `DosingItem` Struct + `dosings` Array in `LogbookEntry`

**Files:**
- Modify: `Lagoon/MeinPool/Models/LogbookEntry.swift`

**Kontext:** `LogbookEntry` hat aktuell `product: String?`, `amount: Double?`, `unit: String?` für Dosierungen. Diese werden durch `dosings: [DosingItem]` ersetzt.

**Step 1: `DosingItem` Struct hinzufügen und Felder ersetzen**

In `LogbookEntry.swift` direkt vor dem `LogbookEntry`-Struct einfügen:

```swift
struct DosingItem: Equatable {
    var productId: String    // "ph_minus", "ph_plus", "chlorine"
    var productName: String  // "pH-Minus", "pH-Plus", "Chlorgranulat"
    var amount: Double
    var unit: String
}
```

In `LogbookEntry` die drei Felder ersetzen:
```swift
// ALT:
var product: String?
var amount: Double?
var unit: String?

// NEU:
var dosings: [DosingItem]
```

`init` anpassen: `product/amount/unit`-Parameter entfernen, `dosings: [DosingItem] = []` hinzufügen.

**Step 2: `DosingEventModel.toLogbookEntry()` Extension anpassen**

```swift
extension DosingEventModel {
    func toLogbookEntry() -> LogbookEntry {
        let dosingUnit = UserDefaults.standard.string(forKey: "dosingUnit") ?? "gramm"
        let cupGrams = UserDefaults.standard.double(forKey: "cupGrams")
        let effectiveCupGrams = cupGrams > 0 ? cupGrams : 50.0
        let formattedAmount = DosingFormatter.format(grams: amount, unit: dosingUnit, cupGrams: effectiveCupGrams)

        return LogbookEntry(
            type: .dosieren,
            timestamp: timestamp,
            summary: "\(formattedAmount) \(productName)",
            dosings: [DosingItem(productId: productId, productName: productName, amount: amount, unit: unit)]
        )
    }
}
```

**Step 3: `sampleEntries()` anpassen**

Die zwei `.dosieren`-Sample-Einträge auf `dosings:` umstellen:
```swift
LogbookEntry(
    type: .dosieren,
    timestamp: calendar.date(byAdding: .hour, value: -5, to: now)!,
    summary: "50 g pH-Minus",
    dosings: [DosingItem(productId: "ph_minus", productName: "pH-Minus", amount: 50, unit: "g")]
),
// ...
LogbookEntry(
    type: .dosieren,
    timestamp: calendar.date(byAdding: .day, value: -4, to: now)!,
    summary: "200 g Chlorgranulat",
    dosings: [DosingItem(productId: "chlorine", productName: "Chlorgranulat", amount: 200, unit: "g")]
),
```

**Step 4: Build-Fehler beheben**

`xcodebuild -project Lagoon.xcodeproj -scheme Lagoon -configuration Debug build 2>&1 | grep -E "error:|Build succeeded"` ausführen. Alle Stellen die `entry.product`, `entry.amount`, `entry.unit` verwenden (EditDosierenSheet, LogbookZone etc.) reparieren – diese kommen in späteren Tasks sauber rein.

**Step 5: Commit**
```bash
git add Lagoon/MeinPool/Models/LogbookEntry.swift
git commit -m "refactor: replace product/amount/unit with dosings array in LogbookEntry"
```

---

### Task 2: Gruppierung in `loadFromSwiftData`

**Files:**
- Modify: `Lagoon/MeinPool/MeinPoolState.swift:115-136`

**Kontext:** Aktuell: `dosings.map { $0.toLogbookEntry() }` – jeder Record wird einzeln konvertiert. Neu: nach Timestamp gruppieren.

**Step 1: Dosing-Lade-Block ersetzen**

Den Block von Zeile 115–123 ersetzen (nach dem `dosingDescriptor.fetchLimit = 200` / fetch):

```swift
if let dosings = try? context.fetch(dosingDescriptor) {
    // Gruppiere nach exakt gleichem Timestamp
    let grouped = Dictionary(grouping: dosings, by: { $0.timestamp })

    let dosingUnit = UserDefaults.standard.string(forKey: "dosingUnit") ?? "gramm"
    let cupGrams = UserDefaults.standard.double(forKey: "cupGrams")
    let effectiveCupGrams = cupGrams > 0 ? cupGrams : 50.0

    for (timestamp, group) in grouped {
        let items = group.map { d in
            DosingItem(productId: d.productId, productName: d.productName, amount: d.amount, unit: d.unit)
        }
        let summaryParts = items.map { item in
            "\(DosingFormatter.format(grams: item.amount, unit: dosingUnit, cupGrams: effectiveCupGrams)) \(item.productName)"
        }
        let entry = LogbookEntry(
            type: .dosieren,
            timestamp: timestamp,
            summary: summaryParts.joined(separator: " · "),
            dosings: items
        )
        allEntries.append(entry)
    }
}
```

**Step 2: `deleteFromSwiftData(.dosieren)` – alle Records löschen**

In `deleteFromSwiftData` den `.dosieren`-Case anpassen:
```swift
case .dosieren:
    let descriptor = FetchDescriptor<DosingEventModel>(
        predicate: #Predicate { $0.timestamp == timestamp }
    )
    if let matches = try? context.fetch(descriptor) {
        matches.forEach { context.delete($0) }
    }
```

**Step 3: `updateEntry` – SwiftData-Persistenz für Dosierungen**

In `updateEntry` nach `entries[index] = updatedEntry` hinzufügen:

```swift
if updatedEntry.type == .dosieren {
    updateDosingInSwiftData(updatedEntry)
}
```

Neue private Methode:
```swift
private func updateDosingInSwiftData(_ entry: LogbookEntry) {
    guard let context = modelContext else { return }
    let timestamp = entry.timestamp
    let descriptor = FetchDescriptor<DosingEventModel>(
        predicate: #Predicate { $0.timestamp == timestamp }
    )
    guard let models = try? context.fetch(descriptor) else { return }
    for item in entry.dosings {
        if let match = models.first(where: { $0.productId == item.productId }) {
            match.amount = item.amount
        }
    }
    try? context.save()
}
```

**Step 4: Build + kurz in Simulator testen**

App starten, im Logbuch prüfen: Einträge die von `saveAll()` stammen (gleichzeitige pH + Chlor Dosierung) sollen jetzt als ein Eintrag erscheinen.

**Step 5: Commit**
```bash
git add Lagoon/MeinPool/MeinPoolState.swift
git commit -m "feat: group simultaneous dosing entries in logbook by timestamp"
```

---

### Task 3: `EditDosierenSheet` neu implementieren

**Files:**
- Modify: `Lagoon/MeinPool/MeinPoolView.swift:239-341`

**Kontext:** Das Sheet soll aussehen wie `bearbeitenSections` aus `MeasurementDosingSheet` (pH-Section mit Segmented Picker + Slider, Chlor-Section mit Slider, DatePicker), aber mit X/✓ Toolbar statt SlideToConfirm.

**Referenz:** `Lagoon/MeasurementDosing/MeasurementDosingSheet.swift:397-454` – dieser Block ist das visuelle Vorbild.

**Referenz:** `PHType` enum ist in `MeasurementDosingSheet.swift` definiert – schauen ob es public ist oder ob es dupliziert werden muss.

**Step 1: `PHType` prüfen und ggf. in eigene Datei oder als `fileprivate` in MeinPoolView.swift definieren**

`Grep` auf `enum PHType` ausführen. Wenn es `private` oder `fileprivate` in `MeasurementDosingSheet.swift` ist, eine Kopie in `MeinPoolView.swift` vor `EditDosierenSheet` einfügen:

```swift
private enum PHType {
    case minus, plus
    var productId: String {
        switch self { case .minus: return "ph_minus"; case .plus: return "ph_plus" }
    }
    var productName: String {
        switch self { case .minus: return "pH-Minus"; case .plus: return "pH-Plus" }
    }
}
```

**Step 2: `EditDosierenSheet` komplett ersetzen**

Den gesamten Block `// MARK: - Edit Dosieren Sheet` (Zeilen 237–341) ersetzen mit:

```swift
// MARK: - Edit Dosieren Sheet

struct EditDosierenSheet: View {
    @Environment(\.dismiss) private var dismiss
    let entry: LogbookEntry?
    @Bindable var state: MeinPoolState

    @AppStorage("dosingUnit") private var dosingUnit: String = "gramm"
    @AppStorage("cupGrams") private var cupGrams: Double = 50.0

    @State private var editedPHAmount: Double = 0
    @State private var editedChlorineAmount: Double = 0
    @State private var phType: PHType = .minus
    @State private var editedDate: Date = Date()

    private var hasPH: Bool {
        entry?.dosings.contains(where: { $0.productId == "ph_minus" || $0.productId == "ph_plus" }) ?? false
    }
    private var hasChlor: Bool {
        entry?.dosings.contains(where: { $0.productId == "chlorine" }) ?? false
    }

    private var effectiveCupGrams: Double { cupGrams > 0 ? cupGrams : 50.0 }
    private var stepSize: Double { dosingUnit == "becher" ? effectiveCupGrams : 10 }
    private var maxPHAmount: Double { dosingUnit == "becher" ? effectiveCupGrams * 10 : 500 }
    private var maxChlorAmount: Double { dosingUnit == "becher" ? effectiveCupGrams * 20 : 1000 }

    init(entry: LogbookEntry? = nil, state: MeinPoolState) {
        self.entry = entry
        self.state = state
        if let entry = entry {
            _editedDate = State(initialValue: entry.timestamp)
            if let ph = entry.dosings.first(where: { $0.productId == "ph_minus" || $0.productId == "ph_plus" }) {
                _editedPHAmount = State(initialValue: ph.amount)
                _phType = State(initialValue: ph.productId == "ph_plus" ? .plus : .minus)
            }
            if let cl = entry.dosings.first(where: { $0.productId == "chlorine" }) {
                _editedChlorineAmount = State(initialValue: cl.amount)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if hasPH {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("pH")
                                Spacer()
                                Text(DosingFormatter.format(grams: editedPHAmount, unit: dosingUnit, cupGrams: effectiveCupGrams))
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                                    .animation(.snappy, value: editedPHAmount)
                            }
                            Picker("pH", selection: $phType) {
                                Text("pH-").tag(PHType.minus)
                                Text("pH+").tag(PHType.plus)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            Slider(value: $editedPHAmount, in: 0...maxPHAmount, step: stepSize)
                                .tint(.phIdealColor)
                        }
                    }
                }

                if hasChlor {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Chlor")
                                Spacer()
                                Text(DosingFormatter.format(grams: editedChlorineAmount, unit: dosingUnit, cupGrams: effectiveCupGrams))
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                                    .animation(.snappy, value: editedChlorineAmount)
                            }
                            Slider(value: $editedChlorineAmount, in: 0...maxChlorAmount, step: stepSize)
                                .tint(.chlorineIdealColor)
                        }
                    }
                }

                Section {
                    DatePicker(
                        selection: $editedDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    ) {
                        Label("Zeitpunkt", systemImage: "clock")
                            .foregroundStyle(.primary)
                    }
                }
            }
            .contentMargins(.top, 0)
            .navigationTitle("Dosierung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveEntry()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveEntry() {
        guard var existingEntry = entry else { return }

        var updatedDosings = existingEntry.dosings
        if hasPH, let idx = updatedDosings.firstIndex(where: { $0.productId == "ph_minus" || $0.productId == "ph_plus" }) {
            updatedDosings[idx].amount = editedPHAmount
            updatedDosings[idx].productId = phType.productId
            updatedDosings[idx].productName = phType.productName
        }
        if hasChlor, let idx = updatedDosings.firstIndex(where: { $0.productId == "chlorine" }) {
            updatedDosings[idx].amount = editedChlorineAmount
        }

        let dosingUnit = self.dosingUnit
        let effectiveCupGrams = self.effectiveCupGrams
        let summaryParts = updatedDosings.map { item in
            "\(DosingFormatter.format(grams: item.amount, unit: dosingUnit, cupGrams: effectiveCupGrams)) \(item.productName)"
        }

        existingEntry.dosings = updatedDosings
        existingEntry.timestamp = editedDate
        existingEntry.summary = summaryParts.joined(separator: " · ")
        state.updateEntry(existingEntry)
    }
}
```

**Step 3: Build-Fehler beheben**

Falls `PHType` doppelt definiert ist oder `phType.productId`/`phType.productName` fehlen → anpassen.

**Step 4: `LogbookListView` Detents prüfen**

Das Sheet wird mit `.presentationDetents([.medium])` geöffnet. Mit zwei Sections + DatePicker könnte `.medium` zu klein sein. Auf `[.medium, .large]` ändern in `LogbookListView.swift:55`.

**Step 5: Build + in Simulator testen**

- Dosierungs-Eintrag antippen → Sheet öffnet sich mit korrekten Sektionen
- pH-Slider, pH-Typ und Chlor-Slider funktionieren
- ✓ speichert, ✕ verwirft

**Step 6: Commit**
```bash
git add Lagoon/MeinPool/MeinPoolView.swift Lagoon/MeinPool/Views/LogbookListView.swift
git commit -m "feat: redesign EditDosierenSheet to match Anpassen layout with sliders"
```

---

### Task 4: Abschluss-Commit & Aufräumen

**Step 1: Design-Doc committen**
```bash
git add docs/plans/
git commit -m "docs: add logbuch grouped dosings design and plan"
```

**Step 2: Gesamten Build prüfen**
```bash
xcodebuild -project Lagoon.xcodeproj -scheme Lagoon -configuration Debug build 2>&1 | tail -5
```
Erwartet: `BUILD SUCCEEDED`

**Step 3: Push**
```bash
git push
```
