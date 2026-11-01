#!/usr/bin/env bash
# collect_triage.sh - read-only first-response evidence collection for Linux.
#
# Captures a timestamped snapshot of the signals you usually need in the
# first minutes of an incident, so the evidence survives a reboot or a fix.
# Nothing on the host is changed.
#
# Usage: ./collect_triage.sh [output-directory]
set -uo pipefail

outdir="${1:-.}"
mkdir -p "$outdir"
report="${outdir}/linux-triage-$(hostname -s)-$(date +%Y%m%d-%H%M%S).txt"

section() { printf '\n===== %s =====\n' "$1"; }
run() {
  # Print the command, then its output; never stop the collection on failure.
  printf '$ %s\n' "$*"
  "$@" 2>&1 || printf '(command failed or not available: %s)\n' "$1"
}
have() { command -v "$1" >/dev/null 2>&1; }

{
  echo "Linux Incident Triage"
  echo "Collected: $(date -Is)"
  echo "Collected by: $(id -un) (uid $(id -u))"
  [[ $(id -u) -ne 0 ]] && echo "Note: not running as root, so some sections may be incomplete."

  section "HOST"
  if have hostnamectl; then run hostnamectl; else run hostname; fi
  run uname -a
  run uptime
  have last && run last -x -n 10 reboot shutdown

  section "CPU AND LOAD"
  run cat /proc/loadavg
  have vmstat && run vmstat 1 5
  echo
  echo "Top processes by CPU:"
  ps -eo pid,ppid,user,%cpu,%mem,stat,etime,cmd --sort=-%cpu 2>/dev/null | head -15

  section "MEMORY"
  run free -h
  echo
  echo "Top processes by memory:"
  ps -eo pid,user,%mem,rss,cmd --sort=-rss 2>/dev/null | head -10
  echo
  echo "OOM killer events (kernel log):"
  if have journalctl; then
    journalctl -k --no-pager -q 2>/dev/null | grep -iE 'out of memory|oom-kill|killed process' | tail -20
  else
    dmesg 2>/dev/null | grep -iE 'out of memory|oom-kill|killed process' | tail -20
  fi

  section "DISK"
  if df -hT >/dev/null 2>&1; then run df -hT; else run df -h; fi
  run df -hi
  have iostat && run iostat -xz 1 3
  echo
  echo "Processes in uninterruptible sleep (D state), often waiting on storage:"
  ps -eo pid,stat,wchan:32,cmd 2>/dev/null | awk 'NR == 1 || $2 ~ /^D/'

  section "SERVICES"
  if have systemctl; then
    run systemctl --failed --no-pager
  fi

  section "RECENT ERRORS"
  if have journalctl; then
    run journalctl -p err..alert --since "-2 hours" -n 100 --no-pager
  else
    for f in /var/log/messages /var/log/syslog; do
      [[ -r "$f" ]] && { echo "--- $f"; tail -100 "$f"; }
    done
  fi
  echo
  echo "Kernel ring buffer (last 50 lines):"
  dmesg -T 2>/dev/null | tail -50 || echo "(dmesg not readable as this user)"

  section "NETWORK"
  run ip -brief addr
  run ip route
  have ss && run ss -s
  have ss && run ss -tulpn
  [[ -r /etc/resolv.conf ]] && run grep -E '^(nameserver|search)' /etc/resolv.conf

  section "LOGINS"
  have who && run who
  have last && run last -n 20

  section "RECENT PACKAGE CHANGES"
  if [[ -r /var/log/dnf.log ]]; then
    tail -30 /var/log/dnf.log
  elif [[ -r /var/log/yum.log ]]; then
    tail -30 /var/log/yum.log
  elif [[ -r /var/log/dpkg.log ]]; then
    grep -E ' (install|upgrade|remove) ' /var/log/dpkg.log | tail -30
  else
    echo "No package log found."
  fi
} > "$report" 2>&1

echo "Created: $report"
echo "Review it before sharing: it contains host names, addresses and user names."
