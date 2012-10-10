LEMUR
=====

A Linode Stack Script which will setup Linux - Nginx - MySQL - Unicorn - Rails

Ruby 1.9.3  
Tested on Ubuntu 12.04


Notes
------
Make sure to update the SSH keys  
Nginx will fail until you deploy with capistrano, once you've deployed run:  
sudo /etc/init.d/nginx start
