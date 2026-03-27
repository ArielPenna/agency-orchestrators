#!/usr/bin/env bash
# install.sh — Agency Orchestrators installer
# Supports fzf (preferred), dialog/whiptail, or pure bash fallback
# Usage: ./install.sh

# ── Config ────────────────────────────────────────────────────────────────────
DEST="${HOME}/.config/opencode/agents"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SCRIPT_DIR}/agents"

# ── Sanity check ──────────────────────────────────────────────────────────────
if [[ ! -d "$SRC" ]]; then
  echo "Error: agents/ directory not found next to install.sh" >&2
  exit 1
fi

# ── Orchestrator definitions ──────────────────────────────────────────────────
# Each entry: "key|display_name|prefix1[|prefix2]"
# prefix is matched as: <prefix>-*.md  (orchestrator file is <key>.md)
ORCHESTRATORS=(
  "engineering|Engineering|engineering"
  "design|Design|design"
  "marketing|Marketing|marketing|paid-media"
  "product|Product|product"
  "pm|PM|pm"
  "testing|Testing|testing"
  "gamedev|Game Dev|gamedev"
  "specialized|Specialized|specialized"
)

# ── Dynamic subagent count ────────────────────────────────────────────────────
count_agents() {
  local total=0
  local key="$1"
  shift
  for prefix in "$@"; do
    local n
    n=$(ls "${SRC}/${prefix}"-*.md 2>/dev/null | wc -l)
    total=$((total + n))
  done
  echo "$total"
}

# Build parallel arrays for display
KEYS=()
NAMES=()
COUNTS=()
PREFIXES=()

for entry in "${ORCHESTRATORS[@]}"; do
  IFS='|' read -ra parts <<< "$entry"
  key="${parts[0]}"
  name="${parts[1]}"
  prefixes=("${parts[@]:2}")

  n=$(count_agents "$key" "${prefixes[@]}")
  label=$(printf "%-14s (%s agents)" "$name" "$n")

  KEYS+=("$key")
  NAMES+=("$name")
  COUNTS+=("$n")
  PREFIXES+=("$(IFS='|'; echo "${prefixes[*]}")")
done

# ── TUI detection ─────────────────────────────────────────────────────────────
detect_tui() {
  if command -v fzf &>/dev/null; then
    echo "fzf"
  elif command -v dialog &>/dev/null; then
    echo "dialog"
  elif command -v whiptail &>/dev/null; then
    echo "whiptail"
  else
    echo "bash"
  fi
}

# ── Selection: returns space-separated indices (0-based) into KEYS[] ──────────

