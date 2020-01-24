#!/bin/bash
# OpenSIPS Docker bootstrap

export ETH0_IPV4="${PRIVATE_IPV4:-$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)}"
#export ETH1_IPV4="${PRIVATE_IPV4:-$(ip addr show eth1 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)}"
#export PUBLIC_IPV4="$(curl --fail -qs whatismyip.akamai.com)"
export HOSTNAME=$(hostname)

#sed -i 's/PRIVATE_IPV4/'$ETH1_IPV4'/g' /opensips/etc/opensips/opensips.cfg

if [ "$CONSUL" ]; then
        curl -qs -XPUT http://$CONSUL:8500/v1/agent/service/register -d '
        {
          "ID": "'$HOSTNAME'",
          "Name": "opensips",
          "Tags": [
            "opensips",
            "sip"
          ],
          "Address": "'$ETH0_IPV4'",
          "Port": 5060
        }
        '
fi

# Starting OpenSIPS process
if [ "$1" = 'opensips' ]; then
    /opensips/sbin/opensips -E
    rsyslogd -n
fi

exec "$@"
