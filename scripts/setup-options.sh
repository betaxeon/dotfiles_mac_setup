# Shared by bootstrap.sh and rebuild.sh; this file does not apply changes.
MODE_FILE="$DIR/.setup-mode"
MODE=""
DRY_RUN=false
SKIP_PACKAGES=false
SKIP_PREFERENCES=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      [[ $# -ge 2 ]] || { echo 'error: --mode needs personal or work' >&2; exit 1; }
      MODE="$2"
      shift 2
      ;;
    --dry-run) DRY_RUN=true; shift ;;
    --skip-packages) SKIP_PACKAGES=true; shift ;;
    --skip-preferences) SKIP_PREFERENCES=true; shift ;;
    --help|-h)
      echo "Usage: $0 [--mode personal|work] [--dry-run] [--skip-packages] [--skip-preferences]"
      echo 'The last three flags apply to work mode. The selected mode is saved locally.'
      exit 0
      ;;
    *) echo "error: unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$MODE" && -f "$MODE_FILE" ]]; then
  MODE="$(< "$MODE_FILE")"
fi
if [[ -z "$MODE" ]]; then
  echo 'error: select --mode personal or --mode work on the first run' >&2
  exit 1
fi
case "$MODE" in
  personal|work) ;;
  *) echo "error: invalid setup mode: $MODE" >&2; exit 1 ;;
esac
if [[ "$(id -u)" -eq 0 ]]; then
  echo 'error: run as your normal user, without sudo' >&2
  exit 1
fi
if [[ "$MODE" == personal ]] && { $DRY_RUN || $SKIP_PACKAGES || $SKIP_PREFERENCES; }; then
  echo 'error: --dry-run, --skip-packages and --skip-preferences apply only to work mode' >&2
  exit 1
fi

# Remember the choice before activation so a failed work setup cannot fall
# through to a privileged personal rebuild on the next invocation.
if ! $DRY_RUN; then
  printf '%s\n' "$MODE" > "$MODE_FILE"
fi
