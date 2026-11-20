#!/usr/bin/env bash
# prompt-engineer access guard.
# Enforces the write scope each component was given in pipeline-policy.json.
# Reads the hook payload on stdin; exit 2 blocks the tool call.
set -uo pipefail

input=$(cat)

# Without jq nothing below can read the call, and every rule would pass it.
# Block this pipeline's own agents then; leave every other session alone.
if ! command -v jq >/dev/null 2>&1; then
  if grep -Eq '"agent_type"[[:space:]]*:[[:space:]]*"prompt-engineer:' <<<"$input"; then
    echo "BLOCKED: the prompt-engineer access guard needs jq to check this call. Install jq." >&2
    exit 2
  fi
  exit 0
fi

tool=$(jq -r '.tool_name // ""' <<<"$input")

# agent_type arrives namespaced ("prompt-engineer:planner"). Strip the prefix,
# or a project-local override agent silently escapes the policy.
agent=$(jq -r '.agent_type // "main"' <<<"$input")
agent="${agent##*:}"

# A project copy wins, so a team can correct contractPaths without forking the plugin.
policy="${CLAUDE_PROJECT_DIR}/pipeline-policy.json"
[[ -f "$policy" ]] || policy="${CLAUDE_PLUGIN_ROOT}/pipeline-policy.json"
# No policy: allow. A half-installed plugin must not brick the session.
[[ -f "$policy" ]] || exit 0

# Guard only this pipeline's agents. A plugin's hooks run in every session it is
# installed in, so the main session and other plugins' agents must pass; same
# filter as timing.sh.
raw=$(jq -r '.agent_type // ""' <<<"$input")
[[ -n "$raw" ]] || exit 0
if [[ "$raw" != prompt-engineer:* ]]; then
  [[ "$raw" == *:* ]] && exit 0
  jq -e --arg a "$raw" '.agents[$a]' "$policy" >/dev/null 2>&1 || exit 0
fi

if [[ "$tool" == "Bash" ]]; then
  cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
  if grep -Eq '(^|[;&|[:space:]])git[[:space:]]+(commit|push)([[:space:]]|$)' <<<"$cmd"; then
    echo "BLOCKED: prompt-engineer components never commit or push. The author reviews and commits." >&2
    exit 2
  fi
  exit 0
fi

path=$(jq -r '.tool_input.file_path // ""' <<<"$input")

# A component may always write its OWN memory - that is how it carries anything
# across runs. Only its own: another component's memory is not its to edit.
case "$path" in
  */.claude/agent-memory/prompt-engineer-"$agent"/*) exit 0 ;;
  */.claude/agent-memory/*)
    echo "BLOCKED: $agent may only write its own memory, at .claude/agent-memory/prompt-engineer-$agent/." >&2
    exit 2
    ;;
esac

phase=$(jq -r --arg a "$agent" '.agents[$a].phase // ""' "$policy")

# The run directory.
#
# Framework agents (run-setup, run-summary) run alone, before and after the
# pipeline's own agents, so they may write it directly: run-setup creates
# 00-task.md and the empty shared files.
#
# Every other agent never writes a run file directly. log.md and plan.md are
# shared, and two agents rewriting one file lose one of the two versions. An
# agent hands its piece to inbox/<file>/<agent>.md with Write, and the
# shared-write hook merges it in under a lock.
case "$path" in
  */.claude/runs/prompt-engineer/*)
    [[ "$phase" == "FRAMEWORK" ]] && exit 0
    base=$(basename "$path")
    case "$path" in
      */inbox/log/*|*/inbox/plan/*)
        if [[ "$base" != "$agent.md" || "$tool" != "Write" ]]; then
          echo "BLOCKED: $agent may only Write its own piece, inbox/<log|plan>/$agent.md. Use Write, not Edit." >&2
          exit 2
        fi
        # plan.md is the contract for BUILD and REVIEW. Only PLAN agents write it.
        if [[ "$path" == */inbox/plan/* && "$phase" != "PLAN" ]]; then
          echo "BLOCKED: plan.md is the contract, and only PLAN agents write it. If it is wrong, append a run log entry with status: blocked that says why (see plan-contract.md)." >&2
          exit 2
        fi
        exit 0
        ;;
    esac
    echo "BLOCKED: $agent never writes the run directory directly. Hand your log entry to inbox/log/$agent.md$([[ "$phase" == "PLAN" ]] && echo " and your plan section to inbox/plan/$agent.md") (see run-log.md and plan-contract.md)." >&2
    exit 2
    ;;
esac

rule=$(jq -r --arg a "$agent" '.agents[$a].deny // "none"' "$policy")
case "$rule" in
  none) exit 0 ;;
  all|contract|non-contract) ;;
  *)
    # A mistyped rule must not turn into "allow".
    echo "BLOCKED: pipeline-policy.json gives $agent the unknown deny rule '$rule'. Use all, contract, non-contract or none." >&2
    exit 2
    ;;
esac

if [[ "$rule" == "all" ]]; then
  echo "BLOCKED: $agent is read-only. Its only output is its run log entry - write your findings there instead." >&2
  exit 2
fi

is_contract=""
while IFS= read -r pat; do
  [[ -n "$pat" ]] || continue
  if [[ "$path" =~ $pat ]]; then is_contract=yes; break; fi
done < <(jq -r '.contractPaths[]?' "$policy")

if [[ "$rule" == "contract" && "$is_contract" == "yes" ]]; then
  echo "BLOCKED: $agent may not modify the contract - it is what defines done. Record the disagreement in your run log entry and let the workflow route it." >&2
  exit 2
fi

if [[ "$rule" == "non-contract" && "$is_contract" != "yes" ]]; then
  echo "BLOCKED: $agent writes the contract only, never the work itself." >&2
  exit 2
fi

exit 0
