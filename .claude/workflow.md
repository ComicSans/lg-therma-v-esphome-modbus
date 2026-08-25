# How We Work

Das Arbeitsmodell. Projektunabhängig — was hier steht, gilt in jedem Projekt,
das es übernimmt. Projektspezifisches (Testkommandos, Gates, Domain-Docs) steht
in der `CLAUDE.md` des jeweiligen Projekts.

Gespiegelt mit `scripts/mirror-setup.sh <zielprojekt>`.

## Eine Sitzung spricht mit Tobias

Diese Sitzung ist der **Koordinator**, und sie startet jeden anderen Agenten als
Subagenten ihrer selbst. Niemand sonst öffnet eine Sitzung, und niemand außer
dem Koordinator berichtet an Tobias.

Agenten, die als eigenständige Sitzungen nebeneinander laufen, verlieren Arbeit:
Nachrichten landen an toten Sockets, Verdikte verschwinden mit ihrem Empfänger,
zwei Agenten schreiben denselben Fix, ein fremdes `git reset` verdrängt einen
laufenden `cherry-pick`. Die sitzungsbezogenen dieser Fehlerformen haben
Subagenten nicht, und Tobias hat einen Ansprechpartner statt fünf.

Gegen Kollisionen im Arbeitsbaum sind sie dagegen nicht immun. Zwei Subagenten,
die gleichzeitig schreiben, treffen sich dort genauso, und wer misst, während
ein anderer schreibt, sieht Änderungen ohne Absender.

**Aus einem Subagenten geht nur sein Endergebnis in den Verlauf des
Koordinators**, in wenigen Stichpunkten, ohne Zwischenstände und ohne
Wiedergabe seiner Begründung. Die Begründung steht in der Aufgabendatei, dort
gehört sie hin und dort überlebt sie die Sitzung. Der Verlauf des Koordinators
ist die knappste Ressource der Sitzung, und jeder nacherzählte Agentenbericht
kostet Platz, den die Arbeit danach braucht.

## Rollen und Modelle

| Rolle | Modell | Reasoning | Tut |
|---|---|---|---|
| **Koordinator** | Opus 5 | high | Plant, schneidet die Arbeit in atomare Subtasks, startet Subagenten, bewertet, was zurückkommt, spricht mit Tobias. Schreibt Code nur für Einzeiler. |
| **Produktmanager** | Fable 5 | high | Entscheidet, ob eine Änderung ins Produkt gehört und unter welchen Auflagen. Hält die Domain-Docs. Sagt, welche Suite eine Änderung braucht. |
| **Coder** | Sonnet 5 | siehe unten | Setzt einen geschnittenen Subtask um. |
| **Reviewer** | Sonnet 5 | high | Gate vor dem Commit. Sieht Spezifikation und `git diff`, nie einen Gesprächsverlauf. |
| **Architekt** | Fable 5 | high | Sieht das Muster statt des Falls. Wird vor dem Schnitt gerufen, nicht danach. Blockiert nichts. |

**Architekt und Reviewer sehen denselben Code und beantworten verschiedene
Fragen.** Der Reviewer bekommt einen Diff und eine Spezifikation und fragt, ob
dieser Diff tut, was er soll, und sonst nichts; er steht nach dem Bauen und vor
dem Commit, und sein Wort ist ein Gate. Der Architekt bekommt keinen Diff,
sondern eine Frage, und steht vor dem Bauen; er fragt, ob die Form richtig ist
und wo dasselbe noch steht, und sein Wort ist eine Empfehlung.

Gerufen wird er beim zweiten Fund derselben Ursache, vor einem Umbau an einem
zentralen Pfad, vor einer Migration mit Nutzerdaten, bei einem Widerspruch
zwischen zwei verbindlichen Dokumenten, und vor dem Schnitt einer Aufgabe, die
niemand in einem Zug baut. Nicht für jede Aufgabe: eine Rolle, die immer
mitläuft, wird zur Zeremonie.

