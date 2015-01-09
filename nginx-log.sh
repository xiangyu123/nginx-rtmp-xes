#!/bin/bash
log_path="/var/log/nginx/"
log_bak="/data/proclog/log/nginx/"
pid="/var/run/nginx.pid"
D=30
date=`date +%Y%m%d`
time=`date +%Y%m%d%H%M%S`
old_date=`date -d "${D}day ago" +%Y%m%d`
sn=`cat /sn.txt`
hname=`hostname`
log_type="access rtmpaccess error"
old_log=$log_bak$old_date
mkdir -p ${log_bak}${date}
for i in $log_type
do
	logbak="${log_bak}${date}/np-$i.log.$sn.$hname.$time.log"
	log="${log_path}$i.log"
	mv $log $logbak
done
kill -USR1 `cat $pid`
cd $log_bak$date
gzip *.log
[ -e $old_log ] && rm -rf $old_log
