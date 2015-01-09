#!/bin/bash
echo 'stop nginx...'
sleep 2
killall -9 nginx
rm -rf /usr/local/nginx
rm -rf /var/log/nginx
rm -rf /data/proclog/log/nginx

# crontab
sed -i '/nginx-monitor/d'  /var/spool/cron/root
sed -i '/nginx-log/d'  /var/spool/cron/root
/etc/init.d/crond restart

sed -i '/nginx/d' /etc/rc.local
sed -i '/apache/d' /etc/rc.local
sed -i '/ulimit/d' /etc/rc.local
echo 'ulimit -HSn 348160' >> /etc/rc.local
rm -f /etc/ChinaCache/app.d/np.amr
echo 'nginx uninsatll success.'
