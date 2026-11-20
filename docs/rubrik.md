# Rubrik: woran ein Prompt scheitert

Inhalt: K1 Ziel · K2 Kontext · K3 Eingaben · K4 Ausgabe · K5 Vorgehen · K6 Grenzen ·
K7 Wahrheit · K8 Unklarheit · K9 Randfälle · K10 Beispiele · K11 Sprache ·
K12 Einbettung · K13 Prüfbarkeit · K14 Zielmodell · Was nicht (mehr) wirkt

Vierzehn Kriterien. Bewerte nach der Wirkung auf den Agenten, nicht danach, ob es
einen Abschnitt mit passendem Titel gibt: Ein Prompt kann ein Kriterium in einem
Halbsatz erfüllen und mit einem ganzen Abschnitt verfehlen. Die Kürzel in eckigen
Klammern verweisen auf `quellen.md`.

Status je Kriterium: `erfüllt`, `teilweise`, `fehlt`, `entfällt`. `entfällt` ist
eine Antwort, kein Ausweichen: Ein einmaliger Auftrag braucht keine
`description`, ein Brainstorming keine Quellenbindung.

**Ein Befund braucht ein Fehlerszenario.** Ein Prüfer, der Probleme finden soll,
findet immer etwas [claude-code-bp]. Was nicht erklärt, welchen konkreten Fehler
der Agent deshalb macht, ist Geschmack und kommt nicht auf die Liste.

## Welche Kriterien je Art zählen

| Art | zählt immer | zählt oft | entfällt meist |
|---|---|---|---|
| Agenten-Definition | K1–K9, K11, K12, K14 | K10, K13 | – |
| Skill | K1–K9, K11, K12, K14 | K10, K13 | – |
| System-Prompt (API, App) | K1–K9, K11, K14 | K10, K13 | K12 |
| Einmaliger Auftrag | K1–K4, K6–K8, K11 | K5, K9, K10, K14 | K12, K13 |
| Projektregeln (CLAUDE.md) | K2, K6, K11, K14 | K7, K8, K12 | K1, K4, K10, K13 |

## K1 Ziel und Erfolgskriterium

**Prüffrage:** Könnte ein Dritter nur mit dem Prompt ein Ergebnis als bestanden
oder nicht bestanden beurteilen?

- Schwäche: „Fass das gut zusammen“, „prüf die Qualität“, „mach es besser“. Das
  Ziel ist eine Tätigkeit, kein Ergebnis.
- Folge: Der Agent optimiert auf das, was er für gut hält, meist Länge, Glätte und
  Vollständigkeit, und hört auf, wann er will.
- Lösung: Ergebnis statt Tätigkeit, prüfbar („jede Aussage mit Fundstelle“,
  „höchstens fünf Punkte, jeder mit Handlung“). Baustein B10.
- Belege: [yan-eval], [hamel-judge], [underspec-2025], [openai-56]

## K2 Kontext und Warum

**Prüffrage:** Weiß der Agent, wofür das Ergebnis gebraucht wird, und kennt er zu
jeder nicht offensichtlichen Regel den Grund?

- Schwäche: nackte Regeln („Keine Aufzählungen“), Projektbegriffe ohne Erklärung,
  Annahmen, die nur der Autor kennt.
- Folge: Der Agent wendet Regeln zu eng oder zu weit an und kann Fälle, die der
  Prompt nicht nennt, nicht ableiten. Mit Grund verallgemeinert er richtig: „read
  aloud by a text-to-speech engine, so never use ellipses“ wirkt besser als
  „NEVER use ellipses“ [anthropic-bp].
- Probe: der Kollegen-Test. Würde eine neue Kollegin ohne Projektwissen dem Prompt
  folgen können? Genau das prüft die Kaltlesung (`scripts/probelauf.py --lesen`).
- **Rollensätze** sind starke Hebel mit Nebenwirkung: Ein einziger Satz über die
  Zuständigkeit für den Code verschob in Anthropics Tests das Verhalten von unter
  10 auf etwa 75 Prozent der Läufe, bei 70 bis 80 Prozent mehr Ausgabe
  [anthropic-fable52]. Prüf, was eine Rolle auslöst, nicht nur, wie sie klingt.
- Lösung: je Regel ein „weil …“ als Halbsatz; Begriffe beim ersten Auftreten
  erklären; was für den Autor selbstverständlich ist, hinschreiben.
