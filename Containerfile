# hummingbird-rpi5 with scout, applier and opencode on top.
# Pinned by digest. Bump the tag and digest together.
ARG BASE_IMAGE=ghcr.io/iamyaash/hummingbird-rpi5:unstable@sha256:ba63af813f1fcd33c0452744446b03500a96f36ce39517ab7020b227baa890f3

# scout and applier use @opencode/client 2.x, which runs `opencode serve --service`.
# opencode 1.x has no --service flag, so keep this on 2.x.
ARG OPENCODE_VERSION=2.3.2
ARG OPENCODE_SHA256=9d10185acdb72336e086e699ca363a6065f410fd3c1caed0dc8046e95ac06ccb

FROM registry.fedoraproject.org/fedora:44 AS opencode
ARG OPENCODE_VERSION
ARG OPENCODE_SHA256
RUN set -eux; \
    curl -fsSL -o /tmp/opencode.tar.gz \
      "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-arm64.tar.gz"; \
    echo "${OPENCODE_SHA256}  /tmp/opencode.tar.gz" | sha256sum -c -; \
    mkdir -p /out; tar -xzf /tmp/opencode.tar.gz -C /out opencode; \
    test -x /out/opencode

FROM ${BASE_IMAGE}

# /usr/local is a link into /var on bootc, so anything put there at build time
# doesn't ship. Install to /usr/bin instead.
COPY --chmod=0755 bin/scout-linux-arm64 /usr/bin/scout
COPY --chmod=0755 bin/applier-linux-arm64 /usr/bin/applier
COPY --from=opencode --chmod=0755 /out/opencode /usr/bin/opencode

COPY files/usr/lib/systemd/system/ /usr/lib/systemd/system/
COPY files/usr/lib/systemd/system-preset/80-jobwish.preset /usr/lib/systemd/system-preset/
COPY files/etc/profile.d/jobwish.sh /etc/profile.d/

# Open scout's UI port to the LAN. firewall-offline-cmd writes /etc/firewalld/zones/,
# which becomes the image default for /etc.
COPY files/usr/lib/firewalld/services/jobwish-scout.xml /usr/lib/firewalld/services/
RUN firewall-offline-cmd --zone=public --add-service=jobwish-scout \
    && firewall-offline-cmd --zone=public --list-services | grep -qw jobwish-scout

RUN systemctl preset scout.service applier.service \
    && systemctl is-enabled scout.service applier.service

RUN bootc container lint --fatal-warnings
