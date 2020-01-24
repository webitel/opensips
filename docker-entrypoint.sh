#!/bin/bash

touch /var/log/opensips.log
echo "local0.*  /var/log/opensips.log" >>/etc/rsyslog.conf

# Starting OpenSIPS process
if [ "$1" = 'opensips' ]; then
    /opensips/sbin/opensips -E
    rsyslogd -n
    tail -f /var/log/opensips.log
fi

exec "$@"