- Belege: [anthropic-bp], [anthropic-fable5], [underspec-2025]

## K3 Eingaben und fremde Inhalte

**Prüffrage:** Weiß der Agent, was er bekommt, wo es steht und welche Teile
Anweisung und welche Material sind?

- Schwäche: Material und Anweisungen gemischt; unklar, ob ein Dateipfad, ein
  Log-Abschnitt oder der Prompt selbst die Eingabe ist; Texte aus fremden Quellen
  (Mails, Webseiten, Tickets) ohne Hinweis, dass sie nur Daten sind.
- Folge: Der Agent sucht an der falschen Stelle, behandelt Beispieltext als
  Auftrag oder folgt Anweisungen, die in einer Eingabe stehen.
- Lösung: Material in benannte Abschnitte oder Tags; lange Dokumente vor die
  Aufgabe; fremde Inhalte ausdrücklich als Daten. Bausteine B6, B16.
- Belege: [anthropic-bp], [openai-spec], [google-ps]

## K4 Ausgabe und Fertig-Kriterium

**Prüffrage:** Weiß der Agent, was er abliefert, in welcher Form, für wen, und
wann er aufhören darf?

- Schwäche: keine Form, keine Länge, kein Empfänger; keine Endmarke, obwohl ein
  Skill auf sie wartet; kein Verhalten bei Teil-Erfolg.
- Folge: Mal Fließtext, mal Tabelle; Vorrede und Zusammenfassung um das
  Eigentliche; der Aufrufer findet das Ergebnis nicht oder wertet halbe Arbeit als
  fertig.
- **Prüfer-Prompts:** „Meld nur schwere Befunde“ oder „sei zurückhaltend“ wird
  wörtlich befolgt, und der Prüfer meldet weniger echte Fehler. Besser: alles
  melden lassen und in einem eigenen Schritt filtern [anthropic-opus5].
- Lösung: Form so genau, wie der Empfänger sie braucht (Mensch: Länge und
  Aufbau; Skript: Schema; Agent: Abschnitt und Marke); was bei Teil-Erfolg
  geliefert wird. Bausteine B10, B11.
- Belege: [anthropic-bp], [openai-5], [ms-sys]

## K5 Vorgehen und Freiheitsgrad

**Prüffrage:** Sind Schritte dort festgelegt, wo die Reihenfolge zählt, und ist
dort Spielraum, wo Urteil gefragt ist?

- Schwäche: alles als starre Schrittliste, auch wo das Modell besser selbst
  urteilt; oder Freiheit bei heiklen, fehleranfälligen Abläufen.
- Folge: Starre Listen brechen bei jedem Fall, den sie nicht vorhersehen; offene
  Anweisungen bei heiklen Abläufen erzeugen jedes Mal einen anderen Weg. Skills,
  die für ältere Modelle geschrieben wurden, sind für neuere oft zu eng und
  verschlechtern das Ergebnis [anthropic-fable5].
- Lösung: niedriger Freiheitsgrad (genaue Schritte, Skript) für fragile Abläufe,
  hoher (Ziel und Kriterien) für Urteilsaufgaben [anthropic-skills]. Bei
  Modellen mit Reasoning das Ziel beschreiben, nicht jeden Schritt („Describe the
  destination rather than prescribing every step“) [openai-56].
- Belege: [anthropic-skills], [anthropic-fable5], [openai-56], [cot-reasoning-2025]

## K6 Grenzen und Scope

**Prüffrage:** Weiß der Agent, was er nicht anfasst, wofür er Freigabe braucht und
was er mit Funden außerhalb seines Auftrags macht?

- Schwäche: keine Grenze („verbessere den Code“); Verbote ohne Alternative;
  breite Freigaberegeln; Grenzen, die nur im Text stehen, obwohl ein Verstoß
  teuer wäre.
- Folge: Der Agent schießt über das Ziel hinaus (zusätzliche Dateien, Features,
  Umbauten) oder bleibt aus Vorsicht stecken. Eine Freigaberegel für „Nachrichten
  an Personen außerhalb dieses Gesprächs“ ließ das Modell etwa die Hälfte seiner
  Routineanfragen zurückhalten [anthropic-fable52].
