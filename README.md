# bootc-experiments-rpi5

[hummingbird-rpi5](https://github.com/iamyaash/hummingbird-rpi5) with scout and opencode added. The applier is not in the image: it drives a real browser, so it runs on a machine with a display and talks to scout over the network.

## Build

### Where the binaries live

scout is about 130 MB. Committing it would mean every clone drags that of history around forever, and git would quietly judge us. So it lives in the [`binaries` release](../../releases/tag/binaries) instead. Releases hold big files for free and stay out of the history.

The build workflow downloads it from that release. Every scout build has the same file name and reports version `0.1.0`, so `scout.sha256` in this repo pins the exact build. CI, the image build and `scripts/build.sh` all fail if the binary doesn't match it.

To ship a new scout build, run:

```
scripts/release.sh   # defaults to ../../gitlab/jobwish/dist/scout-linux-arm64
```

It copies the binary to `bin/`, commits the new checksum, uploads the asset, runs the build and checks that `:unstable` on GHCR has that exact scout. On the Pi, `sha256sum /usr/bin/scout` or `cat /usr/share/jobwish/scout.sha256` shows which build is running.

### In CI

Go to Actions, pick "Build image", and click "Run workflow". Nothing builds unless you ask. The run pushes `ghcr.io/iamyaash/bootc-experiments-rpi5` and leaves a flashable SD image under the run's artifacts.

### Locally

Needs an arm64 host with podman. Grab the binary from the release into `bin/` first:

```
bin/scout-linux-arm64
```

Then:

```
git clone https://github.com/iamyaash/hummingbird-rpi5 ../hummingbird-rpi5
scripts/build.sh
```

Flash `bootc-experiments-rpi5.raw` the same way as hummingbird-rpi5.

## What's added

- `/usr/bin/scout`, `/usr/bin/opencode` (scout uses it for scoring and tailoring)
- `scout.service` on port 4545, enabled, running as `hummingbird`, restarted whenever it exits
- port 4545 open in firewalld's public zone
- `/etc/profile.d/jobwish.sh` sets `JOBWISH_DATA` for login shells

Data lives under `/home/hummingbird/.local/share/jobwish`, which is in `/var` and kept across upgrades.

## Running the applier on another machine

The applier polls scout over HTTP for queued jobs and opens the browser locally. Point it at the Pi:

```
applier doctor --server http://<pi-address>:4545
applier run --server http://<pi-address>:4545
```

Or put it in `~/.local/share/jobwish-applier/applier.yaml` so plain `applier run` works:

```yaml
server: http://<pi-address>:4545
token: <same token scout uses>
```

`SCOUT_URL` and `SCOUT_TOKEN` env vars work too. Since scout listens on the LAN, set a token on it (`server.token` in its config, or `SCOUT_TOKEN` via `systemctl edit scout`), otherwise anyone on the network can use it.
