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


Using the capistrano-deploy gem?
------
In your Capfile:  
  
require 'capistrano-deploy'
use_recipes :git, :bundle, :rails, :unicorn
  
server 'server name or ip address', :web, :app, :db, :primary => true
set :user, 'deploy'
set :deploy_to, '/home/deploy/yourapplication'
set :repository, 'your git repository (git@github.com:username/reponame.git)'

after 'deploy:update', 'bundle:install'
after 'deploy:restart', 'unicorn:reload'
