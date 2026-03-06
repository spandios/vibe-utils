#!/usr/bin/env bash
set -euo pipefail

OS="$(uname -s)"
DRY_RUN="false"
WITH_PLAYWRIGHT_BROWSER="false"
PYTHON_BIN="${PYTHON_BIN:-python3}"

SELECTED_SKILLS=()
BREW_PACKAGES=()
APT_PACKAGES=()
NPM_PACKAGES=()
PYTHON_PACKAGES=()
MANUAL_NOTES=()

DEFAULT_SKILLS=(
  "doc"
  "gh-fix-ci"
  "imagegen"
  "notebooklm"
  "pdf"
  "playwright"
  "playwright-interactive"
  "screenshot"
  "security-ownership-map"
  "sentry"
  "spreadsheet"
)

print_help() {
  cat <<'EOF'
Usage:
  skills/install-prereqs.sh [options]

Options:
  --all                         Install prereqs for all supported skills (default)
  --skill <name>                Install prereqs for one skill; repeatable
  --with-playwright-browser     Also run `playwright-cli install-browser`
  --dry-run                     Print commands without executing
  --list                        Show supported skill names
  --help                        Show this help

Supported skills:
  doc
  gh-fix-ci
  imagegen
  notebooklm
  pdf
  playwright
  playwright-interactive
  screenshot
  security-ownership-map
  sentry
  spreadsheet

Notes:
  - This script installs package dependencies only.
  - Auth/env setup like OPENAI_API_KEY, SENTRY_AUTH_TOKEN, gh auth, NotebookLM login
    is reported separately and must still be completed manually.
  - `playwright-interactive` needs workspace-local setup, so this script only prints
    the required follow-up steps for that skill.
EOF
}

print_list() {
  printf '%s\n' "${DEFAULT_SKILLS[@]}"
}

array_contains() {
  local needle="$1"
  shift || true
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

add_unique() {
  local target="$1"
  local value="$2"
  eval "local current=(\"\${${target}[@]-}\")"
  if array_contains "$value" "${current[@]}"; then
    return 0
  fi
  eval "${target}+=(\"\$value\")"
}

add_brew() {
  local pkg
  for pkg in "$@"; do
    add_unique BREW_PACKAGES "$pkg"
  done
}

add_apt() {
  local pkg
  for pkg in "$@"; do
    add_unique APT_PACKAGES "$pkg"
  done
}

add_npm() {
  local pkg
  for pkg in "$@"; do
    add_unique NPM_PACKAGES "$pkg"
  done
}

add_python() {
  local pkg
  for pkg in "$@"; do
    add_unique PYTHON_PACKAGES "$pkg"
  done
}

add_note() {
  add_unique MANUAL_NOTES "$1"
}

add_skill() {
  local skill="$1"
  add_unique SELECTED_SKILLS "$skill"

  case "$skill" in
    doc)
      add_python python-docx pdf2image
      case "$OS" in
        Darwin) add_brew libreoffice poppler ;;
        Linux) add_apt libreoffice poppler-utils ;;
      esac
      ;;
    gh-fix-ci)
      case "$OS" in
        Darwin) add_brew gh ;;
        Linux) add_apt gh ;;
      esac
      add_note 'gh-fix-ci: run `gh auth login` and verify with `gh auth status` before use.'
      ;;
    imagegen)
      add_python openai pillow
      add_note 'imagegen: set `OPENAI_API_KEY` before live API calls.'
      ;;
    notebooklm)
      add_python notebooklm-py
      add_note 'notebooklm: run `notebooklm login` after install.'
      add_note 'notebooklm: if the `notebooklm` command is not on PATH after pip install, add your Python user bin directory to PATH.'
      ;;
    pdf)
      add_python reportlab pdfplumber pypdf
      case "$OS" in
        Darwin) add_brew poppler ;;
        Linux) add_apt poppler-utils ;;
      esac
      ;;
    playwright)
      add_npm @playwright/cli
      ;;
    playwright-interactive)
      add_note 'playwright-interactive: in each target workspace, run `npm install playwright`.'
      add_note 'playwright-interactive: for headed Chromium or mobile emulation, also run `npx playwright install chromium` in that workspace.'
      add_note 'playwright-interactive: Electron targets may also need `npm install --save-dev electron` in the app workspace.'
      ;;
    screenshot)
      case "$OS" in
        Darwin)
          add_note 'screenshot: macOS uses built-in capture tooling; first run the permission helper when needed.'
          ;;
        Linux)
          add_note 'screenshot: install one Linux capture tool such as `scrot`, `gnome-screenshot`, or ImageMagick `import` if missing.'
          ;;
      esac
      ;;
    security-ownership-map)
      add_python networkx
      ;;
    sentry)
      add_note 'sentry: set `SENTRY_AUTH_TOKEN` before use.'
      ;;
    spreadsheet)
      add_python openpyxl pandas matplotlib
      case "$OS" in
        Darwin) add_brew libreoffice poppler ;;
        Linux) add_apt libreoffice poppler-utils ;;
      esac
      ;;
    *)
      echo "Unknown skill: $skill" >&2
      exit 1
      ;;
  esac
}

