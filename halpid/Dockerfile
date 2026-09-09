ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG HALPID_VERSION=5.1.1-1
ARG HALPID_SHA256=1329c34d9f177e22c2c3ecbcaee03f8499d04ccefc36fcfc26a0d50de5617342

# halpid ships as a statically linked aarch64 binary, so the Debian package
# only has to be unpacked, not installed.
RUN \
    apk add --no-cache --virtual .build-deps binutils \
    && curl -fsSL -o /tmp/halpid.deb \
        "https://apt.hatlabs.fi/pool/stable/main/halpid_${HALPID_VERSION}_arm64.deb" \
    && echo "${HALPID_SHA256}  /tmp/halpid.deb" | sha256sum -c - \
    && cd /tmp \
    && ar x halpid.deb \
    && tar -xJf data.tar.xz -C / ./usr/bin/halpid ./usr/bin/halpi \
    && rm -f /tmp/halpid.deb /tmp/data.tar.xz /tmp/control.tar.xz /tmp/debian-binary \
    && apk del .build-deps \
    && apk add --no-cache mosquitto-clients \
    && addgroup -S -g 960 halpid \
    && mkdir -p /etc/halpid

COPY rootfs /
COPY run.sh /run.sh
COPY ha-poweroff /usr/bin/ha-poweroff
RUN chmod a+x /run.sh /usr/bin/ha-poweroff /etc/services.d/halpid-mqtt/run

CMD [ "/run.sh" ]
