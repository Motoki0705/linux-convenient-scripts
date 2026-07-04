#!/usr/bin/env bash
set -euo pipefail

# codex-bg.sh
# Run Codex CLI non-interactively, optionally detached in the background.
#
# Codex equivalent of:
#   claude --bg --permission-mode bypassPermissions --name "fix-tests" "..."

KNOWN_MODELS=(
  "gpt-5.5"
  "gpt-5.4"
  "gpt-5.4-mini"
  "gpt-5.3-codex-spark"
)

EFFORT_LEVELS=(
  "minimal"
  "low"
  "medium"
  "high"
  "xhigh"
)

APPROVAL_POLICIES=(
  "untrusted"
  "on-request"
  "never"
)

SANDBOX_MODES=(
  "read-only"
  "workspace-write"
  "danger-full-access"
)

usage() {
  cat <<'EOF'
Usage:
  ./codex-bg.sh --name <job-name> --query "<request>" [options]

Required:
  -n, --name <name>
      Job name used for logs, PID file, and output file.
      Note: Codex CLI exec does not have Claude-style named --bg sessions.

  -q, --query "<text>"
      Task prompt passed to Codex.

Options:
  -m, --model <model>
      Model ID.

      Common current Codex models:
        gpt-5.5
        gpt-5.4
        gpt-5.4-mini
        gpt-5.3-codex-spark

      If omitted, Codex's configured/default model is used.

  -e, --effort <level>
      Reasoning effort.

      Available effort levels:
        minimal
        low
        medium
        high
        xhigh

      This is passed as:
        -c model_reasoning_effort=<level>

  -a, --approval <policy>
      Approval policy.

      Available approval policies:
        untrusted
        on-request
        never

      Default:
        never

      For non-interactive runs, "never" is usually the practical choice.

  -s, --sandbox <mode>
      Sandbox mode.

      Available sandbox modes:
        read-only
        workspace-write
        danger-full-access

      Default:
        workspace-write

  -C, --cd <path>
      Working directory for Codex.

      Default:
        current directory

  --yolo
      Use Codex's dangerous bypass flag:
        --dangerously-bypass-approvals-and-sandbox

      Only use inside an isolated container, VM, or disposable checkout.

  --json
      Enable JSONL event output from Codex.
      Recommended for logs.

  --foreground
      Run in the foreground instead of detaching.

  --dry-run
      Print the command that would be executed, without running it.

  --list
      Print known models, effort levels, approval policies, and sandbox modes.

  -h, --help
      Show this help.

Examples:
  ./codex-bg.sh \
    --name fix-tests \
    --model gpt-5.5 \
    --effort high \
    --query "pytestを実行し、失敗を修正し、pytestが全通過するまで繰り返してください。"

  ./codex-bg.sh \
    -n refactor \
    -m gpt-5.4 \
    -e xhigh \
    -s workspace-write \
    -a never \
    -q "src以下を整理し、テストが通るまで修正してください。"

  ./codex-bg.sh \
    -n dangerous-fix \
    -m gpt-5.5 \
    -e high \
    --yolo \
    -q "pytestを実行し、失敗を修正してください。"

Logs:
  logs are written under:
    .codex-runs/<name>.log
    .codex-runs/<name>.out
    .codex-runs/<name>.pid
EOF
}

list_values() {
  echo "Known Codex models:"
  printf '  %s\n' "${KNOWN_MODELS[@]}"
  echo
  echo "Reasoning effort levels:"
  printf '  %s\n' "${EFFORT_LEVELS[@]}"
  echo
  echo "Approval policies:"
  printf '  %s\n' "${APPROVAL_POLICIES[@]}"
  echo
  echo "Sandbox modes:"
  printf '  %s\n' "${SANDBOX_MODES[@]}"
}

contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

shell_quote_command() {
  printf '%q ' "$@"
  printf '\n'
}

