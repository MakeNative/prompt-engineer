#!/usr/bin/env bash
# prompt-engineer shared-file writer.
#
# Agents never write a shared file directly. They Write their piece to
# <run>/inbox/<file>/<agent>.md, and this PostToolUse hook merges it into the
# shared file under an exclusive lock, so agents running in parallel can
# neither interleave nor overwrite each other. The inbox file is then removed.
#
#   inbox/log/<agent>.md   -> appended to log.md as a new numbered entry
#   inbox/plan/<agent>.md  -> replaces the agent's own "## <agent>" section of
#                             plan.md, or appends it on the agent's first write
#
# The content is taken from the hook payload, not re-read from the inbox file,
# so a second Write to the same path cannot swap it out from under us.
#
# Exit 2 on a rejected piece: the agent sees why and can Write it again.
set -uo pipefail

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  if grep -q '/inbox/' <<<"$input"; then
    echo "SHARED-WRITE: jq is not installed, so shared files cannot be written. Install jq." >&2
    exit 2
  fi
  exit 0
fi

path=$(jq -r '.tool_input.file_path // ""' <<<"$input")
case "$path" in
  */.claude/runs/prompt-engineer/*/inbox/log/*.md)  mode=log ;;
  */.claude/runs/prompt-engineer/*/inbox/plan/*.md) mode=plan ;;
  *) exit 0 ;;
esac

run="${path%/inbox/*}"

# agent_type arrives namespaced ("prompt-engineer:planner"). Use the plain name.
agent=$(jq -r '.agent_type // "main"' <<<"$input")
agent="${agent##*:}"
agent_id=$(jq -r '.agent_id // "-"' <<<"$input")

err=$(jq -r '.tool_input.content // ""' <<<"$input" | perl -e '
  use strict; use warnings;
  use Fcntl qw(:flock SEEK_SET);
  use POSIX qw(strftime);
  my ($mode, $file, $agent, $id, $run_name) = @ARGV;
  my $dot = "\xC2\xB7";   # the middle dot, as UTF-8 bytes: everything here is bytes
  sub reject { print STDERR "SHARED-WRITE: not written. $_[0]\n"; exit 2 }

  # True if a line outside code fences matches the pattern.
  sub has_line {
    my ($text, $re) = @_;
    my $fence = 0;
    for my $l (split /\n/, $text) {
      if ($l =~ /^\s*```/) { $fence = !$fence; next }
      return 1 if !$fence && $l =~ $re;
    }
    return 0;
  }

  my $body = do { local $/; <STDIN> } // "";
  $body =~ s/\A\s+//;

  my $status;
  if ($mode eq "log") {
    $body =~ s/\A---\n(.*?)\n---[ \t]*\n//s
      or reject("A log entry must start with frontmatter: a line ---, status: <done|questions|blocked>, a line ---.");
    ($status) = $1 =~ /^status:[ \t]*(\S+)[ \t]*$/m;
    defined $status && $status =~ /\A(?:done|questions|blocked)\z/
      or reject("status must be exactly one of: done, questions, blocked.");
  }
  $body =~ s/\A\s*\n//;
  $body =~ s/\s+\z//;
  length $body or reject("There is no content.");
  has_line($body, qr/^#{1,2}\s/)
    and reject("Use ### headings or deeper. # and ## belong to the shared file itself.");

  open(my $fh, "+>>", $file) or reject("Cannot open $file: $!");
  flock($fh, LOCK_EX) or reject("Cannot lock $file: $!");

  # Everything from here to close() happens while holding the lock.
  seek($fh, 0, SEEK_SET);
  my $old = do { local $/; <$fh> } // "";
  my $out;

  if ($mode eq "log") {
    my $n = () = $old =~ /^## \d+ $dot /mg;
    $out = $old eq ""
      ? "# Run log: $run_name\n\nAppend-only. Agents add entries through the shared-write hook; nobody edits them.\n"
      : "";
    my $ts = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime);
    $out .= sprintf("\n---\n\n## %02d $dot %s $dot %s\n_%s $dot agent_id %s_\n\n%s\n",
                    $n + 1, $agent, $status, $ts, $id, $body);
    (print $fh $out) or reject("Cannot write $file: $!");   # append mode: lands at the end
  } else {
    my $section = "## $agent\n\n$body\n";
    my @lines = split /\n/, $old, -1;
    my ($start, $end, $fence) = (-1, scalar @lines, 0);
    for my $i (0 .. $#lines) {
      my $l = $lines[$i];
      if ($l =~ /^\s*```/) { $fence = !$fence; next }
      next if $fence;
      if ($start < 0) { $start = $i if $l eq "## $agent" }
      elsif ($l =~ /^## /) { $end = $i; last }
    }
    if ($start >= 0) {
      my $before = join("\n", @lines[0 .. $start - 1]);
      my $after  = join("\n", @lines[$end .. $#lines]);
      $before =~ s/\s+\z//;
      $out = ($before eq "" ? "" : "$before\n\n") . $section . ($end <= $#lines ? "\n$after" : "");
    } else {
      my $base = $old;
      $base =~ s/\s+\z//;
      $base = "# Plan\n\nWritten by the PLAN agents, one section each. The contract for every BUILD and REVIEW agent."
        if $base eq "";
      $out = "$base\n\n$section";
    }
    $out =~ s/\s*\z/\n/;
    truncate($fh, 0) or reject("Cannot rewrite $file: $!");
    (print $fh $out) or reject("Cannot write $file: $!");
  }
  close($fh) or reject("Cannot write $file: $!");
' "$mode" "$run/$mode.md" "$agent" "$agent_id" "$(basename "$run")" 2>&1 >/dev/null)
status=$?

if [[ $status -ne 0 ]]; then
  echo "${err:-SHARED-WRITE: not written (exit $status).}" >&2
  exit 2
fi

rm -f "$path"
exit 0
