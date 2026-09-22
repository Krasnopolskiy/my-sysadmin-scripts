# my-sysadmin-scripts

`script.sh` appends `free -h`, `df -h` and `uptime` to `monitor.log` every 5 seconds.

```bash
./script.sh      # loop until Ctrl+C
./script.sh 3    # 3 snapshots, then exit
```

Edit the `INTERVAL=5` constant to change the period. Set `MONITOR_LOG` to write somewhere else.

Exit codes: `1` missing tool, `2` bad argument, `3` log not writable.

See `sample_output.txt` for a full run.

## Container

```bash
docker build -t my-script .
docker run -d -p 8080:8080 --name my-app my-script
curl http://127.0.0.1:8080/monitor.log
```

`script.sh` lives at `/var/www/script.sh` in the image. It writes `monitor.log` into `/var/www`,
and `python3 -m http.server 8080` serves that directory directly. Variant B needs no volume: it
only reads `/proc`, `free` and `df`, never host `/var/log`.

Nginx terminates TLS and reverse-proxies to the container. A `my-app.service` systemd unit
(`ExecStart=docker start -a my-app`, `Requires=docker.service`) keeps it running.
