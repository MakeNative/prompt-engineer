# prompt-engineer

Ein Agent tut nicht, was du meinst, sondern was im Prompt steht. Diese Agenten-Pipeline
nimmt sich einen Prompt, eine Agenten-Definition, einen Skill oder eine CLAUDE.md vor
wie ein Prompt Engineer: Sie prüft ihn, klärt mit dir, was der Agent genau tun soll,
schreibt ihn erst dann neu und zeigt mit echten Probeläufen vorher und nachher, dass
die neue Fassung wirkt.

Gebaut mit dem pipeline-builder von MakeNative (`/pipeline-builder:plan` → `scaffold`). Die Entscheidungen stehen in
[`docs/PIPELINE-PLAN.md`](docs/PIPELINE-PLAN.md).

## Installation

```
/plugin marketplace add MakeNative/prompt-engineer
/plugin install prompt-engineer@prompt-engineer
```

Aus einem Klon ohne Installation: `claude --plugin-dir <pfad-zum-klon>`.

Voraussetzungen: `jq` und `perl` für die Hooks, `python3` und `claude` im PATH für die
Probeläufe.

## Benutzen

```
/prompt-engineer:adopt                      # einmal je Projekt
/prompt-engineer:orchestrate .claude/agents/reviewer.md — er meldet Stil statt Fehler
/prompt-engineer:orchestrate "Fass die Notizen zusammen und liste alle To-dos mit Deadline."
```

Hinter dem Pfad oder Text steht am besten der Anlass, also was der Agent heute falsch
macht. Er wird Testfall Nummer eins.

## Ausprobieren

`examples/meeting-summarizer/` ist ein kleines Projekt mit einem absichtlich schwachen
Agenten: „IMMER vollständig“, „frag nach, wenn etwas unklar ist“, eine Persona, kein
Ausgabeformat. Dazu kommen Meetingnotizen mit einer Lücke und einer eingeschleusten
Anweisung.

```
cd <pfad-zum-klon>/examples/meeting-summarizer
claude
/prompt-engineer:orchestrate .claude/agents/meeting-summarizer.md — Er trägt Deadlines ein, die nicht in den Notizen stehen. Echte Eingabe: notizen.md
```

Der Lauf dauert etwa 20 Minuten und fragt dich zweimal: nach den Befunden und vor dem
Schreiben, wenn du die Absicht freigibst. Danach zeigt `git diff`, was sich am Agenten
geändert hat, und `git restore .claude/agents/meeting-summarizer.md` setzt das Beispiel
zurück.

## Ablauf

| Phase | Agent | Was er tut |
|---|---|---|
| PLAN | `prompt-diagnostician` | prüft Prompt und Umfeld nach der Rubrik (K1–K14), lässt ihn in einer frischen Session kalt lesen, schreibt Befunde mit Fehlerszenario |
| PLAN | `intent-planner` | legt mit dir Absicht, Erfolgskriterium, Grenzen und Testfälle fest; fragt nur, was den Prompt ändert |
| BUILD | `test-case-writer` | schreibt die Testeingaben, darunter eine Lücken-Falle und eine eingeschleuste Anweisung, und sichert die Ausgangsfassung |
| BUILD | `prompt-writer` | schreibt die geschärfte Fassung in die Datei: kleinste wirksame Änderung, Schutzbausteine nur gegen echte Risiken |
| REVIEW | `probe-reviewer` | führt alte und neue Fassung echt aus und meldet Erfundenes, Eingeschleustes und verfehlte Kriterien |
| REVIEW | `prompt-reviewer` | lässt die neue Fassung kalt lesen und prüft Rubrik, Streichbares und Verweise |

`run-setup` öffnet jeden Lauf, `run-summary` schließt ihn mit dem Bericht. Findet ein
Reviewer etwas, läuft eine weitere BUILD → REVIEW-Runde, höchstens zwei. Danach
entscheidest du.

## Echte Probeläufe

`scripts/probelauf.py` startet für jeden Testfall eine frische Claude-Session mit
`--safe-mode` (keine CLAUDE.md, Plugins, Hooks oder MCP-Server) und nur den
Werkzeugen `Read`, `Glob` und `Grep`. Der Prompt ist dort die echte Anweisung: einen
Agenten bekommt die Session als System-Prompt, einen Skill als Auftrag. Mit `--lesen`
liest eine solche Session den Prompt kalt, ohne Plan, Log oder Auftrag zu kennen.

Warum echt: Ein Tester, der den Prompt nur nachspielt, weiß, dass er geprüft wird. Beim
Bau dieser Pipeline übernahm der Meeting-Agent aus `examples/` eine in den Notizen
eingeschleuste Deadline in zwei von zwei echten Läufen, wenn die Notizen als Text in der
Nachricht standen. Der nachgespielte Lauf desselben Prompts übernahm sie nicht. Auch die
Form der Eingabe zählt: Kamen die Notizen als Dateipfad, folgte er ihr nicht. Die
Testfälle bilden deshalb nach, wie der echte Aufrufer schickt.

## Zugriffe

