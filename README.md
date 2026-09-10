# my-sysadmin-scripts

`script.sh` appends `free -h`, `df -h` and `uptime` to `monitor.log` every 5 seconds.

```bash
./script.sh      # loop until Ctrl+C
./script.sh 3    # 3 snapshots, then exit
```

Edit the `INTERVAL=5` constant to change the period. Set `MONITOR_LOG` to write somewhere else.

Exit codes: `1` missing tool, `2` bad argument, `3` log not writable.

See `sample_output.txt` for a full run.