- Lösung: erlaubten Bereich positiv benennen; Freigabepflicht als konkrete Liste
  von Aktionen, Routineschritte ausdrücklich freigeben; Nebenbefunde melden statt
  beheben. Was nie passieren darf, gehört in eine Werkzeugsperre oder einen Hook:
  CLAUDE.md und Prompts sind Leitlinien, von denen das Modell abweichen darf
  [claude-code-bp], [ms-sys]. Baustein B7.
- Belege: [anthropic-bp], [anthropic-opus5], [anthropic-fable52], [claude-code-bp]

## K7 Wahrheit und Lücken

**Prüffrage:** Weiß der Agent, woher seine Fakten kommen dürfen, und was er tut,
wenn eine Angabe fehlt?

- Schwäche: Der Prompt verlangt Zahlen, Namen, Zitate oder Aussagen über Dateien,
  sagt aber nicht, aus welcher Quelle, und nicht, was bei einer Lücke gilt. Oder er
  setzt nur auf einen Appell („erfinde nichts“).
- Folge: Der Agent füllt Lücken mit Plausiblem. Wer nur Treffer belohnt, erzieht
  zum Raten [kalai-2025]. Ein Appell allein reicht oft nicht [ms-pe].
- Lösung: Quellenbindung mit Mechanik: erlaubte Ausweichantwort, sichtbare
  Lückenmarke, Fundstelle an jeder Aussage, bei langen Quellen erst zitieren, vor
  Aussagen über Dateien diese lesen. Bausteine B1 bis B5.
- Belege: [anthropic-hal], [kalai-2025], [ms-pe], [according-to-2023]

## K8 Unklarheit und Rückfragen

**Prüffrage:** Ist geregelt, ob der Agent nachfragen kann, und was er sonst bei
Unklarheit tut?

- Schwäche: „Frag nach, wenn etwas unklar ist“ in einem Subagenten. Subagenten
  steht das Werkzeug für Rückfragen an den Nutzer gar nicht zur Verfügung
  [claude-code-subagents]. Oder: gar keine Regel, oder Rückfragen zu allem.
- Folge: Der Subagent rät still oder beendet seinen Lauf mit einer Frage, die
  niemand liest. Die Hauptsession fragt zu viel oder zu wenig.
- Lösung: Hauptsession: nur fragen, wenn verschiedene Lesarten zu wesentlich
  anderer Arbeit führen, sonst Annahme treffen und nennen [anthropic-opus5].
  Subagent: Annahme markieren, `FRAGLICH` melden oder mit Status abbrechen.
  Bausteine B8, B9.
- Belege: [anthropic-opus5], [openai-55], [claude-code-subagents], [clarify-2018]

## K9 Randfälle

**Prüffrage:** Was tut der Agent bei leerer, widersprüchlicher, übergroßer oder
fachfremder Eingabe?

- Schwäche: Der Prompt beschreibt nur den Normalfall.
- Folge: Bei der ersten ungewöhnlichen Eingabe improvisiert der Agent, oft mit
  einem überzeugend aussehenden, falschen Ergebnis.
- Lösung: die zwei, drei wahrscheinlichsten Randfälle mit gewünschtem Verhalten
  nennen. Nicht alle denkbaren: Jede Regel kostet Aufmerksamkeit, und lange
  Listen von Grenzfällen schaden eher [anthropic-bp].
- Belege: [hamel-field-guide], [underspec-2025], [anthropic-bp]

## K10 Beispiele

**Prüffrage:** Zeigen die Beispiele, was gewollt ist, ohne dass der Agent sie
abschreibt?

- Schwäche: ein einziges Beispiel, das der Agent nachbaut; Beispiele, die alle
  denselben Fall zeigen oder anders formatiert sind als verlangt; Beispiele, die
  einer Regel im Text widersprechen.
- Folge: Ergebnisse gleichen dem Beispiel in Länge, Aufbau und Wortlaut; Fälle,
  die das Beispiel nicht zeigt, gehen schief. Format, Auswahl und Reihenfolge von
  Beispielen verschieben Ergebnisse stark [weng-pe], [format-sensitivity-2023].
- Lösung: drei bis fünf unterschiedliche Beispiele im selben Format, als solche
  markiert, mit dem Hinweis, was sie zeigen. Baustein B15.
- Belege: [anthropic-bp], [google-ps], [openai-41]

## K11 Sprache und Ton

**Prüffrage:** Gibt es Widersprüche, wechselnde Begriffe, vage Maße,
Überbetonung oder Ballast?

Prüfe einzeln:

- **Widersprüche:** Zwei Regeln, die im Randfall kollidieren, oder dieselbe Regel
  an zwei Stellen verschieden, auch über Dateien hinweg (Skill und Agent, CLAUDE.md
  und Memory). Modelle mit Reasoning verbrauchen Denkaufwand darauf, sie zu
  versöhnen; Claude nimmt mitunter eine beliebige. Lösung: Eine Regel gewinnt, und
  das steht da. [openai-5], [openai-56], [claude-code-memory]
- **Begriffe:** Ein Ding, ein Wort, durchgehend. Vage Maße („kurz“, „angemessen“,
  „wichtig“) durch Zahlen oder Kriterien ersetzen. [anthropic-skills]
- **Verbote ohne Alternative:** „Kein Markdown“ statt „Fließtext in Absätzen“.
  Verneinte Anweisungen werden messbar schlechter befolgt, und ein verbotenes Wort
  zu nennen kann es erst auslösen. Lösung: sagen, was stattdessen gilt; harte
  Verbote behalten, aber um die Alternative ergänzen. [anthropic-bp],
  [negation-2026], [negation-prime-2026]
- **Überbetonung:** GROSSBUCHSTABEN, „CRITICAL“, „du MUSST“, gestapelte
  „NIEMALS“. Aktuelle Modelle befolgen eine schlicht formulierte Zeile, und
  Betonung lässt sie die Regel überdehnen [claude-code-bp]. Ein „nie“ nimmt das
  Modell absolut [anthropic-fable52]. Lösung: ruhige Anweisung mit Grund und
  Ausnahme. Baustein B14.
- **Ballast:** siehe „Was nicht (mehr) wirkt“ unten.

## K12 Einbettung (Agent, Skill, CLAUDE.md)

**Prüffrage:** Passt der Prompt zu seiner Umgebung: Auslöser, Werkzeuge,
Aufrufer, Verweise?

- **description:** sagt, was der Agent oder Skill tut und wann er dran ist, in
  dritter Person, mit konkreten Auslösern, den wichtigsten Anlass zuerst.
  Höchstens 1.024 Zeichen [anthropic-skills]; in Claude Code werden
  `description` und `when_to_use` zusammen bei 1.536 Zeichen abgeschnitten
  [claude-code-skills]. Bei Subagenten fördert „use proactively“ das Delegieren
  [claude-code-subagents].
- **Für sich verständlich:** Ein Subagent bekommt nur seinen eigenen Prompt plus
  Umgebungsangaben, nicht den System-Prompt von Claude Code
  [claude-code-subagents]. Was er wissen muss, steht in seiner Datei oder im
  Auftrag.
- **Werkzeuge und Modell:** nur die Werkzeuge, die der Auftrag braucht; was nie
  passieren darf, als `disallowedTools` oder Hook; `maxTurns`, wo ein Abbruch
  sinnvoll ist.
- **Vertrag mit dem Aufrufer:** Format, Abschnitt und Endmarke stimmen mit dem
  überein, was der aufrufende Skill erwartet. Lies den Aufrufer.
- **Verweise:** Jeder Pfad, Befehl, Agent und Skill, den der Prompt nennt,
  existiert. Prüf das mit Glob und Grep, statt es anzunehmen.
- **Aufbau (Skill):** `SKILL.md` unter 500 Zeilen, Details in verlinkten Dateien
  eine Ebene tief; nichts, was das Modell ohnehin weiß [anthropic-skills]. Jede
  Zeile kostet in jeder weiteren Runde, darum sagen, was zu tun ist, statt zu
  erzählen [claude-code-skills].

## K13 Prüfbarkeit

**Prüffrage:** Lässt sich mit drei Testeingaben zeigen, ob der Prompt wirkt?

- Schwäche: keine Testfälle, kein Erfolgskriterium (K1), kein Anlass bekannt.
- Folge: Jede Änderung ist Geschmack; Verbesserungen an einer Stelle zerstören
  unbemerkt eine andere.
- Lösung: Anlass, typischer Fall, Randfall und Lücken-Falle als Testfälle;
  vorher und nachher als echte Probeläufe ausführen und von einem Prüfer mit
  frischem Kontext auswerten lassen, der schlägt Selbstkritik [anthropic-fable5].
  Weichen zwei Läufe derselben Eingabe ab, ist der Prompt dort unterbestimmt
  [selfcheck-2023], [anthropic-hal]. Fehleranalyse an echten Läufen schlägt jede
  Checkliste [hamel-field-guide].
