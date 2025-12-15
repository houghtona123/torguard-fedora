#!/usr/bin/env bash
# ====================================================
# torguard wireguard set script menu
# ====================================================

set -euo pipefail

need_cmd() { command -v "$1" >/dev/null || exit 1; }
need_cmd nmcli
need_cmd curl

list_wg() {
  nmcli -t -f NAME,TYPE connection show | awk -F: '$2=="wireguard"{print $1}'
}

active_wg() {
  nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2=="wireguard"{print $1}'
}

disconnect_all() {
  for c in $(active_wg); do sudo nmcli connection down "$c"; done
}

connect_wg() {
  sudo nmcli connection up "$1"
}

show_status() {
  local a=$(active_wg)
  [[ -z "$a" ]] && echo "Disconnected" || echo "Connected: $a"
  echo -n "IP: "
  curl -s https://ipinfo.io/ip || echo unknown
}

menu() {
  echo ""; show_status; echo ""
  mapfile -t conns < <(list_wg)
  local i=1
  for c in "${conns[@]}"; do echo "$i) $c"; ((i++)); done
  echo "d) Disconnect"
  read -rp "Select: " ch
  [[ "$ch" == "d" ]] && disconnect_all && exit 0
  disconnect_all
  connect_wg "${conns[$((ch-1))]}"
}

menu
