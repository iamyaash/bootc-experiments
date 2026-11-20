# bootc-experiments-rpi5

[hummingbird-rpi5](https://github.com/iamyaash/hummingbird-rpi5) with scout, applier and opencode added.

## Build

### Where the binaries live

scout and applier are about 130 MB each. Committing them would mean every clone drags a quarter gigabyte of history around forever, and git would quietly judge us. So they live in the [`binaries` release](../../releases/tag/binaries) instead. Releases hold big files for free and stay out of the history.

The build workflow downloads them from that release. To ship new builds, replace the assets there:

```
gh release upload binaries bin/scout-linux-arm64 bin/applier-linux-arm64 --clobber
```

### In CI

Go to Actions, pick "Build image", and click "Run workflow". Nothing builds unless you ask. The run pushes `ghcr.io/iamyaash/bootc-experiments-rpi5` and leaves a flashable SD image under the run's artifacts.

### Locally

Needs an arm64 host with podman. Grab the binaries from the release into `bin/` first:

```
bin/scout-linux-arm64
bin/applier-linux-arm64
```

Then:

```
git clone https://github.com/iamyaash/hummingbird-rpi5 ../hummingbird-rpi5
scripts/build.sh
```

Flash `bootc-experiments-rpi5.raw` the same way as hummingbird-rpi5.

## What's added

- `/usr/bin/scout`, `/usr/bin/applier`, `/usr/bin/opencode`
- `scout.service` (port 4545) and `applier.service`, enabled, running as `hummingbird`
- `/etc/profile.d/jobwish.sh` sets `JOBWISH_DATA` and `APPLIER_DATA` for login shells

Data lives under `/home/hummingbird/.local/share/` (`jobwish` and `jobwish-applier`), which is in `/var` and kept across upgrades.
