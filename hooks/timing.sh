#!/usr/bin/env bash
# prompt-engineer timing probe.
#
# Records where a run's time goes, one JSONL line per event, into the run
# directory the workflow created. Agents are unaware of it — they are measured,
# not instrumented.
#
# This must never break a run: it exits 0 on every path, including failure.
set -uo pipefail

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

logroot="${CLAUDE_PROJECT_DIR:-.}/.claude/runs/prompt-engineer"
[[ -d "$logroot" ]] || exit 0

# Only this pipeline's own run agents are measured. The main session, other
# plugins' agents and the evaluation agents keep working in the same project
# long after a run has ended, and would otherwise land in its timings.
agent=$(jq -r '.agent_type // ""' <<<"$input" 2>/dev/null) || exit 0
[[ -n "$agent" ]] || exit 0
case "${agent##*:}" in
  run-evaluator|pipeline-evaluator|prompt-auditor) exit 0 ;;
esac
if [[ "$agent" != prompt-engineer:* ]]; then
  # A project-local override carries the plain name. It counts only if the
  # policy knows that name.
  [[ "$agent" == *:* ]] && exit 0
  policy="${CLAUDE_PROJECT_DIR:-.}/pipeline-policy.json"
  [[ -f "$policy" ]] || policy="${CLAUDE_PLUGIN_ROOT:-}/pipeline-policy.json"
  jq -e --arg a "$agent" '.agents[$a]' "$policy" >/dev/null 2>&1 || exit 0
fi

# Newest run directory. The workflow creates exactly one per run.
run=$(ls -1dt "$logroot"/*/ 2>/dev/null | head -1)
[[ -n "${run:-}" ]] || exit 0

# Millisecond clock. Only SubagentStart/Stop need it — tool durations come from
# the payload's own duration_ms, which is more accurate than anything we measure.
ts=$(perl -MTime::HiRes=time -e 'printf "%.0f", time*1000' 2>/dev/null) || ts=$(date +%s)000

jq -c --arg ts "$ts" '{
  ts:        ($ts | tonumber),
  event:     .hook_event_name,
  agent:     (.agent_type // "main"),
  agent_id:  .agent_id,
  tool:      .tool_name,
  duration_ms: .duration_ms,
  command:   (.tool_input.command // null),
  file:      (.tool_input.file_path // null)
}' <<<"$input" >> "${run}timings.jsonl" 2>/dev/null

exit 0
