#!/bin/bash

SERVER_IP="$1"
SERVER_PORT="3309"

HTTP_STATUS=$(/usr/bin/curl -s http://${SERVER_IP}:${SERVER_PORT} -o /dev/null -w '%{http_code}\n')

if [ "${HTTP_STATUS}" = "200" ]
then
  /bin/echo -e "Check OK"
elif [ "${HTTP_STATUS}" = "000" ]
then
  /bin/echo -e "Check NG unknown error ip=${SERVER_IP}"
else
  /bin/echo -e "Check NG ip=${SERVER_IP} http_status=${HTTP_STATUS}"
fi
