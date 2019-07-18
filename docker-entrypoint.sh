#!/bin/bash
# OpenSIPS Docker bootstrap

export PRIVATE0_IPV4="${PRIVATE_IPV4:-$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)}"
export PRIVATE1_IPV4="${PRIVATE_IPV4:-$(ip addr show eth1 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)}"
#export PUBLIC_IPV4="$(curl --fail -qs whatismyip.akamai.com)"
export HOSTNAME=$(hostname)

sed -i 's/PRIVATE_IPV4/'$PRIVATE1_IPV4'/g' /opensips/etc/opensips/opensips.cfg

if [ "$CONSUL" ]; then
        curl --request PUT http://$CONSUL:8500/v1/agent/service/register -d '
        {
          "ID": "'$HOSTNAME'",
          "Name": "opensips",
          "Tags": [
            "opensips"
          ],
          "Address": "'$PRIVATE0_IPV4'",
          "Port": 5060
        }
        '
fi

# Starting OpenSIPS process
/opensips/sbin/opensips -E

rsyslogd -n
