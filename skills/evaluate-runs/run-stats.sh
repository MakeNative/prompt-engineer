#!/usr/bin/env bash
# prompt-engineer run stats.
#
# Numbers for one finished run, read from the Claude Code transcripts of its
# agents: a header, one tab-separated row per agent start, then summary lines
# that start with "#". It counts and never judges; the evaluation agents judge.
#
# An agent belongs to the run when its first prompt names the run folder, the
# way the orchestrator passes it. The evaluation agents of this pipeline are
# left out: they read a run, they are not part of it.
#
# Usage: run-stats.sh <run folder>
# CLAUDE_PROJECTS_DIR replaces ~/.claude/projects, for tests.
set -o pipefail
command -v jq >/dev/null || { echo "run-stats: jq is missing" >&2; exit 1; }
[ -f "${1%/}/log.md" ] || { echo "run-stats: ${1:-<run folder>} has no log.md" >&2; exit 1; }

run=$(cd "$1" && pwd)
name=$(basename "$run")
projects=${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}
evaluators='^(run-evaluator|pipeline-evaluator|prompt-auditor)$'

# Agents of a run in a worktree may be started from the main checkout's
# session, so the search starts at the main repository and takes its worktrees
# along.
common=$(git -C "$run" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
if [ -n "$common" ]; then root=${common%/.git}; else root=${run%/.claude/runs/*}; fi
slug=$(printf '%s' "$root" | sed 's/[^A-Za-z0-9]/-/g')

# The folder name followed by anything but a name character, so that
# 2026-10-01-draft does not also match 2026-10-01-draft-2.
mark="runs/prompt-engineer/$(printf '%s' "$name" | sed 's/[.[\*^$]/\\&/g')([^A-Za-z0-9_-]|$)"

per_agent='
  def epoch: sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601;
  . as $all
  | [.[] | select(.type == "user" or .type == "assistant")] as $e
  | ([$e[] | .timestamp | epoch] | sort) as $t
  | [range(1; $t | length) as $i | [$t[$i - 1], $t[$i]] | select(.[1] - .[0] <= 1200)] as $spans
  | ([$e[] | select(.type == "assistant" and .message.usage) | {id: .message.id, u: .message.usage}]
     | group_by(.id) | map(.[-1].u)) as $u
  | {agent: $agent, name: $name, id: $id, first: $t[0], last: $t[-1], spans: $spans,
     active: (($spans | map(.[1] - .[0]) | add // 0) / 6 | floor / 10),
     tasks: (([$e[] | select(.type == "user" and (.isMeta | not)) | .message.content
               | select(type == "string" or any(.[]; .type == "text"))] | length)
             + ([$all[] | (select(.type == "user" and .isMeta == true) | .message.content
                           | if type == "string" then . else (.[0].text // "") end
                           | select(startswith("The coordinator sent a message"))
                           | sub("^The coordinator sent a message[^\n]*\n"; "")),
                          (select(.type == "attachment" and .attachment.type == "queued_command"
                                  and .attachment.origin.kind == "coordinator") | .attachment.prompt | tostring)
                 | .[0:200]] | unique | length)),
     model: ([$e[] | select(.type == "assistant") | .message.model // empty
              | select(. != "<synthetic>")] | unique | join(" ")),
     version: ([$e[] | .version // empty] | unique | join(" ")),
     input: ($u | map(.input_tokens // 0) | add // 0),
     cache_write: ($u | map(.cache_creation_input_tokens // 0) | add // 0),
     cache_read: ($u | map(.cache_read_input_tokens // 0) | add // 0),
     output: ($u | map(.output_tokens // 0) | add // 0),
     tool_calls: ([$e[] | select(.type == "assistant") | .message.content[]?
                   | select(type == "object" and .type == "tool_use") | .id] | unique | length),
     tool_errors: ([$e[] | select(.type == "user") | .message.content[]?
                    | select(type == "object" and .type == "tool_result" and .is_error == true)
                    | .tool_use_id] | unique | length)}'

summary='
  def utc: strftime("%Y-%m-%dT%H:%M:%SZ");
  def min: . / 6 | floor / 10;
  sort_by(.first) as $a
  | ([$a[] | .spans[]] | sort
     | reduce .[] as $s ([]; if length > 0 and $s[0] <= .[-1][1]
                             then .[-1][1] = ([.[-1][1], $s[1]] | max) else . + [$s] end)
     | map(.[1] - .[0]) | add // 0) as $busy
  | (if ($a | length) > 0 then ($a | map(.last) | max) - $a[0].first else 0 end) as $span
  | ([$a[] | .agent] | group_by(.) | map(select(length > 1) | "\(.[0]) \(length)") | join(", ")) as $twice
  | "agent\tagent_id\tfirst\tlast\tactive_min\ttasks\tmodel\tversion\tinput\tcache_write\tcache_read\toutput\ttool_calls\ttool_errors\tname",
    ($a[] | [.agent, .id, (.first | utc), (.last | utc), .active, .tasks, .model, .version,
             .input, .cache_write, .cache_read, .output, .tool_calls, .tool_errors, .name] | map(tostring) | join("\t")),
    "# run\t\($name)",
    "# agent_starts\t\($a | length)",
    "# started_twice\t\(if $twice == "" then "none" else $twice end)\tthe same agent started again instead of continued",
    "# agent_span_min\t\($span | min)\tfirst agent start to last agent entry",
    "# agent_busy_min\t\($busy | min)\tat least one agent working; pauses over 20 min inside an agent not counted",
    "# no_agent_min\t\(($span - $busy) | min)\tno agent working: orchestrating, waiting for the author, or idle",
    "# tokens\tinput \($a | map(.input) | add // 0)\tcache_write \($a | map(.cache_write) | add // 0)\tcache_read \($a | map(.cache_read) | add // 0)\toutput \($a | map(.output) | add // 0)",
    "# models\t\([$a[] | .model | split(" ")[]] | unique | join(" "))",
    "# versions\t\([$a[] | .version | split(" ")[]] | unique | join(" "))"'

for f in "$projects/$slug"*/*/subagents/agent-*.jsonl; do
  [ -f "$f" ] || continue
  # An agent started under a name of its own carries that name as agentType;
  # its type from this plugin is then in spawnedAgentType.
  agent=$(jq -r '.spawnedAgentType // .customAgentType // .agentType // "-"' "${f%.jsonl}.meta.json" 2>/dev/null) || agent=-
  # run-setup is started before the folder exists, so only its writes name it.
  if [ "${agent##*:}" = run-setup ]; then
    grep -qE "$mark" "$f" || continue
  else
    head -c 8000 "$f" | grep -qE "$mark" || continue
  fi
  grep -qE "$evaluators" <<<"${agent##*:}" && continue
  label=$(jq -r 'if .agentType and .agentType != (.spawnedAgentType // .customAgentType // .agentType) then .agentType else "-" end' "${f%.jsonl}.meta.json" 2>/dev/null) || label=-
  id=$(basename "$f" .jsonl)
  jq -sc --arg agent "$agent" --arg name "$label" --arg id "${id#agent-}" "$per_agent" "$f"
done | jq -rs --arg name "$name" "$summary"

# Wall time from the log itself: the hook stamps every entry with a real UTC time.
times=$(grep -oE '^_[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' "$run/log.md" | tr -d _ | sort | sed -n '1p;$p')
first=$(head -1 <<<"$times"); last=$(tail -1 <<<"$times")
if [ -n "$first" ]; then
  wall=$(jq -rn --arg a "$first" --arg b "$last" '(($b | fromdateiso8601) - ($a | fromdateiso8601)) / 6 | floor / 10')
  printf '# log_wall_min\t%s\t%s to %s, from the log entries\n' "$wall" "$first" "$last"
else
  printf '# log_wall_min\tunknown\tno stamped entry in log.md\n'
fi
entries=$(grep -cE '^## [0-9]+ · ' "$run/log.md")
printf '# log_entries\t%s\n' "${entries:-0}"
for s in done questions blocked; do
  printf '# log_%s\t%s\n' "$s" "$(grep -cE "^## [0-9]+ · [^·]+ · $s\$" "$run/log.md")"
done
