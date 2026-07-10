---
name: Feature request
about: Lobby-Layout responsiv machen (ScrollContainer)
title: "[FEATURE] Lobby-Layout mit ScrollContainer für kleine Auflösungen"
labels: enhancement, ux
assignees: ''

---

**Is your feature request related to a problem? Please describe.**
Auf kleinen Bildschirmauflösungen (800×600) läuft der untere Teil der Lobby (`ui/lobby.tscn`) aus dem Bildschirm, weil das VBox-Layout keine Scroll-Unterstützung hat.

**Describe the solution you'd like**
Das VBox in einen `ScrollContainer` legen, sodass auf kleinen Auflösungen gescrollt werden kann. Alternativ das Layout responsiver gestalten (Anchors /比例的).

**Describe alternatives you've considered**
- Feste Mindestauflösung vorgeben (schließt kleine Bildschirme aus)
- Aktuell: Overflächen-Teile unsichtbar

**Additional context**
Code-Review 2026-07-06, Punkt #8
