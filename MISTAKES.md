# MISTAKES.md

Mistakes in this project that cost time. Every session reads this file before it
plans or changes anything, and writes its own mistakes here before it reports
done. The rules: `project_standards rule:"learning.mistakes-log"` and
`rule:"learning.mistakes-read"`.

The format, deliberately narrow:

- One `###` entry per mistake, newest on top.
- The heading is the trigger in one line — it is the only part that reaches the
  next session at startup.
- Three fields, none optional: **What happened**, **Trigger**, **Fix**.
- No entry without a trigger and a fix. Without the trigger the next session does
  not know what to watch for.
- An entry that turns out wrong or obsolete is corrected or deleted with one line
  saying why. A wrong entry costs more than a missing one.

<!-- Template, copy and fill in, then leave this comment in place:

### YYYY-MM-DD Short trigger in one line

- **What happened:** [what went wrong, one sentence]
- **Trigger:** [what caused it and how it could have been spotted first]
- **Fix:** [what resolved it, with the file or command]

-->

### 2026-08-16 `unavailable` in der HA-Historie als Geräteausfall gelesen

- **What happened:** Alle 106 Entitäten standen im Auswertungsfenster achtmal
  gemeinsam auf `unavailable`. Als Ausfall gezählt, zerschnitt das eine
  180-s-Wiederanlaufsperre in 44 s und 135 s — eine Sperrzeit, die es nie gab,
  in genau der Statistik, deren Aussage „immer exakt 180 s" ist.
- **Trigger:** `unavailable` an *allen* Entitäten gleichzeitig, mit
  Rückkehr im selben oder nächsten Sekundenschlag. Das ist ein
  Home-Assistant-Neustart, kein Geräteausfall. Der Gegenbeweis steht in der
  Zyklusreihe der Firmware: liegt dort an derselben Stelle keine Lücke, hat der
  ESP durchgehend weitergefragt.
- **Fix:** Echte Lücken aus der Zyklusreihe bestimmen (Abstand zweier
  aufeinanderfolgender Werte > 90 s), nicht aus `unavailable`. Phasen, die eine
  `unavailable`-Marke berühren, vorher zusammenführen.

### 2026-08-16 Zwei Register verglichen, die 14 s auseinander gelesen werden

- **What happened:** DI08 schien der Anforderung IR20 vorauszulaufen — der
  Melder zog bei IR20 = 41 an, und 42 kam erst danach. Daraus wurde monatelang
  eine gesuchte „zweite Bedingung". Es gibt keine: DI08 ist IR20 = 60, und der
  scheinbare Vorlauf ist die Leseordnung innerhalb eines Zyklus.
- **Trigger:** Ein Flankenversatz zwischen zwei Registern, der nur zwei Werte
  annimmt und dessen Beträge sich zur Zykluszeit addieren — hier −14 s und
  +16 s bei 30 s Zyklus. Das ist immer Abtastung, nie Physik.
- **Fix:** Vor jeder Kausalaussage zwischen zwei Registern die Verteilung des
  Versatzes ansehen, nicht nur sein Vorzeichen. Bimodal und in der Summe genau
  ein Zyklus heißt: dasselbe Ereignis.