| Agent | darf schreiben | Befehle | Web |
|---|---|---|---|
| `prompt-diagnostician` | nur Plan-Abschnitt, Log, Memory | nur `probelauf.py --lesen` | `WebFetch` (Prompting-Seiten der Anbieter) |
| `intent-planner` | nur Plan-Abschnitt, Log, Memory | – | – |
| `test-case-writer` | `.claude/prompt-engineer/<lauf>/tests/` und `baseline/` | – | – |
| `prompt-writer` | die Prompt-Datei aus dem Plan, nicht Tests und Ausgangsfassung | – | – |
| `probe-reviewer` | nur Log, Memory | nur `probelauf.py` | – |
| `prompt-reviewer` | nur Log, Memory | nur `probelauf.py --lesen` | – |

Niemand committet oder pusht; das blockt der Hook. Zwei Lücken sind echt:

- Drei Agenten lesen nur, dürfen aber Befehle ausführen. Über die Shell könnten sie am
  Hook vorbei schreiben. Die Grenze „nur das Probelauf-Skript“ steht nur in ihrem Text.
- Der Hook regelt, *wohin* geschrieben wird, `tools:` im Frontmatter, *ob* überhaupt.
  Fehlt eines davon, wird das andere schwächer.

Der `prompt-writer` schreibt nach deiner Freigabe des Plans direkt in die Prompt-Datei.
Der Rückweg führt über git oder über die Ausgangsfassung unter `baseline/`.

<!-- VERIFY --> Die geschützten Pfade in `pipeline-policy.json`
(`/\.claude/prompt-engineer/[^/]+/(tests|baseline)/`) sind eine Annahme, bis sie in
einem echten Projekt bestätigt sind.

## Der Plan

Die PLAN-Agenten schreiben `plan.md` im Run-Ordner, je einen Abschnitt. Er ist der
Vertrag für jeden BUILD- und REVIEW-Agenten, und keiner von ihnen kann ihn ändern.

## Run-Log

Jeder Lauf hat `log.md` in seinem Run-Ordner `.claude/runs/prompt-engineer/<datum>-<slug>/`.
Jeder Agent hängt bei jedem Ende seines Zugs einen Eintrag an, jede Frage an dich und
deine Antwort eingeschlossen. `log.md` und `plan.md` schreibt ein Hook unter einer
Sperre, damit parallele Agenten sich nicht überschreiben; er braucht `jq` und `perl`.

## Auswertung

- `/prompt-engineer:evaluate-pipeline` prüft die Pipeline gegen `docs/FRAMEWORK.md`,
  `docs/PIPELINE-DESIGN.md` und `docs/PIPELINE-PLAN.md` und zeigt die Befunde nach
  Priorität. Sie ändert nichts.
- `/prompt-engineer:evaluate-runs` wertet fertige Läufe aus: ein Faktenblatt je Lauf,
  eine Prüfung der Texte und des Agenten-Memorys, höchstens acht Vorschläge mit
  erwarteter Zahl. Eingebaut wird nur, was du ankreuzt, protokolliert in
  `.claude/evals/prompt-engineer/EVAL-CHANGELOG.md`. Sie committet nie und braucht `jq`.
- Eval: `claude plugin eval <pfad-zum-klon> --allow-tools Write Edit Bash --no-publish`.
  Ohne `--no-publish` wird der Bericht veröffentlicht.

## Projektkontext

`/prompt-engineer:adopt` einmal je Projekt schreibt `.claude/docs/PROJECT_CONTEXT.md`.
Jeder Agent liest es vor dem Start, und `adopt` prüft, ob die Pfade und Befehle der
Agenten im Projekt existieren. Was ein Agent über das Projekt lernt, hält er in seinem
eigenen Memory fest; `evaluate-runs` schlägt vor, was mehrere brauchen, in den
Projektkontext zu ziehen.

## Zeitmessung

In jedem Run-Ordner entsteht `timings.jsonl`. `run-summary` macht daraus die Tabelle
im Abschlussbericht; die Modellzeit ist Gesamtzeit minus Werkzeugzeit.

## Wissen

Die Rubrik (`docs/rubrik.md`), die Schutzbausteine (`docs/bausteine.md`) und ihre
Belege (`docs/quellen.md`) stammen aus der Doku von Anthropic, OpenAI, Google und
Microsoft und aus Studien bis Oktober 2026, mit wörtlichen Zitaten. Dazu gehört auch,
was nicht (mehr) wirkt: Trinkgeld und Drohungen, Experten-Personas für Faktentreue,
Großbuchstaben, „denk gründlich“.

## MakeNative

Dieses Plugin ist Teil von [MakeNative](https://makenative.de). Wir arbeiten jeden Tag mit
Agenten-Pipelines und bringen anderen bei, sie für ihre eigenen Prozesse zu
bauen. Für Entwickler genauso wie für alle, die ihre Arbeit mit KI automatisieren wollen.

Du willst das für deine Arbeit lernen? Trag dich in die Liste ein:
[Bewerbung Starter-Kohorte](https://tally.so/r/5ByYj6?utm_source=github&utm_medium=readme&utm_campaign=starter-kohorte)

Christian Eichmüller · [LinkedIn](https://linkedin.com/in/christianeichmueller)

## Lizenz

MIT