- Belege: [anthropic-skills], [hamel-evals], [hamel-field-guide], [anthropic-fable5]

## K14 Passung zum Zielmodell

**Prüffrage:** Ist der Prompt für das Modell geschrieben, auf dem er läuft?

- Schwäche: Regeln aus früheren Modellgenerationen, die heute schaden (Tabelle
  unten); Techniken, die für ein anderes Modell gemessen wurden.
- Folge: Überreaktion, Mehrarbeit, Abbrüche oder Ablehnung. Bitten, das eigene
  Reasoning in die Antwort zu schreiben, können neuere Claude-Modelle ablehnen
  [anthropic-opus5].
- Lösung: Steht das Zielmodell fest, lies dessen Prompting-Seite beim Anbieter
  (Claude: `platform.claude.com/docs/en/build-with-claude/prompt-engineering/`,
  Seiten `prompting-claude-<modell>`). Anthropic: Eine Technik, die ein Modell
  nennt, gilt als an diesem Modell gemessen [anthropic-bp]. Vorsichtsregeln, deren
  Grund nicht mehr gilt, streichen; absolute Regeln mit Geltungsbereich und Grund
  neu schreiben [anthropic-fable52].
- Belege: [anthropic-bp], [anthropic-opus5], [anthropic-fable5], [anthropic-fable52], [openai-r]

## Was nicht (mehr) wirkt

Findest du eines davon, ist es ein Befund unter K11 oder K14. Die Stufe ist meist
`feinschliff`. Wenn es Überreaktion, Mehrarbeit oder Ablehnung auslöst, ist sie
`riskant`.

| Kunstgriff | Stand der Belege | Stattdessen |
|---|---|---|
| Trinkgeld, Drohung („sonst wirst du abgeschaltet“) | kein signifikanter Effekt auf Benchmarks [tip-threat-2025] | Ziel und Erfolgskriterium klar machen |
| „Du bist ein Weltklasse-Experte“ für Faktentreue | verbessert die Genauigkeit nicht, Laien-Personas senken sie oft [persona-2023], [persona-2025] | Rolle nur für Ton und Blickwinkel; Fakten über Quellenbindung (B1) |
| GROSSBUCHSTABEN, IMPORTANT, „CRITICAL: You MUST“ | führt bei aktuellen Modellen zum Überdehnen der Regel [claude-code-bp], [anthropic-bp] | ruhige Anweisung mit Grund (B14); was nie passieren darf, als Hook |
| „Denk gründlich“, „think hard“, „be thorough“ | Effort ist der Regler; solche Sätze sind normaler Text [claude-code-bp] | Effort einstellen; bei Reasoning-Modellen kein Denk-Schema [openai-r], [cot-reasoning-2025] |
| „Mach weiter, bis alles fertig ist, sei nicht faul“ | führt eher zu Mehrarbeit als dass es Abbrüche behebt [claude-code-bp] | eine Prüfung, die bestanden werden muss (B10) |
| „Im Zweifel nutze [Werkzeug]“ | löst Overtriggering aus [anthropic-bp] | Wenn-dann-Regel, wann das Werkzeug passt |
| „Prüf deine Antwort noch einmal“ ohne Maßstab | Selbstkorrektur ohne äußeres Feedback hilft kaum [selfcorrect-2023]; auf Claude Opus 5 Übermaß an Prüfen [anthropic-opus5] | Prüfung gegen benannte Kriterien (B12) oder frischer Prüfer |
| Reasoning in die Antwort schreiben lassen | kann bei neueren Claude-Modellen abgelehnt werden [anthropic-opus5] | kurze Begründung des Ergebnisses verlangen |
| Prefill (Antwort des Assistenten vorgeben) | ab Claude 4.6 mit 400-Fehler abgelehnt [anthropic-bp] | direkte Anweisung, strukturierte Ausgabe |
| Nur Verbote | schlechter befolgt als die positive Form [negation-2026] | sagen, was stattdessen gilt |
| Architektur und Dateibaum in CLAUDE.md | Claude liest das Repo selbst [claude-code-bp] | nur aufschreiben, was nicht im Repo steht |
| Lange Regelkataloge „zur Sicherheit“ | alles aufzuzählen hilft nicht verlässlich, Regeln kollidieren [underspec-2025] | die Regeln, die ein Testfall braucht; der Rest fliegt raus |
