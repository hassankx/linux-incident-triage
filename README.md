[🌌 View the black-and-Milky-Way themed page](index.html) · [Open HTML source](https://github.com/hassankx/linux-incident-triage/blob/main/index.html)

> GitHub README pages use GitHub's own theme. Download `index.html` and open it in a browser to see the full starfield design.

# Linux Incident Triage

A read-only evidence collector for the first minutes of a Linux incident. It saves a timestamped snapshot of the host before anyone restarts a service or reboots, so the root-cause analysis has something to work from.

Nothing on the host is changed.

## What it collects

| Section | Contents |
| --- | --- |
| Host | Hostname, kernel, uptime, recent reboots and shutdowns |
| CPU and load | Load average, `vmstat` samples, top processes by CPU |
| Memory | `free`, top processes by resident memory, OOM-killer events |
| Disk | Space and inode use, `iostat` samples, processes stuck in D state |
| Services | Failed systemd units |
| Recent errors | Error-level journal entries from the last two hours, tail of the kernel ring buffer |
| Network | Addresses, routes, socket summary, listening ports, DNS configuration |
| Logins | Current sessions and recent logins |
| Package changes | Recent `dnf`, `yum` or `dpkg` activity, since a recent update is often the cause |

Each command is printed above its output, and a failed or missing command is noted instead of stopping the run.

## Usage

```bash
chmod +x collect_triage.sh
./collect_triage.sh                 # report in the current directory
sudo ./collect_triage.sh /var/tmp   # fuller report, written to /var/tmp
```

Running as root fills in the sections that need it (listening process names, the kernel log, `last`).

## Before you share the report

The report contains host names, IP addresses, user names and process command lines. Review it, and redact what you need to, before attaching it to a ticket or sending it outside your organization.

## License

MIT
