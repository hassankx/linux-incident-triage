# Linux Incident Triage

A safe collection script for first-response Linux troubleshooting. It captures a timestamped report of common operating-system signals without modifying the host.

## Usage

```bash
chmod +x collect_triage.sh
./collect_triage.sh
```

The report is saved in the current directory. Inspect it before sharing externally because it may contain host and network information.
