#!/usr/bin/env bats

# Unit tests for compact-mode-check.sh. These cover the pure functions only
# (parsing, risk-class detection, date normalization, verdict formatting) and
# make no network calls. Run via `make test-scripts` or `bats <file>`.

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/compact-mode-check.sh"
  # Sourcing must not execute main (guarded by BASH_SOURCE == $0).
  # shellcheck source=/dev/null
  source "$SCRIPT"
}

issue_12_text() {
  cat << 'EOF'
Event priority ranking and metric-policy gate (rank_event_priority)

Implement the tool in internal/events per plans/0007-reporting-decision-output-contracts.md
section 4 metric-policy gate and plans/0004 phase 3. Add test/integration/event_rank_smoke_test.go.
The deliverable emits decision_basis and provenance fields.
EOF
}

plain_text() {
  cat << 'EOF'
Add a persisted boundary field to the brew log struct and a new sentinel
error. Small bounded change in one file.
EOF
}

@test "parse_artifacts finds the events package and plan 0007" {
  run parse_artifacts <<< "$(issue_12_text)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"internal/events"* ]]
  [[ "$output" == *"0007"* ]]
}

@test "parse_artifacts returns nothing for a body with no paths or plan refs" {
  run parse_artifacts <<< "$(plain_text)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "risk_class_verbs fires on an #12-shaped title (ranking -> rank)" {
  run risk_class_verbs <<< "$(issue_12_text)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"rank"* ]]
}

@test "risk_class_fields fires on decision_basis and provenance" {
  run risk_class_fields <<< "$(issue_12_text)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"decision_basis"* ]]
  [[ "$output" == *"provenance"* ]]
}

@test "risk_class_fields fires on success_probability and probability_adjustment_source" {
  run risk_class_fields <<< "the deliverable emits success_probability and a probability_adjustment_source field"
  [ "$status" -eq 0 ]
  [[ "$output" == *"success_probability"* ]]
  [[ "$output" == *"probability_adjustment_source"* ]]
}

@test "risk_class_advisory flags a plan reference near a policy marker" {
  run risk_class_advisory <<< "$(issue_12_text)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"signal (b)"* || "$output" == *"policy"* ]]
}

@test "risk-class signals are silent on a plain body" {
  run risk_class_verbs <<< "$(plain_text)"
  [ -z "$output" ]
  run risk_class_fields <<< "$(plain_text)"
  [ -z "$output" ]
  run risk_class_advisory <<< "$(plain_text)"
  [ -z "$output" ]
}

@test "normalize_date strips the RFC3339 time component" {
  run normalize_date "2026-08-23T14:02:11Z"
  [ "$status" -eq 0 ]
  [ "$output" = "2026-08-23" ]
}

@test "classify_artifact widens an internal file to its package dir" {
  run classify_artifact "internal/events/schedule.go"
  [ "$output" = $'dir\tinternal/events' ]
}

@test "classify_artifact treats a bare 0NNN as a plan reference" {
  run classify_artifact "0007"
  [ "$output" = $'plan\t0007' ]
}

@test "file_matches_artifact matches a package dir prefix" {
  run file_matches_artifact "internal/events/schedule.go" "dir" "internal/events"
  [ "$status" -eq 0 ]
  run file_matches_artifact "internal/catalog/price.go" "dir" "internal/events"
  [ "$status" -ne 0 ]
}

@test "format_verdict disqualifies on drift > 0" {
  run format_verdict "" "" "3" "2026-08-23"
  [[ "$output" == "COMPACT_MODE: disqualified"* ]]
  [[ "$output" == *"drift = 3"* ]]
}

@test "format_verdict disqualifies on a risk-class verb with zero drift" {
  run format_verdict "rank" "" "0" "2026-08-23"
  [[ "$output" == "COMPACT_MODE: disqualified"* ]]
  [[ "$output" == *"signal (a)"* ]]
}