Der Anlass ist gemessen. Am 25.08.2026 wurde dieselbe Ableitung dreimal
einzeln gefunden und zweimal einzeln behoben, dieselbe Testverschmutzung zum
vierten Mal, und ein Widerspruch zwischen zwei verbindlichen Dateien fiel erst
auf, als ein Agent daran die Arbeit verweigerte. Keiner dieser Fälle ist ein
Diff-Fehler, keinen davon kann ein Reviewer sehen, der immer nur einen Diff vor
sich hat.

**Die Reasoning-Stufe des Coders setzt der Koordinator beim Start, nie der Coder
selbst.** `medium` ist der Normalfall für mechanische Arbeit. `high` ist Pflicht,
sobald der Subtask Migration, Nebenläufigkeit, Caching oder einen Pfad berührt,
auf dem Nutzerdaten verloren gehen können.

Das ist keine Vorsicht um ihrer selbst willen: am 25.08.2026 fingen drei Coder
auf `high` je einen Fehler, den ein abhakender Durchlauf festgeschrieben hätte,
darunter ein Regressionstest, der gegen genau den kaputten Code grün gewesen
wäre, den er bewachen sollte.

Produktmanager und Koordinator laufen bewusst auf verschiedenen Modellen. Zwei
Rollen auf demselben Modell sind sich einig, bis sie beide falsch liegen.

**Startet der Koordinator auf dem falschen Modell, arbeitet er nicht einfach
weiter und wechselt auch nicht still.** Er bittet Tobias um den Wechsel, bevor
er inhaltlich etwas tut. Eine Sitzung kann ihr eigenes Modell nicht selbst
setzen, das geht nur über `/model`.

Ein Subagent hat keinen Kanal zu Tobias. Fällt ihm auf, dass er auf dem
falschen Modell läuft, meldet er es dem Koordinator und arbeitet nicht
inhaltlich weiter. Sein Modell setzt ohnehin der Koordinator beim Spawn.

Bei Widerspruch zwischen den Regeln eines Projekts (dieser Datei, der
Projekt-CLAUDE.md, den Domain-Docs) und globalen Anweisungen wie
`~/.claude/CLAUDE.md` gewinnt immer die Projektebene, auch bei Rollen- und
Modellzuweisungen. Entschieden am 25.08.2026.

## Aufgaben

`TASKS.md` im Projektwurzelverzeichnis ist der Index: eine Zeile je Aufgabe, nach
Priorität gruppiert, verlinkt auf eine Datei unter `tasks/`. Jede Aufgabendatei
trägt den Befund, die betroffenen Dateien und eine Abnahmeliste.

Aufgaben liegen im Repository, damit sie eine Sitzung, einen Neuaufbau und ein
`git gc` überleben. **Nichts über die laufende Arbeit existiert nur in einer
Nachricht.** Ein Verdikt, eine Messung oder eine Entscheidung, die nur in einem
Gespräch steht, ist weg, sobald diese Sitzung endet.

Eine erledigte Aufgabe wird gelöscht, nicht abgehakt. Die Historie steht im
Git-Log.

**Eine Aufgabe, die eine Ursache an Datei und Zeile nennt und älter als ein paar
Stunden ist, wird nachgemessen, bevor sie gebaut wird.** Aufgabentexte altern
schneller, als sie abgearbeitet werden.

## Gates

Jede Prüfung, die ein Skript sein kann, ist ein Skript unter `scripts/`, und
jedes Skript hängt an einem Hook. Ein Gate, das niemand aufruft, ist Dekoration.

Das Lint-Gate ist **Layer 1 des Reviews** und läuft, bevor ein Coder fertig
meldet: deterministisch, in Sekunden, für null Token, und es fängt, was ein
Modell nur manchmal fängt.

**Nie einen Exit-Code durch eine Pipe prüfen.** Diese Shell ist zsh, dort heißt
das Array `pipestatus`, beginnt bei 1 und überlebt kein Kommando dazwischen.
`${PIPESTATUS[0]}` liefert kommentarlos einen leeren String. Erst umleiten, `$?`
direkt danach lesen, dann die Ausgabe ansehen.

**Ein leeres Ergebnis ist kein Ergebnis.** Ein Werkzeug, das seine Eingabe nicht
versteht, antwortet oft mit null Treffern statt mit einem Fehler. Bevor eine
Null eine Aussage trägt: prüfen, dass der Aufruf lief und traf, was gemeint war.

