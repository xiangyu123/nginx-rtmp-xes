#!/bin/bash

LOG="/usr/local/nginx/logs/nginx_running.log"
PID="/var/run/nginx.pid"
DATE=`date +%Y%m%d`
D=15
OLD_DATE=`date -d "${D}day ago" +%Y%m%d`
#service squid status > /dev/null  2>&1
        if [ ! -e $PID ]; then
                killall nginx > /dev/null 2>&1
                echo `date` >> $LOG
                echo "Nginx pid lost,restart nginx now!" >> $LOG
                sleep 2
                /usr/local/nginx/sbin/nginx
                if [ $? -eq 0 ];then
                        echo "Nginx restart success" >> $LOG
                else
                        echo "Nginx restart falied" >> $LOG
                fi
        fi

        ps -ef | grep -v grep | grep -q /usr/local/nginx/sbin/nginx

        if [ $? -ne 0 ] ;then
                killall nginx > /dev/null 2>&1
                echo `date` >> $LOG
                echo 'Nginx process stopped,restart nginx now!' >> $LOG
                rm -f /usr/local/nginx/logs/nginx.pid
                sleep 2
                /usr/local/nginx/sbin/nginx
                if [ $? -eq 0 ];then
                        echo "Nginx restart success." >> $LOG
                else
                        echo "Nginx restart falied." >> $LOG
                fi
        fi

DAY_END=`date +%H%M`
if [ ${DAY_END} == "0000" ] ; then
        touch ${LOG}
        [ -e ${LOG}_${DATE} ] && rm -f ${LOG}_${DATE}
        mv ${LOG} ${LOG}_${DATE}
        [ -e ${LOG}_${OLD_DATE} ] && rm -f ${LOG}_${OLD_DATE}
        touch ${LOG}
fi
