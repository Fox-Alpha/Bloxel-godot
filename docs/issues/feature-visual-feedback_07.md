---
name: Feature request
about: Visuelles Feedback für Line-Clears, Locking und Level-Up
title: "[FEATURE] Visuelles Feedback bei Line-Clears / Level-Up"
labels: enhancement, ux
assignees: ''

---

**Is your feature request related to a problem? Please describe.**
Line-Clears, Locking und Level-Up haben keinerlei Animation, Partikel oder Screen-Shake. Das Spiel wirkt statisch und gibt dem Spieler kein visuelles Feedback für Erfolge.

**Describe the solution you'd like**
- Line-Clear: kurz aufblinken lassen (Timer + draw_rect) vor dem Entfernen
- Level-Up: kurzer Screen-Shake oder Farbblitz
- Option: einfache Partikel-Explosion bei Clear (GPUParticles2D)

**Describe alternatives you've considered**
- Nur Sound (kommt evtl. später)
- Aktuell: gar kein Feedback

**Additional context**
Code-Review 2026-07-06, Punkt #7
