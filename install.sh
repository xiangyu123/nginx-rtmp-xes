#!/bin/bash
# configure 
echo 'start install nginx.initing...'
export CFLAGS=""
export LIBS=""
cd LuaJIT-2.0.3
make clean
make
make install
export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.0
cd ../nginx-1.6.2
make clean
echo 'configure...'
sleep 2
./auto/configure  --prefix=/usr/local/nginx --with-http_flv_module --with-http_mp4_module --with-pcre=../pcre-8.31 --with-ld-opt=-Wl,-rpath,/usr/local/lib --with-http_stub_status_module --add-module=../lua-nginx-module-0.9.10 --add-module=../nginx-rtmp-module-master --with-file-aio && make && make install
if [ $? != '0' ] ; then
	echo 'nginx compile failed!exit ...'
	exit 1
fi
echo 'nginx compile success.'
cd ..
sleep 2
echo "================= compile complete ======================"

mkdir -p /etc/ChinaCache/app.d
mkdir -p /var/log/nginx
mkdir -p /data/proclog/log/nginx

cp -f np.amr /etc/ChinaCache/app.d/
cp -f nginx.sh /etc/init.d/
cp -f nginx-monitor.sh nginx-log.sh /usr/local/nginx/sbin/
cp -f nginx.conf sites mime.types  /usr/local/nginx/conf/
cp -f stat.xsl logo.jpg /usr/local/nginx/html/

# crontab
sed -i '/nginx-monitor/d' /var/spool/cron/root
sed -i '/ntpdate/d' /var/spool/cron/root
sed -i '/nginx-log/d' /var/spool/cron/root

echo '*/5 * * * * /usr/local/nginx/sbin/nginx-monitor.sh &> /dev/null' >> /var/spool/cron/root
echo '*/10 * * * * /usr/local/nginx/sbin/nginx-log.sh &> /dev/null' >> /var/spool/cron/root
echo '*/30 * * * * /usr/sbin/ntpdate -u -t 5 ntp.chinacache.com &> /dev/null' >> /var/spool/cron/root
echo 'nameserver 8.8.8.8' > /etc/resolv.conf

/etc/init.d/crond restart

sed -i '/nginx/d' /etc/rc.local
sed -i '/apache/d' /etc/rc.local
sed -i '/ulimit/d' /etc/rc.local
echo 'ulimit -HSn 348160' >> /etc/rc.local
echo '/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf' >> /etc/rc.local

echo 'nginx install success.'
ulimit -HSn 348160
/usr/local/nginx/sbin/nginx
