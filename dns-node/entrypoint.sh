#!/usr/bin/env bash

#set -x

# 1. Run as ROOT: Substitute env vars and create final config
envsubst < /etc/coredns/Corefile.template > /etc/coredns/Corefile

# 2. Set correct ownership on the new config file
chown coredns:coredns /etc/coredns/Corefile

# 3. Drop privileges: Execute the original CMD (coredns -conf ...)
#    as the 'coredns' user.
which coredns
exec su-exec coredns /usr/bin/coredns "$@"