## Review

Ohne das Verdikt des Reviewers wird nichts committet. Der Reviewer bekommt die
Spezifikation und den `git diff`, sonst nichts. Frischer Kontext ist der Zweck:
wer die Begründung des Autors gelesen hat, erbt seine blinden Flecken.

Ein Verdikt geht in die Aufgabe, nicht nur in eine Nachricht.

**Ein Regressionstest wird gegen die kaputte Fassung gefahren, nicht nur gegen
die reparierte.** Ein Test, der grün bleibt, wenn man den Code kaputtmacht,
belegt nichts, und bei einem Fix gegen Datenverlust ist genau das sein ganzer
Wert.

**Ein grüner Lauf wird mit seinem Umfang gemeldet**: welches Schema, wie viele
Fälle tatsächlich liefen, und welche Suiten nicht. `ok: true` mit null
ausgeführten Fällen sieht aus wie ein bestandener Lauf.

**Die volle Suite fährt nur der Koordinator.** Ein Subagent testet
ausschließlich, was sein Diff berührt, auf Klassenebene. Ein voller Lauf hält
den Build-Slot eine Viertelstunde, und zwei Suiten gleichzeitig färben
Zeittests rot, deren Rot anschließend im Zwischenspeicher klebt: der nächste
Lauf meldet dasselbe Rot in Sekunden, ohne getestet zu haben. Wer die Zahlen
der Vollsuite braucht, bekommt sie vom Koordinator, nachdem der Diff steht.

**Ein sorgfältiger Kommentar kann eine Lücke decken statt sie aufzudecken.** Wo
eine Stelle auffällig ausführlich begründet ist, genauer hinsehen, nicht
flüchtiger.

## Git

Gearbeitet wird auf `main`, in kleinen Schritten, die grün bleiben. Keine
Feature-Branches. Ein Commit braucht zweierlei: grün und das Verdikt des
Reviewers. Es gibt keine Trivialausnahme.

Nach Namen vormerken — `git add <pfad>`, nie `git add -A`, nie `git add .`, nie
`git commit -a`. Vor dem Vormerken `git status --short` lesen.

**Nicht amenden.** `--amend` trifft immer HEAD, und HEAD vorher zu prüfen
schließt das Fenster zwischen Prüfung und Kommando nicht. Ein zweiter Commit
kostet nichts.

Nie ein git-Kommando auf den ganzen Baum richten: `git reset`,
`git checkout -- .`, `git stash` ohne Pfade, `git clean`, `git restore .`. Pfade
nennen, oder es bleiben lassen.

**Nach dem ersten Schreibvorgang in einem neuen Worktree wird `git status
--short` in beiden Bäumen gelesen.** Einem Werkzeug den Wurzelpfad mitzugeben
ist eine Absicht, ein leerer fremder Baum ist ein Beleg. Am 24.08.2026 schrieb
ein Werkzeugaufruf ohne gesetzten Wurzelpfad aus einem Worktree in den
Hauptbaum, in dem gleichzeitig fremde Arbeit offen stand.

**Zur selben Zeit schreibt nur einer.** Lesende Subagenten dürfen beliebig
parallel laufen, schreibende nicht, und auch der Koordinator schreibt nicht,
während ein Subagent es tut. Wer einen Baum misst, in dem ein anderer arbeitet,
bekommt Änderungen ohne Absender und deutet sie falsch. Am 25.08.2026 meldete
ein Subagent zwei verschwundene Dateien als Hinweis auf eine parallele Sitzung,
die es nicht gab; gelöscht hatte sie Tobias. Der Subagent hat richtig gehandelt
und nichts angefasst, aber seine Messung war für den Moment wertlos.

**Committen, sobald es grün und geprüft ist.** Uneingecheckte Arbeit ist das
Einzige in einem Repository, das nichts wiederherstellen kann — nicht der
Reflog, nicht die Objektdatenbank. Hängt ein Verdikt länger als Minuten, ist das
ein Koordinationsproblem und wird gemeldet, nicht ausgesessen.