run_cmd() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
  if [[ "$DRY_RUN" != "true" ]]; then
    "$@"
  fi
}

need_cmd() {
  local cmd="$1"
  local message="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$message" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      SELECTED_SKILLS=()
      shift
      ;;
    --skill)
      [[ $# -ge 2 ]] || { echo "Missing value for --skill" >&2; exit 1; }
      add_skill "$2"
      shift 2
      ;;
    --with-playwright-browser)
      WITH_PLAYWRIGHT_BROWSER="true"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --list)
      print_list
      exit 0
      ;;
    --help)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      print_help >&2
      exit 1
      ;;
  esac
done

if [[ ${#SELECTED_SKILLS[@]} -eq 0 ]]; then
  for skill in "${DEFAULT_SKILLS[@]}"; do
    add_skill "$skill"
  done
fi

if array_contains "playwright" "${SELECTED_SKILLS[@]}"; then
  if [[ "$WITH_PLAYWRIGHT_BROWSER" == "true" ]]; then
    add_note 'playwright: browser bootstrap will run via `playwright-cli install-browser`.'
  else
    add_note 'playwright: add `--with-playwright-browser` if you also want the CLI browser cache preinstalled.'
  fi
fi

printf '대상 스킬: %s\n' "${SELECTED_SKILLS[*]}"

if [[ ${#BREW_PACKAGES[@]} -gt 0 ]]; then
  printf 'Homebrew 패키지: %s\n' "${BREW_PACKAGES[*]}"
fi
if [[ ${#APT_PACKAGES[@]} -gt 0 ]]; then
  printf 'apt 패키지: %s\n' "${APT_PACKAGES[*]}"
fi
if [[ ${#NPM_PACKAGES[@]} -gt 0 ]]; then
  printf 'npm 전역 패키지: %s\n' "${NPM_PACKAGES[*]}"
fi
if [[ ${#PYTHON_PACKAGES[@]} -gt 0 ]]; then
  printf 'Python 패키지 (%s): %s\n' "$PYTHON_BIN" "${PYTHON_PACKAGES[*]}"
fi
echo

if [[ ${#BREW_PACKAGES[@]} -gt 0 ]]; then
  case "$OS" in
    Darwin)
      need_cmd brew "Homebrew가 필요해. https://brew.sh 에서 설치해줘."
      run_cmd brew install "${BREW_PACKAGES[@]}"
      ;;
    *)
      echo "현재 OS($OS)에서는 brew 패키지를 자동 설치하지 않아." >&2
      exit 1
      ;;
  esac
fi

if [[ ${#APT_PACKAGES[@]} -gt 0 ]]; then
  case "$OS" in
    Linux)
      need_cmd apt-get "apt-get이 필요해."
      need_cmd sudo "apt 패키지 설치에는 sudo가 필요해."
      run_cmd sudo apt-get update
      run_cmd sudo apt-get install -y "${APT_PACKAGES[@]}"
      ;;
    *)
      echo "현재 OS($OS)에서는 apt 패키지를 자동 설치하지 않아." >&2
      exit 1
      ;;
  esac
fi

if [[ ${#NPM_PACKAGES[@]} -gt 0 ]]; then
  need_cmd npm "npm이 필요해. Node.js/npm 먼저 설치해줘."
  run_cmd npm install -g "${NPM_PACKAGES[@]}"
fi

if [[ ${#PYTHON_PACKAGES[@]} -gt 0 ]]; then
  need_cmd "$PYTHON_BIN" "$PYTHON_BIN 이 필요해."
  run_cmd "$PYTHON_BIN" -m pip install "${PYTHON_PACKAGES[@]}"
fi

if [[ "$WITH_PLAYWRIGHT_BROWSER" == "true" ]] && array_contains "playwright" "${SELECTED_SKILLS[@]}"; then
  if command -v playwright-cli >/dev/null 2>&1; then
    run_cmd playwright-cli install-browser
  else
    need_cmd npx "Playwright browser bootstrap에는 npx가 필요해."
    run_cmd npx --yes @playwright/cli install-browser
  fi
fi

if [[ ${#MANUAL_NOTES[@]} -gt 0 ]]; then
  echo
  echo "수동 후속 작업:"
  local_note=""
  for local_note in "${MANUAL_NOTES[@]}"; do
    printf '  - %s\n' "$local_note"
  done
fi

echo
echo "완료"
