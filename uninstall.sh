# Remove PHP
sudo apt-get remove -y php.*
sudo apt-get -y autoremove
sudo apt-get -y autoclean
# Remove Nginx
sudo apt-get remove -y nginx nginx-common
sudo apt-get -y autoremove
sudo apt-get -y autoclean
# Remove MySQL
sudo apt-get remove -y mysql*
sudo apt-get -y autoremove
sudo apt-get -y autoclean
sudo rm -rf /var/lib/mysql
sudo rm -rf /etc/mysql
