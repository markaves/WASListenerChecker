#!/usr/bin/ksh

#Title: WAS Listener Monitoring Script
#Description:  This script checs the WAS log files for listener ports status
#Created By:  Mark Neil C. Aves
#Version:
# 1.0  Initial Script

#Variables:
WRK_DIR='/usr/IBM/scripts/listener_monitoring'
LOG_DIR='/usr/IBM/WebSphere/AppServer/profiles/Custom01/logs/<appServerName>'

#Main:
now=`date '+%y%m%d%H%M'`

cd $LOG_DIR
if [[ -s $WRK_DIR/linenumber ]]
then
        linenumber=`cat /usr/IBM/scripts/listener_monitoring/linenumber`
else
        linenumber=1
fi

#Check Log last entry
if [[ -s $WRK_DIR/MDB_entries ]]
then
        mv $WRK_DIR/MDB_entries $WRK_DIR/MDB_entries.old
        output=`tail -1 /usr/IBM/scripts/listener_monitoring/MDB_entries.old | cut -d"[" -f2 | cut -d"]" -f1`; \
         grep "$output" /usr/IBM/WebSphere/AppServer/profiles/Custom01/logs/<appServerName>/SystemOut.log | grep -in "MDB Listener"
        flag=$?
        if [ $flag -eq 0 ]
        then
                linenumber=`tail -1 /usr/IBM/scripts/listener_monitoring/MDB_entries | cut -d":" -f1 `
                tail -1 $WRK_DIR/MDB_entries
                linenumber=$(($linenumber+1))
                echo $linenumber
        else
                linenumber=1
        fi
        echo $linenumber > $WRK_DIR/linenumber
fi
tail +$linenumber $LOG_DIR/SystemOut.log | grep -in 'MDB Listener' > $WRK_DIR/MDB_entries


##Check MDB_entries log for status of each listener
min=1
max=9

desc=""
error=0

while [ $min -lt $max ]
do
        line=`head -n $min $WRK_DIR/listener_list | tail -n 1 `
        grep $line $WRK_DIR/MDB_entries | tail -1 | grep stopped
        flagStop=$?

        #grep $line $WRK_DIR/MDB_entries | tail -1 | grep 'started successfully'
        #flagStart=$?

        if [ $flagStop -eq 0 ]
        then
                desc2=$line
                desc="$desc $desc2"
                error=1
        fi
        echo "$line $flag"
        min=`expr $min + 1`
done

if [ $error -eq 1 ]
then
        echo $now "Listener Offline" $desc >> $WRK_DIR/listener.log
fi

