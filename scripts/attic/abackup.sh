#!/bin/sh

# usage: abackup <repostitory folder> <attic name> <json file> <custom tag>
# param 1: repository folder
# param 2: attic name
# param 3: json file
# param 4: custom backup tag

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

REPO_HOME=$1
REPO_NAME=$2
BACKUP_TAG=""
JSON_FILE=$1/confs/$3

# Set BACKIP_TAG if exist
if [ "$4" != "" ]; then
    BACKUP_TAG=$4
fi

# Read variables from JSON config file
SERVER_NAME=`jq '.name' $JSON_FILE | sed -e 's/^"//'  -e 's/"$//'`
SERVER_IP=`jq '.ip' $JSON_FILE | sed -e 's/^"//'  -e 's/"$//'`
SERVER_USER=`jq '.user' $JSON_FILE | sed -e 's/^"//'  -e 's/"$//'`
SERVER_STATUS=`jq '.status' $JSON_FILE | sed -e 's/^"//'  -e 's/"$//'`

# Log variables
LOG_TIME="`date +%Y-%m-%d\ %H:%M`"
LOG_FILE="$REPO_HOME/logs/$SERVER_NAME-`date +%Y%m%d-%H%M`.log"

echo "$LOG_TIME Iniciando programa" > $LOG_FILE

# Exit if last integrity check failed
if [ ! -f $REPO_HOME/status_ok ]; then
    echo "$LOG_TIME Integridad FAIL" >> $LOG_FILE
    exit 1
fi

echo "$LOG_TIME Integridad OK" >> $LOG_FILE

# Exit if last backup failed
if [ "$SERVER_STATUS" != "ok" ]; then
    echo "$LOG_TIME Ultimo respaldo FAIL" >> $LOG_FILE
    exit 2
fi

echo "$LOG_TIME Ultimo respaldo OK" >> $LOG_FILE

echo "$LOG_TIME Ejecutando respaldo remoto" >> $LOG_FILE
# Execute remote backup
ssh $SERVER_USER@$SERVER_IP 'sudo /mnt/nfs/lnxconfs/attic.sh $BACKUP_TAG'

echo "$LOG_TIME Copiando log remoto" >> $LOG_FILE
# Copy to local server remote log
scp $SERVER_USER@$SERVER_IP:/tmp/last_backup.log /tmp/last_backup.log >> $LOG_FILE

grep "Resultado 0" /tmp/last_backup.log > /dev/null
retval=$?
if [ "$retval" -ne 0 ]; then
    sed  -i 's/"status": "ok"/"status": "fail"/' $JSON_FILE
    echo
fi

cat /tmp/last_backup.log >> $LOG_FILE

echo "$LOG_TIME Eliminando logs viejos" >> $LOG_FILE
# Remove old log files - Keep only 30 days
find $REPO_HOME/logs/* -mtime +30 -exec rm {} \;

echo "$LOG_TIME Comprobando integridad del repositorio" >> $LOG_FILE
# Check attic repository integrity
attic check $REPO_HOME/$REPO_NAME >> $LOG_FILE
retval=$?

# Remove status_ok flag if repository check fail
if [ "$retval" -ne 0 ]; then
    echo "$LOG_TIME Resultado FAIL" >> $LOG_FILE
    rm -f $REPO_HOME/status_ok
    exit 1
fi

date > $REPO_HOME/status_ok

echo "$LOG_TIME Resultado OK. Terminando programa." >> $LOG_FILE

# Create link to last back log
ln -sf $LOG_FILE $REPO_HOME/logs/$SERVER_NAME.last

exit 0