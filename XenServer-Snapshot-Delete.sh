#!/bin/bash

TMP_FILE=/tmp/XenServer-Snapshot-Delete-tmp.txt
DAYS_TO_KEEP="30"
LOG="/var/log/XenServer-Snapshot-Delete.log"
TEST_RUN="NO" # Set to YES or NO

###########################################
shopt -s nocasematch
SECONDS=0
echo "XenServer-Snapshot-Delete:: Script Start -- $(date +%Y%m%d_%H%M)" >> $LOG

xe snapshot-list params=uuid,name-label,name-description,snapshot-time > $TMP_FILE

if [ ! -f $TMP_FILE ]; then
  echo "$TMP_FILE not found!\n"
  exit 0
fi

DAYS_AGO=$(date -d "now - $DAYS_TO_KEEP days" +%s)

while IFS= read LINE
do
        if [[ $LINE == uuid* ]]; then
                SNAPUUID=$(echo $LINE | grep uuid | cut -d":" -f2| tr -d '[:space:]')
                ##printf '%s,' "$SNAPUUID"
                # Read the next line which should be name-label
                read LINE
                SNAPLABEL=$(echo $LINE | grep name-label | cut -d":" -f2| tr -d '[:space:]')
                # Read the next line which should be name-description
                read LINE
                SNAPDESCRIPTION=$(echo $LINE | grep name-description | cut -d":" -f2| tr -d '[:space:]')
                # Read the next line which should be snapshot-time
                read LINE
                SNAPTIME=$(echo $LINE | grep snapshot-time | cut -d":" -f2|cut -c2-9)
                ##printf '%s\n' "$SNAPTIME"
                SNAPTIME_SECS=$(date -d $SNAPTIME +%s)
		if (( $SNAPTIME_SECS <= $DAYS_AGO )); then
                        ##echo "UUID->$SNAPUUID,snapshot-time->$SNAPTIME,name-label->$SNAPLABEL,name-description->$SNAPDESCRIPTION -> OLDER"
			if [[ $TEST_RUN == "YES" ]]; then
	                        echo "TEST RUN - FOUND BUT NOT DELETING -> ->$SNAPUUID" >> $LOG
			else
                                echo "DELETING UUID->$SNAPUUID" >> $LOG
				xe snapshot-uninstall force=true uuid=$SNAPUUID
			fi
                        	echo " snapshot-time->$SNAPTIME" >> $LOG
	                        echo " name-label->$SNAPLABEL" >> $LOG
        	                echo " name-description->$SNAPDESCRIPTION" >> $LOG
                else
                        : #
                        ##echo "UUID->$SNAPUUID,snapshot-time->$SNAPTIME,name-label->$SNAPLABEL,name-description->$SNAPDESCRIPTION -> yonger"
                fi
        fi
done < $TMP_FILE

echo "XenServer-Snapshot-Delete :: Script End -- $(date +%Y%m%d_%H%M)" >> $LOG
echo "Elapsed Time :: $(($SECONDS / 3600))h:$((($SECONDS / 60) % 60))m:$(($SECONDS % 60))s" >> $LOG
echo "" >> $LOG
