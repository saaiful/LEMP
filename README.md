# LEMP Stack (NGiNX)
This repository contains a shell script for installing the LEMP stack, Composer, and Redis on Ubuntu-based systems. After running the script, you will have a fully functional LEMP stack with Composer and Redis installed on your Ubuntu-based system.

## What is LEMP Stack?
LEMP stack is a combination of software used to build and deploy web applications. LEMP stands for `Linux`, `Nginx`, `MySQL`, and `PHP`.

* Linux is the operating system on which the stack runs.
* Nginx is the web server that handles incoming HTTP requests and forwards them to the appropriate PHP files.
* MySQL is the database management system used to store and retrieve data for the web application.
* PHP is the server-side scripting language that is used to dynamically generate HTML pages for the web application.

## Install (php 7.0)
1. Copy script by using `wget https://raw.githubusercontent.com/saaiful/LEMP/master/install.sh`
2. Run using `sudo bash install.sh`
3. MySQL password can be found in `mysql_cred.txt` in server root

## Install (php 7.2)
1. Copy script by using `wget https://raw.githubusercontent.com/saaiful/LEMP/master/install-php-7.2.sh`
2. Run using `sudo bash install-php-7.2.sh`
3. MySQL password can be found in `mysql_cred.txt` in server root

## Install (php 7.3)
1. Copy script by using `wget https://raw.githubusercontent.com/saaiful/LEMP/master/install-php-7.3.sh`
2. Run using `sudo bash install-php-7.3.sh`
3. MySQL password can be found in `mysql_cred.txt` in server root

## Install (php 7.4)
1. Copy script by using `wget https://raw.githubusercontent.com/saaiful/LEMP/master/install-php-7.4.sh`
2. Run using `sudo bash install-php-7.4.sh`
3. MySQL password can be found in `mysql_cred.txt` in server root

## Install (php 8.0)
1. Copy script by using `wget https://raw.githubusercontent.com/saaiful/LEMP/master/install-php-8.0.sh`
2. Run using `sudo bash install-php-8.0.sh`
3. MySQL password can be found in `mysql_cred.txt` in server root

## Install (php 8.1)
1. Copy script by using `wget https://raw.githubusercontent.com/saaiful/LEMP/master/install-php-8.1.sh`
2. Run using `sudo bash install-php-8.1.sh`
3. MySQL password can be found in `mysql_cred.txt` in server root

## Install (php 8.2)
1. Copy script by using `wget https://raw.githubusercontent.com/saaiful/LEMP/master/install-php-8.2.sh`
2. Run using `sudo bash install-php-8.2.sh`
3. MySQL password can be found in `mysql_cred.txt` in server root

## Install (php 7.0 - 8.2)
1. Copy script by using `wget https://raw.githubusercontent.com/saaiful/LEMP/master/install-php-all.sh`
2. Run using `sudo bash install-php-all.sh`
3. MySQL password can be found in `mysql_cred.txt` in server root

## Uninstall
1. Copy script by using `wget https://raw.githubusercontent.com/saaiful/LEMP/master/uninstall.sh`
2. Run using `sudo bash uninstall.sh`


## Usage
Once the LEMP stack is installed, you can start deploying your web application to the server. Here are a few basic steps to get started:

1. Create a new PHP file in the /var/www/html/ directory. This file will serve as the main entry point for your web application.
2. Write your PHP code in the file.
3. Visit http://<your-server-ip-address>/filename.php in your web browser to see your PHP code in action.
