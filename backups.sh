#!/bin/bash

# locks: https://stackoverflow.com/questions/185451/quick-and-dirty-way-to-ensure-only-one-instance-of-a-shell-script-is-running-at

(
  # Wait for lock on fd 200 for max 3 seconds - if fail then exit
  flock -x -w 3 200 || exit 124

echo "got exclusive lock - starting script..."
# Do stuff
sleep 10

source /pgenv.sh

#echo "Running with these environment options" >> /var/log/cron.log
#set | grep PG >> /var/log/cron.log

MYDATE=`date +%d-%B-%Y`
MONTH=$(date +%B)
YEAR=$(date +%Y)
MYBASEDIR=/backups
MYBACKUPDIR=${MYBASEDIR}/${YEAR}/${MONTH}
mkdir -p ${MYBACKUPDIR}
cd ${MYBACKUPDIR}

echo "Backup running to $MYBACKUPDIR" >> /var/log/cron.log

#
# Loop through each pg database backing it up
#

DBLIST=`psql -l | awk '{print $1}' | grep -v "+" | grep -v "Name" | grep -v "List" | grep -v "(" | grep -v "template" | grep -v "postgres" | grep -v "|" | grep -v ":"`
# echo "Databases to backup: ${DBLIST}" >> /var/log/cron.log
for DB in ${DBLIST}
do
  echo "Backing up $DB"  >> /var/log/cron.log
  FILENAME=${MYBACKUPDIR}/${DUMPPREFIX}_${DB}.${MYDATE}.dmp
  pg_dump -Fc -f ${FILENAME} -x -O ${DB}
done

) 200>/var/lock/.backups.exclusivelock
