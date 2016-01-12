#!/bin/sh
# Simple script to install Nginx PHP(php-fpm) on CentOS 5.x - 6.x only 64bit
# By PhongLe - http://congdonglinux.vn

##Check version OS
arch=`uname -m`
OS_MAJOR_VERSION=`sed -rn 's/.*([0-9])\.[0-9].*/\1/p' /etc/redhat-release`
OS_MINOR_VERSION=`sed -rn 's/.*[0-9].([0-9]).*/\1/p' /etc/redhat-release`
	if [ "$OS_MAJOR_VERSION" = 5 ]; then
		rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm;
		rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-5.rpm;
	else 
		rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm;
		rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm;
	fi

## Install library packages
yum -y update
yum -y install openssl openssl-devel perl-*
yum -y install gcc  gcc-c++
yum -y install --exclude=*.i386 bzip2-devel gdbm-devel db4-devel libjpeg-devel libmcrypt-devel libmcrypt libtidy libtidy-devel icu libicu libicu-devel
yum -y install --exclude=*.i386 libpng-devel freetype-devel libxslt-devel libxml2-devel libc-client-devel gd-devel openssl-devel pcre-devel gmp-devel aspell aspell-devel curl curl-devel zlib-devel 
yum -y install perl-ExtUtils-Embed  

yum -y remove php*
yum -y remove httpd*  

mkdir -p /logs/nginx
mkdir /logs/php-fpm
chmod 777 -R /logs

## Check info hardware server
cpucores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
ram=$( free -m | awk 'NR==2 {print $2}' )
hdd=$( df -h | awk 'NR==2 {print $2}' )
swap=$( free -m | awk 'NR==4 {print $2}' )


#ramformariadb=$(calc $svram/10*6)
#ramforphpnginx=$(calc $svram-$ramformariadb)
#max_children=$(calc $ramforphpnginx/30)
#memory_limit=$(calc $ramforphpnginx/5*3)M
#buff_size=$(calc $ramformariadb/10*8)M
#log_size=$(calc $ramformariadb/10*2)M

##Dinh nghia cac bien
binary_remote_addr='$binary_remote_addr' 
request_method='$request_method' 
limit='$limit'


## Compile nginx
useradd nginx -c "NGINX User" -d /var/lib/nginx -s /sbin/nologin
cd /root/installscript/packages

##ngx_pagespeed
##option1
#wget https://github.com/pagespeed/ngx_pagespeed/archive/v1.9.32.6-beta.tar.gz
#tar -xvzf v1.9.32.6-beta.tar.gz
#cd ngx_pagespeed-1.9.32.6-beta
#wget https://dl.google.com/dl/page-speed/psol/1.9.32.6.tar.gz
#tar -xvzf 1.9.32.6.tar.gz
#rm -rf 1.9.32.6.tar.gz

##option2
tar -xvzf v1.9.32.6-beta.tar.gz
cp 1.9.32.6.tar.gz ngx_pagespeed-1.9.32.6-beta/
cd ngx_pagespeed-1.9.32.6-beta
tar -xvzf 1.9.32.6.tar.gz
rm -rf 1.9.32.6.tar.gz

mkdir /dev/shm/ngx_pagespeed_cache
chown nginx:nginx /dev/shm/ngx_pagespeed_cache

cd /root/installscript/packages
tar -xvzf nginx-1.8.0.tar.gz
patch -p0 < nginx_1.8.0_signature.patch
tar -xvzf ngx_cache_purge-2.3.tar.gz
tar -xvzf pcre-8.37.tar.gz
cd nginx-1.8.0
./configure --prefix=/build/nginx --user=nginx --group=nginx --http-client-body-temp-path=/build/nginx/client_body --http-proxy-temp-path=/build/nginx/proxy --http-fastcgi-temp-path=/build/nginx/fastcgi --with-http_ssl_module --with-http_realip_module --with-debug --with-http_stub_status_module --with-http_gzip_static_module --with-http_perl_module --with-http_secure_link_module --with-http_flv_module --with-pcre=/root/installscript/packages/pcre-8.37 --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --without-http_uwsgi_module --without-http_scgi_module --without-http_ssi_module --add-module=/root/installscript/packages/ngx_cache_purge-2.3 --add-module=/root/installscript/packages/ngx_pagespeed-1.9.32.6-beta
make
make install
mv /build/nginx/conf/nginx.conf  /build/nginx/conf/nginx.conf_org

cd /root/installscript/packages
cp nginx /etc/init.d/
chmod 700 /etc/init.d/nginx

cd /root/installscript/configure/nginx
cp -r * /build/nginx/
chmod 700 /build/nginx/sbin/start-stop-daemon

mkdir /build/nginx/sites-enabled

## Config nginx
cat > "/build/nginx/conf/nginx.conf" <<END
user  nginx;
worker_processes  $cpucores;
worker_rlimit_nofile 100000;
error_log  /logs/nginx/error.log info;

events {
    worker_connections  10000;
        use epoll;
        multi_accept on;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

        ## Options config
        include /build/nginx/conf.d/options.conf;

        ## Performance File Cache Settings
        open_file_cache          max=100000  inactive=20s;
        open_file_cache_valid    30s;
        open_file_cache_min_uses 2;
        open_file_cache_errors   on;


        ##Limits request
        ## 1m can handle 32000 sessions with 32 bytes/session, set to 5m x 32000 session ###
        limit_req_zone $binary_remote_addr zone=antiddos:20m rate=50r/s;
        #limit_req_zone $binary_remote_addr zone=antiddos:20m rate=15r/s;
        limit_req_zone $binary_remote_addr zone=antiddosphp:20m rate=5r/s;

	##limit connection
        limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:20m;

        ##Maps ip address to $limit variable if request is of type POST
        map $request_method $limit {
                default "";
                POST $binary_remote_addr;
        }

        ##Creates 10mb zone in memory for storing binary ips
        limit_req_zone $limit zone=post_request:10m rate=1r/s;

include /build/nginx/sites-enabled/*;


         server {
            server_name  _;
            return 444;
        }
##Block Spam
include /build/nginx/conf.d/referral-spam.conf;

}

END




## Start all service

/etc/init.d/nginx start
chkconfig nginx on


clear
echo -e "\n\n\n";
echo "Thank you for use scripts ===  Nginx  Successfully installed";
echo "Please access http://ip on browser ";





