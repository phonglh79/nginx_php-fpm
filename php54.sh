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


## Compile php-fpm
cd /root/installscript/packages
tar -xvzf php-5.4.45.tar.gz
cd php-5.4.45
./configure --prefix=/build/php-fpm  --with-config-file-path=/build/php-fpm/etc --with-mysql --with-mysqli --with-bz2  --with-jpeg-dir  --with-freetype-dir  --with-png-dir --with-gd  --enable-gd-native-ttf  --with-gdbm --with-gettext --enable-mbstring --with-pcre-regex --with-regex --enable-soap  --enable-sockets --enable-pdo --with-xmlrpc  --enable-zip  --with-zlib --enable-ftp --with-iconv --enable-pcntl --enable-fpm  --with-mcrypt  --enable-bcmath --enable-gd-jis-conv --enable-dba --enable-intl --with-pspell --with-tidy --with-mhash --with-curl --with-curlwrappers --with-pear  --with-pcre-dir --with-openssl --with-pdo-mysql --with-libxml-dir  --enable-sysvmsg  --enable-sysvsem --enable-sysvshm --enable-exif --with-xsl  --without-pdo-sqlite --without-sqlite3 --with-libdir=lib64  
make
make install
cd /root/installscript/packages/php-5.4.45
cp php.ini-production /build/php/etc/php.ini_org
cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod 700 /etc/init.d/php-fpm

cd /root/installscript/configure/php-fpm
cp * /build/php-fpm/etc


## Install memcache extenstion 
cd /root/installscript/packages
tar -xvf memcache-2.2.7.tgz
cd memcache-2.2.7
/build/php-fpm/bin/phpize
./configure --enable-memcache --with-php-config=/build/php-fpm/bin/php-config
make
make install

## Install redis extenstion 
cd /root/installscript/packages
tar -xvf redis-2.2.7.tgz
cd redis-2.2.7
/build/php-fpm/bin/phpize
./configure --enable-redis --with-php-config=/build/php-fpm/bin/php-config
make
make install

## Install zend opcache extenstion 
cd /root/installscript/packages
tar -xvf zendopcache-7.0.5.tgz
cd zendopcache-7.0.5
/build/php-fpm/bin/phpize
./configure --with-php-config=/build/php-fpm/bin/php-config
make
make install


## Start all service
/etc/init.d/php-fpm start
chkconfig php-fpm on



clear
echo -e "\n\n\n";
echo "Thank you for use scripts ===  Nginx + PHP-FPM Successfully installed";
echo "Please access http://ip on browser ";





