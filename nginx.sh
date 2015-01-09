#!/bin/bash
if [ "$1" == "start" ]
then
	ulimit -HSn 348160
	/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
	[ "$?" -eq "0" ] && echo "nginx start success!"|| echo "nginx start fail !"
	exit 0
fi

if [ "$1" == "stop" ]
then
	killall -9 nginx
	echo "nginx stopped!"
	exit 0
fi

if [ "$1" == "restart" ]
then
	killall -9 nginx
	sleep 3
	ulimit -HSn 348160
	/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
	[ "$?" -eq "0" ] && echo "nginx restart success!"|| echo "nginx start fail !"
	exit 0
fi

if [ "$1" == "reload" ]
then
	ulimit -HSn 348160
	/usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf
	if [ $? == 0 ];then
		/usr/local/nginx/sbin/nginx -s reload
		[ $? == 0 ] && echo 'nginx reload success!'
	else
		echo 'Nginx conf file wrong!!!plase check.'
	fi
	exit 0
fi

echo "Usege:$0 start|stop|reload|restart"
