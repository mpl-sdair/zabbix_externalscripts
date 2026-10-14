#!/bin/bash

MYSQL_HOSTIP="$1"
MYSQL_PORT="3306"
MYSQL_USERNAME="gr_healthcheck"

GR_STATE=$(mysql -u${MYSQL_USERNAME} -h ${MYSQL_HOSTIP} -P ${MYSQL_PORT} --ssl-mode=DISABLED -BN -e "SELECT MEMBER_STATE FROM performance_schema.replication_group_members where MEMBER_HOST = '${MYSQL_HOSTIP}';" --connect-timeout=5 2>/dev/null)

if [ "${GR_STATE}" = "ONLINE" ]
then
  /bin/echo -e "Check OK"
elif [ "${GR_STATE}" = "" ]
then
  /bin/echo -e "Check NG no state mysql_ip=${MYSQL_HOSTIP}"
else
  /bin/echo -e "Check NG state mysql_ip=${MYSQL_HOSTIP} gr_status=${GR_STATE}"
fi
