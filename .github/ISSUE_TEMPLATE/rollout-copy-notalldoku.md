---
name: "Rollout: Copy_Notfalldoku"
about: "Plan Rollout Copy_Notfalldoku.ps1 script."
title: "Rollout: Copy_Notfalldoku.ps1"
labels: ["task", "powershell", "mf_notfalldoku"]
assignees: []
milestone: [1]
---

## Task
Einrichten des Scripts `Copy_Notfalldoku.ps1` auf einem PC pro Wohnbereich, je Einrichtung. 

## Einrichtung
- Bezeichnung: [EINRICHTUNG] 


## Dedizierte Clients
- [HOSTNAME]


## USB Sticks
- Anzahl:
- Bezeichner
  - [USBLabel]


## Checklist
- [ ] USB Stick vorbereitet
  - [ ] Freigabe im ESET Media Control
  - [ ] Benennung nach Schema
  - [ ] Bitlocker verschlüsselt
  - [ ] Am PC Angeschlossen
  - [ ] Bitlocker freigeschaltet (Dauerhaft)
  - [ ] Bitlocker Schlüssel Dokumentiert, Passwort Manager
- [ ] Aktuellste Script Version verwendet
- [ ] Aufgabenplanung eingerichtet
  - [ ] Manuelle Ausführung erfolgreich
  - [ ] CheckMK Statusdatei wird auf Server hochgeladen
  - [ ] CheckMK Status zeigt OK
    - [ ] Möglicherweise Monitoring anpassen

## Notes
Vorlage für Rollout in Einrichtungen