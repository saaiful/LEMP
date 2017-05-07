# Remove PHP
sudo apt-get -y purge php.*
sudo apt-get -y autoremove
sudo apt-get -y autoclean
# Remove Nginx
sudo apt-get remove -purge nginx nginx-common
sudo apt-get -y autoremove
sudo apt-get -y autoclean
# Remove MySQL
sudo apt-get -y remove --purge mysql-server mysql-client mysql-commo
sudo apt-get -y autoremove
sudo apt-get -y autoclean
sudo rm -rf /var/lib/mysql
sudo rm -rf /etc/mysql
