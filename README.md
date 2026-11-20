# bootc-experiments-rpi5

[hummingbird-rpi5](https://github.com/iamyaash/hummingbird-rpi5) with scout, applier and opencode added.

## Build

Needs an arm64 host with podman. The binaries aren't in git, so put them in `bin/` first:

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
