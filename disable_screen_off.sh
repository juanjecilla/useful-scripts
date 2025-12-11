shell name=disable_screen_off.sh url=https://github.com/juanjecilla/useful-scripts/blob/bdf38fc887396b1645d0247359cddf6e8e8832b1/disable_screen_off.sh
#!/usr/bin/env bash
set -euo pipefail

# disable_screen_off.sh
# - On X11: uses xset to disable DPMS and screen blanking
# - On GNOME (Wayland or X11): tries gsettings to disable idle/screen-blanking
# - Fallback: uses systemd-inhibit to block idle (run in background to keep it active)
#
# Usage: run this at session start (autostart) or run manually. If using systemd-inhibit
# as fallback the script will block indefinitely (so run it in background if you want it persistent).

info() { printf '%s\n' "$*"; }

# 1) Prefer xset if X11 is available
if command -v xset >/dev/null 2>&1 && [ -n "${DISPLAY-}" ]; then
  info "Using xset on DISPLAY=${DISPLAY} to disable DPMS and screen blanking..."
  if ! xset -dpms; then
    info "Warning: xset -dpms failed"
  fi
  if ! xset s noblank; then
    info "Warning: xset s noblank failed"
  fi
  if ! xset s off; then
    info "Warning: xset s off failed"
  fi
  info "Done (xset)."
  exit 0
fi

# 2) If gsettings is available (GNOME), try to adjust GNOME settings
if command -v gsettings >/dev/null 2>&1; then
  info "xset not usable; attempting GNOME gsettings changes..."
  # Set idle-delay to 0 (no automatic idle) — value is in seconds
  if gsettings writable org.gnome.desktop.session idle-delay >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.session idle-delay 0 || info "Warning: failed to set org.gnome.desktop.session idle-delay"
  fi
  # Disable screensaver activation
  if gsettings writable org.gnome.desktop.screensaver idle-activation-enabled >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.screensaver idle-activation-enabled false || info "Warning: failed to set org.gnome.desktop.screensaver idle-activation-enabled"
  fi
  info "Done (gsettings). Note: this affects GNOME settings and may be reset by user/policy."
  exit 0
fi

# 3) Fallback: systemd-inhibit (blocks idle while this process runs)
if command -v systemd-inhibit >/dev/null 2>&1; then
  info "No xset or gsettings available — falling back to systemd-inhibit."
  info "This will block idle while the command runs. Run it in background (eg: nohup) to keep it persistent."
  exec systemd-inhibit --what=idle --why="Keep screen on" --mode=block sleep infinity
fi

info "Unable to disable screen blanking: no supported method found (xset, gsettings, or systemd-inhibit)."
exit 2
