#!/usr/bin/env bash
# Creates a local, read-only triage report.
set -euo pipefail

report="linux-triage-$(hostname)-$(date +%Y%m%d-%H%M%S).txt"

{
  echo "Linux Incident Triage"
  echo "Collected: $(date -Is)"
  echo
  echo "===== HOST ====="
  hostnamectl 2>/dev/null || hostname
  uname -a
  echo
  echo "===== UPTIME ====="
  uptime
  echo
  echo "===== FAILED SERVICES ====="
  systemctl --failed --no-pager 2>/dev/null || true
  echo
  echo "===== DISK ====="
  df -hT 2>/dev/null || df -h
  echo
  echo "===== MEMORY ====="
  free -h 2>/dev/null || true
  echo
  echo "===== RECENT SYSTEM ERRORS ====="
  journalctl -p err..alert -n 50 --no-pager 2>/dev/null || true
  echo
  echo "===== NETWORK ====="
  ip addr 2>/dev/null || true
  ip route 2>/dev/null || true
} > "$report"

echo "Created: $report"
