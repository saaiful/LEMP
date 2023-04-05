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

#insttall mysql-server with password
NEW_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password "$NEW_PASS
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password "$NEW_PASS
sudo apt-get -y install mysql-server
echo $NEW_PASS > mysql_cred.txt

sudo apt-get install -y mysql-server
sudo apt-get install -y php7.1-fpm php7.1-cli php7.1-curl php7.1-mbstring php7.1-xml php7.1-zip php7.1-mysql php7.1-imagick php7.1-gd
sudo sed -i s/\;cgi\.fix_pathinfo\s*\=\s*1/cgi.fix_pathinfo\=0/ /etc/php/7.1/fpm/php.ini

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
working. Further configuration is required. (7.1)</p>
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
        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.1-fpm.sock;
        }
        # redirect server error pages to the static page /50x.html
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
                root /var/www/html;
        }
}
EOL
sudo service php7.1-fpm reload
sudo service nginx stop
sudo service nginx start

echo  "Installing Composer\n";
sudo curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

echo "Installing Redis";
sudo apt install redis-server -y