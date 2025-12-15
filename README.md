## TorGuard WireGuard CLI Menu (Fedora / KDE)

This guide documents the full process used to **fix TorGuard WireGuard issues on Fedora** and create a **simple CLI + popup menu** to manage WireGuard connections via NetworkManager.

This was written after extensive troubleshooting where the **official TorGuard GUI was stuck on “Reconnecting”**. After completing these steps, both the **CLI menu** and the **official TorGuard GUI** worked correctly.

---

## ✅ What This Solves

* TorGuard GUI stuck on **Reconnecting**
* WireGuard connects but no traffic flows
* SELinux silently blocking VPN
* NetworkManager WireGuard profiles missing or broken
* No easy way to switch WireGuard servers

---

## 🧩 Prerequisites

* Fedora (tested on Fedora KDE)
* NetworkManager enabled
* sudo access

Install required packages:

```bash
sudo dnf install -y wireguard-tools NetworkManager curl awk
```

Verify WireGuard support:

```bash
wg --version
nmcli --version
```

---

## 🔐 SELinux Reset (Important)

TorGuard often fails silently due to SELinux.

```bash
sudo setenforce 0
sudo setenforce 1
```

This clears blocked states and allows TorGuard helpers to register correctly.

---

## 📁 WireGuard Config Files

Download WireGuard `.conf` files from the TorGuard dashboard.

**IMPORTANT:** Each file must be named like:

```
servername.conf
```

Example:

```
torguard-us.conf
torguard-uk.conf
```

Create a directory:

```bash
mkdir -p ~/wireguard-confs
mv *.conf ~/wireguard-confs/
```

### 🔧 Required TorGuard Fix

Edit **each config** and add MTU:

```ini
[Interface]
MTU = 1420
```

Without this, connections often fail or hang.

---

## 🔗 Import WireGuard Configs into NetworkManager

Import manually (repeat for each file):

```bash
sudo nmcli connection import type wireguard file ~/wireguard-confs/torguard-us.conf
```

Verify:

```bash
nmcli connection show
```

Bring one up manually to test:

```bash
sudo nmcli connection up torguard-us
```

If this works, your configs are valid.

---

## 🧠 Why This Fixes the TorGuard GUI

Even if you plan to use the TorGuard GUI:

* NetworkManager must already understand WireGuard
* Valid WG profiles must exist
* SELinux must allow TorGuard helpers

Doing the above **fixes the backend** the GUI depends on.

---

## 📜 WireGuard CLI Menu Script

Create the script (or download [here](./wg-menu.sh/) ):

```bash
mkdir -p ~/bin
nano ~/bin/wg-menu.sh
```

Paste:

```bash
#!/usr/bin/env bash
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
```

Make executable:

```bash
chmod +x ~/bin/wg-menu.sh
```

Ensure `~/bin` is in PATH (Fedora default):

```bash
echo $PATH
```

---

## 🖥️ Optional: Desktop Popup Menu (KDE)

Create desktop entry:

```bash
mkdir -p ~/.local/share/applications
nano ~/.local/share/applications/wg-menu.desktop
```

```ini
[Desktop Entry]
Name=WireGuard Menu
Exec=konsole --noclose -e ~/bin/wg-menu.sh
Icon=network-vpn
Type=Application
Categories=Network;
Terminal=false
```

Now you can launch the menu from the KDE app launcher.

---

## 🟢 Final Result

* WireGuard works via CLI
* NetworkManager properly configured
* TorGuard GUI starts working again
* Easy server switching

---

## 📌 Notes

* TorGuard GUI depends heavily on NetworkManager state
* This process fixes underlying issues even if you use the GUI
* Fedora + VPN + SELinux requires manual care

---

## 🙏 Credits

Community troubleshooting + persistence.

If this helped you — feel free to share or contribute improvements.
