#!/usr/bin/env python3
"""Führt einen Prompt mit einer Testeingabe in einer frischen Claude-Session aus,
oder lässt ihn dort kalt lesen.

Der Probelauf zeigt, was ein Agent mit genau diesem Prompt tut. Ein Tester, der
den Prompt nur nachspielt, weiß, dass er geprüft wird, und arbeitet vorsichtiger
als der echte Agent. Hier gibt es keinen Tester: Der Prompt ist die Anweisung.

Aufruf:
  probelauf.py PROMPT EINGABE [--als system|auftrag] [--modell MODELL]
               [--aus DATEI] [--timeout SEKUNDEN]
  probelauf.py --lesen PROMPT [--modell MODELL] [--timeout SEKUNDEN]

  PROMPT    Datei mit dem Prompt. Ein Frontmatter (--- … ---) wird entfernt.
  EINGABE   Datei mit der Testeingabe: genau die erste Nachricht, die der Agent
            bekommt. Nennt sie Dateien, darf der Lauf den Ordner der Eingabe lesen.
  --als     system (Standard): Der Prompt ist der System-Prompt, die Eingabe die
            erste Nachricht. So laufen Agenten-Definitionen und System-Prompts.
            auftrag: Prompt und Eingabe bilden zusammen die erste Nachricht. Steht
            $ARGUMENTS im Prompt, tritt die Eingabe an diese Stelle. So laufen
            Skills und einmalige Aufträge.
  --modell  Modell der Session (Standard: sonnet).
  --aus     Schreibt das Ergebnis zusätzlich in diese Datei.
  --lesen   Kaltlesung: Eine frische Session liest nur PROMPT, mit der Anweisung
            aus docs/kaltleser.md, und berichtet, wo sie raten müsste. Sie sieht
            weder Plan noch Log noch Auftrag.

Abschottung: --safe-mode (keine CLAUDE.md, Plugins, Hooks, MCP-Server, eigenen
Agenten), nur die Werkzeuge Read, Glob und Grep, kein Auto-Memory, keine
gespeicherte Session. Der Lauf kann lesen, aber nichts schreiben, ausführen oder
verschicken. Er läuft im aktuellen Ordner, damit Verweise auf Projektdateien so
auflösen wie beim echten Agenten.

Exit-Code 0 bei Erfolg, 2 bei falschem Aufruf, sonst der Code von claude.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

WERKZEUGE = "Read,Glob,Grep"


def ohne_frontmatter(text: str) -> str:
    m = re.match(r"^---\n.*?\n---\n", text, re.S)
    return text[m.end():] if m else text


def main() -> int:
    ap = argparse.ArgumentParser(description="Probelauf eines Prompts in einer abgeschotteten Claude-Session.")
    ap.add_argument("prompt")
    ap.add_argument("eingabe", nargs="?")
    ap.add_argument("--lesen", action="store_true")
    ap.add_argument("--als", choices=["system", "auftrag"], default="system")
    ap.add_argument("--modell", default="sonnet")
    ap.add_argument("--aus")
    ap.add_argument("--timeout", type=int, default=900)
    args = ap.parse_args()

    claude = shutil.which("claude")
    if not claude:
        print("FEHLER: Der Befehl claude ist nicht im PATH.", file=sys.stderr)
        return 2
    if args.lesen:
        kaltleser = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "kaltleser.md")
        args.eingabe = None
    elif not args.eingabe:
        print("FEHLER: EINGABE fehlt (oder --lesen für eine Kaltlesung).", file=sys.stderr)
        return 2
    for pfad in [p for p in (args.prompt, args.eingabe) if p] + ([kaltleser] if args.lesen else []):
        if not os.path.isfile(pfad):
            print(f"FEHLER: Datei fehlt: {pfad}", file=sys.stderr)
            return 2

    if args.lesen:
        with open(kaltleser, encoding="utf-8") as f:
            prompt = f.read().strip()
        eingabe = f"Lies den Prompt in {os.path.abspath(args.prompt)} und antworte nach deiner Anweisung."
        args.als = "system"
        lesbar = os.path.dirname(os.path.abspath(args.prompt))
    else:
        with open(args.prompt, encoding="utf-8") as f:
            prompt = ohne_frontmatter(f.read()).strip()
        with open(args.eingabe, encoding="utf-8") as f:
            eingabe = f.read().strip()
        lesbar = os.path.dirname(os.path.abspath(args.eingabe))

    cmd = [
        claude, "-p",
        "--safe-mode",
        "--model", args.modell,
        "--tools", WERKZEUGE,
        "--strict-mcp-config",
        "--no-session-persistence",
        "--permission-mode", "default",
        "--add-dir", lesbar,
    ]
    umgebung = dict(os.environ, CLAUDE_CODE_DISABLE_AUTO_MEMORY="1")

    systemdatei = None
    try:
        if args.als == "system":
            with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8") as f:
                f.write(prompt)
                systemdatei = f.name
            cmd += ["--system-prompt-file", systemdatei]
            nachricht = eingabe
        elif "$ARGUMENTS" in prompt:
            nachricht = prompt.replace("$ARGUMENTS", eingabe)
        else:
            nachricht = f"{prompt}\n\n{eingabe}"

        try:
            lauf = subprocess.run(cmd, input=nachricht, capture_output=True, text=True,
                                  timeout=args.timeout, env=umgebung)
        except subprocess.TimeoutExpired:
            print(f"FEHLER: Probelauf nach {args.timeout} s abgebrochen.", file=sys.stderr)
            return 124
    finally:
        if systemdatei:
            os.unlink(systemdatei)

    if args.aus:
        with open(args.aus, "w", encoding="utf-8") as f:
            f.write(lauf.stdout)
    sys.stdout.write(lauf.stdout)
    if lauf.returncode != 0:
        sys.stderr.write(lauf.stderr)
    return lauf.returncode


if __name__ == "__main__":
    sys.exit(main())
