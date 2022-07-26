#!/bin/bash  
yum update -y
yum install httpd -y
echo "<html><body><h1>Scale Test</h1></body></html>" >/var/www/html/index.html
systemctl start httpd
systemctl enable httpd
amazon-linux-extras install epel -y
yum install htop -y
yum install stress -y