select_fzf() {
  # Build fzf input: index TAB label
  local items=()
  items+=("ALL|All orchestrators  ($(( ${#KEYS[@]} )) teams, all agents)")
  for i in "${!KEYS[@]}"; do
    items+=("${i}|${NAMES[$i]}  (${COUNTS[$i]} agents)")
  done

  local chosen
  chosen=$(printf '%s\n' "${items[@]}" | \
    fzf --multi \
        --with-nth='2..' \
        --delimiter='|' \
        --prompt='Select orchestrators (SPACE to mark, ENTER to confirm): ' \
        --header='[TAB/SPACE] toggle  [ENTER] install  [ESC] cancel' \
        --height=60% \
        --border \
        --ansi \
    | cut -d'|' -f1)

  if [[ -z "$chosen" ]]; then
    echo ""
    return
  fi

  # If ALL is in chosen, return all indices
  if echo "$chosen" | grep -q "^ALL$"; then
    seq 0 $(( ${#KEYS[@]} - 1 )) | tr '\n' ' '
    return
  fi

  echo "$chosen" | tr '\n' ' '
}

select_checklist() {
  local tool="$1"  # dialog or whiptail
  local cmd=("$tool" --title "Agency Orchestrators" \
    --checklist "Select orchestrators to install (SPACE to toggle):" \
    20 60 10)

  cmd+=("ALL" "All orchestrators" "off")
  for i in "${!KEYS[@]}"; do
    cmd+=("$i" "${NAMES[$i]} (${COUNTS[$i]} agents)" "off")
  done

  local chosen
  chosen=$("${cmd[@]}" 3>&1 1>&2 2>&3) || true

  if [[ -z "$chosen" ]]; then
    echo ""
    return
  fi

  # dialog/whiptail returns quoted tokens — normalize
  chosen=$(echo "$chosen" | tr -d '"')

  if echo "$chosen" | grep -qw "ALL"; then
    seq 0 $(( ${#KEYS[@]} - 1 )) | tr '\n' ' '
    return
  fi

  echo "$chosen"
}

select_bash() {
  # Menu output goes to /dev/tty so it is NOT captured by $() in main
  {
    echo ""
    echo "╔════════════════════════════════════════════════╗"
    echo "║       Agency Orchestrators — Installer         ║"
    echo "╠════════════════════════════════════════════════╣"
    printf "║  %-3s  %-14s  %s\n" "0" "ALL" "All orchestrators"
    for i in "${!KEYS[@]}"; do
      printf "║  %-3s  %-14s  (%s agents)\n" "$((i+1))" "${NAMES[$i]}" "${COUNTS[$i]}"
    done
    echo "╚════════════════════════════════════════════════╝"
    echo ""
    echo "Enter numbers separated by spaces (e.g.: 1 3 5), or 0 for all:"
    echo -n "> "
  } >/dev/tty

  read -r raw_input </dev/tty

  if [[ -z "$raw_input" ]]; then
    return
  fi

  local indices=()
  local all_selected=0
  for token in $raw_input; do
    if [[ "$token" == "0" ]]; then
      all_selected=1
      break
    elif [[ "$token" =~ ^[1-9][0-9]*$ ]]; then
      local idx=$(( token - 1 ))
      if (( idx >= 0 && idx < ${#KEYS[@]} )); then
        indices+=("$idx")
      else
        echo "  Warning: '$token' is out of range, skipping." >/dev/tty
      fi
    else
      echo "  Warning: '$token' is not a valid number, skipping." >/dev/tty
    fi
  done

  if (( all_selected )); then
    seq 0 $(( ${#KEYS[@]} - 1 )) | tr '\n' ' '
    return
  fi

  # Deduplicate indices before returning
  local seen=()
  local unique=()
  for idx in "${indices[@]}"; do
    local dup=0
    for s in "${seen[@]}"; do
      [[ "$s" == "$idx" ]] && dup=1 && break
    done
    if (( !dup )); then
      seen+=("$idx")
      unique+=("$idx")
    fi
  done

  echo "${unique[*]}"
}

# ── Install selected orchestrators ────────────────────────────────────────────
install_selection() {
  local selected_indices=($@)

  if [[ ${#selected_indices[@]} -eq 0 ]]; then
    echo "No orchestrators selected. Exiting."
    exit 0
  fi

  mkdir -p "$DEST"

  local total_orchestrators=0
  local total_agents=0
  local installed_names=()

  for idx in "${selected_indices[@]}"; do
    # Validate index
    if ! [[ "$idx" =~ ^[0-9]+$ ]] || (( idx >= ${#KEYS[@]} )); then
      continue
    fi

    local key="${KEYS[$idx]}"
    local name="${NAMES[$idx]}"
    IFS='|' read -ra prefixes <<< "${PREFIXES[$idx]}"

    # Copy orchestrator file
    if [[ -f "${SRC}/${key}.md" ]]; then
      cp "${SRC}/${key}.md" "${DEST}/"
      (( total_orchestrators++ )) || true
    fi

    # Copy subagents for each prefix
    local agent_count=0
    for prefix in "${prefixes[@]}"; do
      local files=("${SRC}/${prefix}"-*.md)
      if [[ -e "${files[0]}" ]]; then
        cp "${SRC}/${prefix}"-*.md "${DEST}/"
        local n
        n=$(ls "${SRC}/${prefix}"-*.md 2>/dev/null | wc -l)
        agent_count=$((agent_count + n))
      fi
    done

    total_agents=$((total_agents + agent_count))
    installed_names+=("$name")
  done

  # ── Summary ───────────────────────────────────────────────────────────────
  echo ""
  if [[ ${#installed_names[@]} -gt 0 ]]; then
    echo "✓ Installed ${total_orchestrators} orchestrator(s) + ${total_agents} agents → ${DEST}"
    echo ""
    echo "  Teams installed:"
    for n in "${installed_names[@]}"; do
      echo "    • $n"
    done
    echo ""
    echo "  Restart OpenCode to load the new agents."
  else
    echo "Nothing was installed."
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  local tui
  tui=$(detect_tui)

  local raw_selection=""

  case "$tui" in
    fzf)
      raw_selection=$(select_fzf)
      ;;
    dialog)
      raw_selection=$(select_checklist "dialog")
      ;;
    whiptail)
      raw_selection=$(select_checklist "whiptail")
      ;;
    bash)
      raw_selection=$(select_bash)
      ;;
  esac

  if [[ -z "$raw_selection" ]]; then
    echo "Cancelled."
    exit 0
  fi

  # Deduplicate indices (defensive — select_bash already deduplicates,
  # but fzf/dialog could theoretically return repeated values)
  local deduped=()
  local seen_main=()
  for idx in $raw_selection; do
    local dup=0
    for s in "${seen_main[@]}"; do
      [[ "$s" == "$idx" ]] && dup=1 && break
    done
    if (( !dup )); then
      seen_main+=("$idx")
      deduped+=("$idx")
    fi
  done

  install_selection "${deduped[@]}"
}

main "$@"
