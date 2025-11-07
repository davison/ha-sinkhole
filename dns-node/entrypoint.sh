#!/usr/bin/env bash

export LOCAL_DOMAIN=${LOCAL_DOMAIN:-_invalid.local}
export LOCAL_UPSTREAM_DNS=${LOCAL_UPSTREAM_DNS:-8.8.4.4}
export UPSTREAM_DNS=${UPSTREAM_DNS:-1.1.1.1 9.9.9.9}

if [ "$SINKHOLE_DEBUG" == "true" ]; then
    export CORE_RELOAD="reload 10s"
else
    export CORE_RELOAD="reload 1h"
fi

# 1. Run as ROOT: Substitute env vars and create final config
envsubst < /etc/coredns/Corefile.template > /etc/coredns/Corefile

# 2. Set correct ownership on the new config file
chown coredns:coredns /etc/coredns/Corefile

# 3. Drop privileges: Execute the original CMD (coredns -conf ...)
#    as the 'coredns' user.
exec su-exec coredns /usr/bin/coredns "$@"
