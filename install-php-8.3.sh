#!/usr/bin/env bash
# LEMP installation script
# Author: Saiful Islam

if dpkg-query -W needrestart >/dev/null 2>&1; then
    sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
fi

echo 'Acquire::ForceIPv4 "true";' | tee /etc/apt/apt.conf.d/99force-ipv4
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get install -y nginx

#install mariadb-server with password
NEW_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
sudo apt-get install -y mariadb-server
sudo mysql -uroot <<MYSQL_SCRIPT
ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_PASS}';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo $NEW_PASS > mariadb_root_pass.txt

# Add Adminer
sudo mkdir -p /var/www/html/adminer
sudo wget "https://www.adminer.org/latest-mysql-en.php" -O /var/www/html/adminer/index.php
sudo chown -R www-data:www-data /var/www/html/adminer


sudo apt-get install -y php8.3-fpm php8.3-cli php8.3-curl php8.3-mbstring php8.3-xml php8.3-zip php8.3-mysql php8.3-imagick php8.3-gd php8.3-intl
sudo sed -i s/\;cgi\.fix_pathinfo\s*\=\s*1/cgi.fix_pathinfo\=0/ /etc/php/8.3/fpm/php.ini

sudo cat >  /var/www/html/index.html << EOL
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required. (8.3)</p>
<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>
<p><em>Thank you for using nginx.</em></p>
</body>
</html>
EOL
sudo echo '<?php phpinfo(); ?>' > /var/www/html/info.php

# add php in nginx config
sudo echo "" > /etc/nginx/sites-available/default
sudo cat > /etc/nginx/sites-available/default << EOL
server {
	listen 80 default_server;
	server_name _;
	root /var/www/html;
	index index.html index.htm index.php;
	location / {
			try_files \$uri \$uri/ /index.html;
	}
	
	# Use custom path for secure access
	# location /adminer {
	# 	alias /var/www/html/adminer/;
	# 	index index.php;
	# 	location ~ ^/adminer/(.+\.php)$ {
	# 		alias /var/www/html/adminer/$1;
	# 		fastcgi_pass unix:/run/php/php8.3-fpm.sock;
	# 		include fastcgi_params;
	# 		fastcgi_param SCRIPT_FILENAME $request_filename;
	# 		fastcgi_param PATH_INFO $fastcgi_path_info;
	# 	}
	# }

	location ~ \.php$ {
			include snippets/fastcgi-php.conf;
			fastcgi_pass unix:/run/php/php8.3-fpm.sock;
	}
	# redirect server error pages to the static page /50x.html
	error_page 500 502 503 504 /50x.html;
	location = /50x.html {
			root /var/www/html;
	}
}
EOL
sudo service php8.3-fpm reload
sudo service nginx stop
sudo service nginx start

echo  "Installing Composer\n";
sudo curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

echo "Installing Redis";
sudo apt install redis-server -y
