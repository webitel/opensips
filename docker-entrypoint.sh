#!/bin/bash
# OpenSIPS Docker bootstrap

export PRIVATE_IPV4="${PRIVATE_IPV4:-$(ip addr show eth1 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)}"
#export PUBLIC_IPV4="$(curl --fail -qs whatismyip.akamai.com)"

sed -i 's/PRIVATE_IPV4/'$PRIVATE_IPV4'/g' /opensips/etc/opensips/opensips.cfg

# Starting OpenSIPS process
/opensips/sbin/opensips -E

rsyslogd -n