@test "format_verdict disqualifies on a decision field" {
  run format_verdict "" "decision_basis" "0" "2026-08-23"
  [[ "$output" == "COMPACT_MODE: disqualified"* ]]
  [[ "$output" == *"signal (c)"* ]]
}

@test "format_verdict signal (b) advisory is not an input and never flips the verdict" {
  # No (a)/(c) signal and zero drift stays eligible regardless of any advisory.
  run format_verdict "" "" "0" "2026-08-23"
  [ "$output" = "COMPACT_MODE: eligible" ]
}

@test "format_verdict reports inconclusive staleness fallback" {
  run format_verdict "" "" "inconclusive" "2026-08-23"
  [[ "$output" == *"eligible (staleness inconclusive"* ]]
}

@test "format_verdict disqualifies on a capped drift result" {
  run format_verdict "" "" "capped" "2026-08-23"
  [[ "$output" == "COMPACT_MODE: disqualified"* ]]
  [[ "$output" == *"staleness indeterminate"* ]]
  [[ "$output" == *"cap"* ]]
}

@test "print_report renders artifacts, drift, and risk-class lines" {
  run print_report "12" "5" "2026-08-23" $'internal/events\n0007' \
    "4" $'rank\nscore' $'decision_basis\nprovenance' "policy"
  [ "$status" -eq 0 ]
  [[ "$output" == *"issue: #12"* ]]
  [[ "$output" == *"age_days: 5"* ]]
  [[ "$output" == *"window_start: 2026-08-23"* ]]
  [[ "$output" == *"  - internal/events"* ]]
  [[ "$output" == *"  - 0007"* ]]
  [[ "$output" == *"drift: 4"* ]]
  [[ "$output" == *"risk_class_signal_a_verbs: rank,score"* ]]
  [[ "$output" == *"risk_class_signal_c_fields: decision_basis,provenance"* ]]
  [[ "$output" == *"RISK_CLASS_ADVISORY: signal (b) possible (policy)"* ]]
}

@test "print_report shows placeholders when there are no artifacts or signals" {
  run print_report "42" "unknown" "inconclusive" "" "inconclusive" "" "" ""
  [ "$status" -eq 0 ]
  [[ "$output" == *"  (none parsed)"* ]]
  [[ "$output" == *"risk_class_signal_a_verbs: none"* ]]
  [[ "$output" == *"risk_class_signal_c_fields: none"* ]]
  [[ "$output" != *"RISK_CLASS_ADVISORY"* ]]
}

# count_drift talks to gh; these tests stub gh with a shell function returning
# canned `gh pr list --json number,files` output, so they make no network call.

@test "count_drift returns 0 when no merged PR touches an artifact" {
  gh() { echo '[{"number":1,"files":[{"path":"docs/x.md"}]}]'; }
  run count_drift "" "2026-01-01" <<< $'dir\tinternal/events'
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "count_drift deduplicates multiple matching files in one PR" {
  gh() { echo '[{"number":1,"files":[{"path":"internal/events/a.go"},{"path":"internal/events/b.go"}]},{"number":2,"files":[{"path":"docs/x.md"}]}]'; }
  run count_drift "" "2026-01-01" <<< $'dir\tinternal/events'
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "count_drift counts multiple distinct matching PRs" {
  gh() { echo '[{"number":1,"files":[{"path":"internal/events/a.go"}]},{"number":2,"files":[{"path":"internal/events/b.go"}]}]'; }
  run count_drift "" "2026-01-01" <<< $'dir\tinternal/events'
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

@test "count_drift fails loudly when gh errors" {
  gh() { return 1; }
  run count_drift "" "2026-01-01" <<< $'dir\tinternal/events'
  [ "$status" -ne 0 ]
}

@test "count_drift reports capped when the PR list hits the fetch cap with no match" {
  gh() { jq -nc '[range(200) | {number: ., files: [{path: "docs/none.md"}]}]'; }
  run count_drift "" "2026-01-01" <<< $'dir\tinternal/events'
  [ "$status" -eq 0 ]
  [ "${lines[${#lines[@]}-1]}" = "capped" ]
}
