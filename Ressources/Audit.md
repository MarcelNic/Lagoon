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

---

## Offen (moegliche naechste Schritte)

### Robustheit / Safety
- **Division by Zero** in `ActiveAction.swift:49` — `progress` rechnet `elapsed / duration` ohne Guard fuer `duration == 0`
- **Force Cast** in `LiveActivityBackgroundManager.swift:24` — `task as! BGAppRefreshTask` sollte `as?` sein
- **Timer nie gestoppt** in `PoolcareState` — kein `deinit` um `timerCancellable` zu canceln
- **Stille Save-Fehler** in `PoolWaterState` (Zeilen 130, 156, 193, 212) — Errors nur geloggt, kein User-Feedback

### Performance
- **N+1 Queries** in `MeinPoolState.swift:105-126` — laedt ALLE Measurements/DosingEvents/CareTasks ohne Limit oder Predicate
- **Mehrfache @Query** in PoolcareView-Structs — gleiche Query in mehreren Structs, erzeugt doppelte Subscriptions

### Architektur
- **Fehlende @MainActor** auf `PoolWaterState` — Properties koennen theoretisch von Background-Thread geaendert werden
- **Data Race bei Task-Completion** in `PoolcareState.completeTask()` — 0.8s Delay zwischen Save und Re-Fetch, Task koennte zwischenzeitlich geloescht werden
- **Keine Input-Validierung** im Engine-Layer — ungueltige Messwerte werden ohne Pruefung verarbeitet

### UI-Konsistenz (kleinere Punkte)
- Horizontales Padding variiert zwischen 12-80px je nach View
- Unterschiedliche `presentationDetents` Strategien (`.medium`, `.large`, Custom Heights)
- Font-Groessen fuer gleiche semantische Bedeutung unterschiedlich (z.B. 13pt vs 15pt vs 17pt fuer Body-Text)
- Inkonsistente Opacity-Werte (`.opacity(0.5)` vs `.opacity(0.25)` vs `.opacity(0.15)`)
