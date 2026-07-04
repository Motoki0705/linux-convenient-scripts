#!/usr/bin/env bash
set -euo pipefail

# claude-bg.sh
# Launch a Claude Code background session with configurable name, query, model, and effort.

KNOWN_MODELS=(
  "fable"
  "opus"
  "sonnet"
  "haiku"
  "claude-fable-5"
  "claude-opus-4-8"
  "claude-sonnet-5"
  "claude-haiku-4-5"
  "claude-haiku-4-5-20251001"
)

EFFORT_LEVELS=(
  "low"
  "medium"
  "high"
  "xhigh"
  "max"
)

PERMISSION_MODES=(
  "default"
  "manual"
  "acceptEdits"
  "plan"
  "auto"
  "dontAsk"
  "bypassPermissions"
)

usage() {
  cat <<'EOF'
Usage:
  ./claude-bg.sh --name <session-name> --query "<request>" [options]

Required:
  -n, --name <name>
      Background session name.

  -q, --query "<text>"
      Task prompt passed to Claude Code.

Options:
  -m, --model <model>
      Model alias or full model ID.

      Common aliases:
        fable
        opus
        sonnet
        haiku

      Common current model IDs:
        claude-fable-5
        claude-opus-4-8
        claude-sonnet-5
        claude-haiku-4-5
        claude-haiku-4-5-20251001

      If omitted, Claude Code's configured/default model is used.

  -e, --effort <level>
      Reasoning effort level.

      Available effort levels:
        low
        medium
        high
        xhigh
        max

      Notes:
        - Available levels depend on the selected model/account.
        - Claude Code may fall back if a model does not support the requested level.
        - "ultracode" is not a --effort value.

  -p, --permission-mode <mode>
      Permission mode.

      Available permission modes:
        default
        manual
        acceptEdits
        plan
        auto
        dontAsk
        bypassPermissions

      Default:
        bypassPermissions

  --dry-run
      Print the command without executing it.

  --list
      Print known model aliases/IDs, effort levels, and permission modes.

  -h, --help
      Show this help.

Examples:
  ./claude-bg.sh \
    --name fix-tests \
    --query "pytestを実行し、失敗を修正し、pytestが全通過するまで繰り返してください。"

  ./claude-bg.sh \
    --name fix-tests \
    --model fable \
    --effort high \
    --query "pytestを実行し、失敗を修正し、pytestが全通過するまで繰り返してください。"

  ./claude-bg.sh \
    -n refactor \
    -m sonnet \
    -e xhigh \
    -q "src以下を整理し、テストが通るまで修正してください。"

  ./claude-bg.sh \
    -n safe-plan \
    -m opus \
    -e medium \
    -p auto \
    -q "実装計画を立ててから、必要な修正を行ってください。"
EOF
}

list_values() {
  echo "Known model aliases / IDs:"
  printf '  %s\n' "${KNOWN_MODELS[@]}"
  echo
  echo "Effort levels:"
  printf '  %s\n' "${EFFORT_LEVELS[@]}"
  echo
  echo "Permission modes:"
  printf '  %s\n' "${PERMISSION_MODES[@]}"
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

NAME=""
QUERY=""
MODEL=""
EFFORT=""
PERMISSION_MODE="${PERMISSION_MODE:-bypassPermissions}"
DRY_RUN=0

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
    -p|--permission-mode)
      PERMISSION_MODE="${2:-}"
      shift 2
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

if [[ -n "$PERMISSION_MODE" ]] && ! contains "$PERMISSION_MODE" "${PERMISSION_MODES[@]}"; then
  echo "Error: invalid permission mode: $PERMISSION_MODE" >&2
  echo "Available permission modes:" >&2
  printf '  %s\n' "${PERMISSION_MODES[@]}" >&2
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "Error: claude command not found." >&2
  exit 1
fi

CMD=(
  claude
  --bg
  --permission-mode "$PERMISSION_MODE"
  --name "$NAME"
)

if [[ -n "$MODEL" ]]; then
  CMD+=(--model "$MODEL")
fi

if [[ -n "$EFFORT" ]]; then
  CMD+=(--effort "$EFFORT")
fi

CMD+=("$QUERY")

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf 'Command:\n  '
  printf '%q ' "${CMD[@]}"
  printf '\n'
  exit 0
fi

exec "${CMD[@]}"
