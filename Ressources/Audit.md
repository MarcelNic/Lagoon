# App-Audit 12.02.2026

## Erledigt

### Dead Code entfernt
- `MeasurementSheets.swift` geloescht (MessenSheet/DosierenSheet nirgends instanziiert)
- `recordCareTask()` aus `PoolWaterState.swift` entfernt (nie aufgerufen)

### Farben zentralisiert
- `temperatureColor(for:)` aus MeasurementDosingSheet in `ChemistryColors.swift` als `Color.temperatureColor(for:)` verschoben
- pH/Chlor Marker-Border-Farben als adaptive Colors in ChemistryColors (`phMarkerBorderColor`, `chlorineMarkerBorderColor`)
- `VerticalTrendBarV2`: zwei separate Light/Dark Params zu einem `markerBorderColor: Color` vereinfacht

### UI-Konsistenz
- AddItemSheet Confirm-Button: `.borderedProminent.tint(.blue).clipShape(Circle())` durch Checkmark-Icon ersetzt (wie alle anderen Sheets)
- `cancelAction` in PoolcareState: Full-Table-Scan durch Predicate-Fetch mit `fetchLimit: 1` ersetzt

### Code-Organisation
- `PoolcareView.swift` von ~1084 auf ~400 Zeilen reduziert
- Extrahierte Dateien: `AddItemSheet.swift`, `EditTaskSheet.swift`, `ScenarioSheets.swift`, `TimerPickerSheet.swift`

### Care-Task Erinnerungen implementiert
- `NotificationManager` erweitert: `scheduleCareTaskReminder(task:)`, `cancelCareTaskReminder(taskId:)`, `scheduleTimerExpiredNotification(taskTitle:taskId:)`
- `PoolcareState`: addTask/updateTask/completeTask/deleteTask rufen Notification-Scheduling auf
- `remindAfterTimer`: ActiveAction traegt Flag, checkExpiredActions() feuert Notification bei Timer-Ablauf
- `PoolcareState.configure(modelContext:notificationManager:)` ersetzt `setModelContext()`

### Robustheit / Safety
- **Division by Zero** behoben in `ActiveAction.swift` und `LiveActivityBackgroundManager.swift` — Guard fuer `duration <= 0`
- **Force Cast** behoben in `LiveActivityBackgroundManager.swift` — `as!` durch sicheres `as?` mit `setTaskCompleted(success: false)` Fallback ersetzt
- **Timer-Cleanup** hinzugefuegt in `PoolcareState` — `deinit` cancelt `timerCancellable`
- **Save-Fehler sichtbar** in `PoolWaterState` — `lastSaveError` Property + `saveContext()` Helper + Alert in MainTabView

### Architektur
- **@MainActor** auf `PoolWaterState` hinzugefuegt — Thread-Safety fuer @Observable class
- **Data Race in completeTask()** behoben — `context.model(for:)` durch sicheren `FetchDescriptor` mit Predicate ersetzt
- **Input-Validierung** im Engine-Layer — `PoolWaterEngineInput.validated()` Extension clampt alle Werte auf physikalisch sinnvolle Bereiche

### Performance
- **Logbook-Queries optimiert** in `MeinPoolState` — 90-Tage Predicate + `fetchLimit: 200` fuer alle drei FetchDescriptors
- **Doppelte @Query entfernt** in ScenarioSheets — `scenarios` wird als Parameter von PoolcareView uebergeben statt dreifach per @Query geladen

---

## Offen (moegliche naechste Schritte)

### UI-Konsistenz (kleinere Punkte)
- Horizontales Padding variiert zwischen 12-80px je nach View
- Unterschiedliche `presentationDetents` Strategien (`.medium`, `.large`, Custom Heights)
- Font-Groessen fuer gleiche semantische Bedeutung unterschiedlich (z.B. 13pt vs 15pt vs 17pt fuer Body-Text)
- Inkonsistente Opacity-Werte (`.opacity(0.5)` vs `.opacity(0.25)` vs `.opacity(0.15)`)
