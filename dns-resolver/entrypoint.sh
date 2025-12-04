#!/usr/bin/env bash

export LOCAL_DOMAIN=${LOCAL_DOMAIN:-_invalid.local}
export LOCAL_UPSTREAM_DNS=${LOCAL_UPSTREAM_DNS:-8.8.4.4}
export UPSTREAM_DNS=${UPSTREAM_DNS:-1.1.1.1 9.9.9.9}
export TRUSTED_NETS=${TRUSTED_NETS:-192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 169.254.1.2/32}

if [ "$SINKHOLE_DEBUG" == "true" ]; then
    export RELOAD_INTERVAL="10s"
    export TTL_DURATION="5"
    export CACHE_DURATION="10"
else
    export RELOAD_INTERVAL="10m"
    export TTL_DURATION="900"
    export CACHE_DURATION="3600"
fi

# 1. Run as ROOT: Substitute env vars and create final config
envsubst < /etc/coredns/Corefile.template > /etc/coredns/Corefile

# 2. Set correct ownership on the new config file
chown coredns:coredns /etc/coredns/Corefile

# 3. Drop privileges: Execute the original CMD (coredns -conf ...)
#    as the 'coredns' user.
exec su-exec coredns /usr/bin/coredns "$@"
