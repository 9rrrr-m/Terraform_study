#!/bin/bash
sudo yum -y install httpd
echo "MyWEB Server" | sudo tee /var/www/html/index.html
sudo systemctl enable --now httpd
