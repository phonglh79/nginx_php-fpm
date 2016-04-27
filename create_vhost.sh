#!/bin/sh
# Simple script to install Nginx PHP(php-fpm) on CentOS 5.x - 6.x only 64bit
# By PhongLe - http://congdonglinux.vn

## Make domain and web documentroot

printf "\nNhap vao ten mien cua ban roi an [ENTER]: "
read domain
if [ "$domain" = "" ]; then
        domain="congdonglinux.vn"
echo "Ban nhap sai, he thong se dung congdonglinux.vn lam ten mien chinh"
fi
mkdir -p /home/$domain/public_html
echo "Welcome to http://$domain" > /home/$domain/public_html/index.html;

## Dinh nghia cac bien
request_method='$request_method' 
request_filename='$request_filename'
uri='$uri'
fastcgi_script_name='$fastcgi_script_name'

## Modify error pages
cat > "/build/nginx/html/403.html" <<END
<html>
<head><title>403 Forbidden</title></head>
<body bgcolor="white">
<center><h1>Access Forbidden</h1></center>
<hr><center>Congdonglinux.vn</center>
</body>
</html>

END

cat > "/build/nginx/html/404.html" <<END
<html>
<head><title>404 Not Found</title></head>
<body bgcolor="white">
<center><h1>File Not Found</h1></center>
<hr><center>Congdonglinux.vn</center>
</body>
</html>

END

## Add vhost
mkdir /logs/nginx/$domain
vhdomain="$domain www.$domain";

cat > "/build/nginx/sites-enabled/$domain.conf" <<END

server {
        listen 80;
        server_name $domain;
        root /home/$domain/public_html;

        access_log  /logs/nginx/$domain/access.log  main buffer=16k;
        error_log   /logs/nginx/$domain/error.log;


	## Limit and security
        limit_req zone=antiddos burst=100 nodelay;
        limit_conn conn_limit_per_ip 30;
        include /build/nginx/conf.d/antihack.conf;
        include /build/nginx/conf.d/blackbot.conf;  
        include /build/nginx/conf.d/headers.conf;
 
        ## Only allow these request methods ##
                if ($request_method !~ ^(GET|POST)$ ) {
                return 444;
                }
				
	location / {
		
		root   /home/$domain/public_html;
                index  index.html index.htm index.php;

		if (-f $request_filename) {
                       break;
                        }

                if (!-e $request_filename) {
                        rewrite ^.*$ /index.php last;
                        }

    		}
			
	## redirect server error pages to the static page /50x.html

		error_page   500 502 504 503  /50x.html;
			location = /50x.html {
           		root   html;
			}
		
		error_page   403  /403.html;
			location = /403.html {
            		root   html;
        		}
        	error_page   404  /404.html;
			location = /404.html {
            		root   html;
        		}
		
	##Static file
        location ~* "\.(ico|gif|jpg|jpeg|png|htm|swf|htc|xml|bmp|cur)$" {
        root            /home/$domain/public_html;
        add_header      Pragma "public";
        add_header      Cache-Control "public";
        expires         max;
        access_log      off;
        log_not_found   off;
        }

	location ~* "\.(js|css)$" {
        root            /home/$domain/public_html;
        add_header      Pragma "public";
        add_header      Cache-Control "public";
        expires         7d;
        access_log      off;
        log_not_found   off;
        }


	## Execute PHP scripts
        location ~ \.php$ {
            try_files $uri =404;
            root   /home/$domain/public_html;
            fastcgi_pass 127.0.0.1:9000;
            #fastcgi_pass unix:/dev/shm/php-fpm.sock;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  /home/$domain/public_html$fastcgi_script_name;
            include        fastcgi_params;
        }

	## Disable access to hidden files

        	location ~ /\.          { access_log off; log_not_found off; deny all; }
        	location ~ ~$           { access_log off; log_not_found off; deny all; }

		location = /favicon.ico {
                log_not_found off;
                access_log off;
			}
		location = /robots.txt {
              	allow all;
              	log_not_found off;
              	access_log off;
			}

}


END

/etc/init.d/nginx restart

clear
echo -e "\n\n\n";
echo "Thank you for use scripts ===  Create vhost Successfully installed";
echo " You can upload code to host $domain with documentroot /home/$domain/public_html/";
echo " Please access http://$domain "; 