NAME=""
QUERY=""
MODEL=""
EFFORT=""
APPROVAL="${CODEX_APPROVAL:-never}"
SANDBOX="${CODEX_SANDBOX:-workspace-write}"
WORKDIR="$(pwd)"
RUN_DIR=".codex-runs"
JSON_OUTPUT=0
FOREGROUND=0
DRY_RUN=0
YOLO=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name)
      NAME="${2:-}"
      shift 2
      ;;
    -q|--query)
      QUERY="${2:-}"
      shift 2
      ;;
    -m|--model)
      MODEL="${2:-}"
      shift 2
      ;;
    -e|--effort)
      EFFORT="${2:-}"
      shift 2
      ;;
    -a|--approval)
      APPROVAL="${2:-}"
      shift 2
      ;;
    -s|--sandbox)
      SANDBOX="${2:-}"
      shift 2
      ;;
    -C|--cd)
      WORKDIR="${2:-}"
      shift 2
      ;;
    --yolo)
      YOLO=1
      shift
      ;;
    --json)
      JSON_OUTPUT=1
      shift
      ;;
    --foreground)
      FOREGROUND=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --list)
      list_values
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      echo >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$NAME" ]]; then
  echo "Error: --name is required." >&2
  echo >&2
  usage >&2
  exit 1
fi

if [[ -z "$QUERY" ]]; then
  echo "Error: --query is required." >&2
  echo >&2
  usage >&2
  exit 1
fi

if [[ -n "$EFFORT" ]] && ! contains "$EFFORT" "${EFFORT_LEVELS[@]}"; then
  echo "Error: invalid effort: $EFFORT" >&2
  echo "Available effort levels:" >&2
  printf '  %s\n' "${EFFORT_LEVELS[@]}" >&2
  exit 1
fi

if [[ "$YOLO" -eq 0 ]] && ! contains "$APPROVAL" "${APPROVAL_POLICIES[@]}"; then
  echo "Error: invalid approval policy: $APPROVAL" >&2
  echo "Available approval policies:" >&2
  printf '  %s\n' "${APPROVAL_POLICIES[@]}" >&2
  exit 1
fi

if [[ "$YOLO" -eq 0 ]] && ! contains "$SANDBOX" "${SANDBOX_MODES[@]}"; then
  echo "Error: invalid sandbox mode: $SANDBOX" >&2
  echo "Available sandbox modes:" >&2
  printf '  %s\n' "${SANDBOX_MODES[@]}" >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "Error: codex command not found." >&2
  exit 1
fi

mkdir -p "$RUN_DIR"

LOG_FILE="$RUN_DIR/$NAME.log"
OUT_FILE="$RUN_DIR/$NAME.out"
PID_FILE="$RUN_DIR/$NAME.pid"

CMD=(
  codex
  exec
  --cd "$WORKDIR"
  --output-last-message "$OUT_FILE"
)

if [[ "$JSON_OUTPUT" -eq 1 ]]; then
  CMD+=(--json)
fi

if [[ -n "$MODEL" ]]; then
  CMD+=(--model "$MODEL")
fi

if [[ -n "$EFFORT" ]]; then
  CMD+=(-c "model_reasoning_effort=$EFFORT")
fi

if [[ "$YOLO" -eq 1 ]]; then
  CMD+=(--dangerously-bypass-approvals-and-sandbox)
else
  CMD+=(--ask-for-approval "$APPROVAL")
  CMD+=(--sandbox "$SANDBOX")
fi

CMD+=("$QUERY")

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Command:"
  echo "  $(shell_quote_command "${CMD[@]}")"
  echo
  if [[ "$FOREGROUND" -eq 0 ]]; then
    echo "Detached command:"
    if command -v setsid >/dev/null 2>&1; then
      echo "  setsid bash -lc '$(shell_quote_command "${CMD[@]}")' > '$LOG_FILE' 2>&1 < /dev/null &"
    else
      echo "  nohup bash -lc '$(shell_quote_command "${CMD[@]}")' > '$LOG_FILE' 2>&1 < /dev/null &"
    fi
  fi
  exit 0
fi

if [[ "$FOREGROUND" -eq 1 ]]; then
  exec "${CMD[@]}"
fi

# Detach the Codex run.
# On Linux/WSL, prefer setsid because it starts a new session.
# On macOS, setsid may not exist, so fall back to nohup.
if command -v setsid >/dev/null 2>&1; then
  setsid "${CMD[@]}" > "$LOG_FILE" 2>&1 < /dev/null &
else
  nohup "${CMD[@]}" > "$LOG_FILE" 2>&1 < /dev/null &
fi

PID="$!"
echo "$PID" > "$PID_FILE"

echo "Started Codex job: $NAME"
echo "PID: $PID"
echo "Log: $LOG_FILE"
echo "Final output: $OUT_FILE"
echo "PID file: $PID_FILE"
echo
echo "Watch log:"
echo "  tail -f $LOG_FILE"
