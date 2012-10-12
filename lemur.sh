#!/bin/bash
#
#                                      _,.
#                                 _,::' ':)
#                               ,'  ::_.-'
#                              /::.,"'
#                             :  `:
#                             :   :
#                              \.:::._
#          LEMUR!               `:'   `-.
#                                 `._..:::.
#                                    `:::''\
#                                      \    \
#                                       :::..:
#                                       |''::|
#                                       ;    |
#     _                    ______      /::.  ;
#     \`-...._,\   __  _.-':.:. .''-.,''::::/
#      \/::::|,/:-':.`':. . .   .  . `.  ';'
#      :\ '/ `'.\::. ..  .             \ /
#      :o|/o) _-':.    \    .  .-'  .   /
#       \_`.,.' `-._.   \     /.  .    /
#        `-' `.     \.   \   /. .    ,'
#              `._   \.   \_/..     /|
#               /.`;-->'  / |.    ,'.:
#              :. /  /.  /  :.   :\ .\
#              | /  :.  /    :.  | \  \
#              ;_\  |  /     :.  |  `, |
#            ,//_`__; /    __.\  |,-',|;
#             ,//,---'   ,//,--..'
#
#
# Linux - Nginx - MySQL - Unicorn - Rails
# ---- Brought to you by the AMA Team
#
# <udf name="appname" default="yourapplication" label="Application name" />
# <udf name="domain" default="yourapplication.com" label="Domain to Host" />
# <udf name="user_name" default="deploy" label="Unprivileged User Account" />
# <udf name="user_password" default="WAFFLES123!" label="Unprivileged User Password (WAFFLES123!)" />
# <udf name="db_password" default="NINJAS123!" Label="MySQL root Password (NINJAS123!)" />
# <udf name="db_name" Label="Create Database" default="yourapplication_production" example="Optionally create this database" />
# <udf name="db_user" Label="Create MySQL User" default="superman" example="Optionally create this user" />
# <udf name="db_user_password" Label="MySQL User's Password (OATMEAL123!)" default="OATMEAL123!" example="User's password" />
# <udf name="rails_env" default="production" Label="Rails Environment" oneOf="development,test,staging,production" />
# <udf name="the_ssh_key" Label="Your machine's public ssh key" />

exec &> /root/script.log

function user_ssh_keygen {
  # $1 - username
  sudo -u $1 -i -- "ssh-keygen -N '' -f ~/.ssh/id_rsa -t rsa -q"
}

function add_known_hosts {
  # $1 - username
    ssh-keyscan github.com | tee /home/$1/.ssh/known_hosts
    chown $1:$1 /home/$1/.ssh/known_hosts
}

function add_ssh_keys {
  # $1 - username
   system_user_add_ssh_key "$1" "$THE_SSH_KEY"
}

function set_host_names  {
  # set hostname
  echo $1 > /etc/hostname

  # apply hostname to hosts file
  sed -i "/^127.0.0.1/a\
  $2 $1
  " /etc/hosts
}

source <ssinclude StackScriptID="1">
source <ssinclude StackScriptID="123">

system_update

set_host_names ${DOMAIN} $(system_primary_ip)

system_add_user $USER_NAME $USER_PASSWORD "users,sudo"
add_ssh_keys "$USER_NAME"
goodstuff

system_enable_universe
system_security_ufw_install
system_security_ufw_configure_basic
system_update_locale_en_US_UTF_8
system_sshd_permitrootlogin No
system_sshd_passwordauthentication No
system_sshd_pubkeyauthentication Yes
system_sshd_append ClientAliveInterval 60
/etc/init.d/ssh restart

user_ssh_keygen "$USER_NAME"
add_known_hosts "$USER_NAME"

mysql_install "$DB_PASSWORD"
sudo apt-get -y install libmysqlclient-dev
mysql_tune 30

mysql_create_user "$DB_PASSWORD" "$DB_USER" "$DB_USER_PASSWORD"
mysql_create_database "$DB_PASSWORD" "$DB_NAME"
mysql_grant_user "$DB_PASSWORD" "$DB_USER" "$DB_NAME"

sudo apt-get -y install nginx

cat > /etc/nginx/sites-available/$APPNAME <<EOF
  upstream app_server {
    server unix:/home/deploy/$APPNAME/current/tmp/sockets/unicorn.sock fail_timeout=0;
  }

  server {
    listen 80;
    server_name $DOMAIN ${system_primary_ip};

    access_log /home/deploy/$APPNAME/current/log/access.log;
    error_log /home/deploy/$APPNAME/current/log/error.log;

    root /home/deploy/$APPNAME/current/public/;

    location / {
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header Host \$http_host;
      proxy_redirect off;

      # This is the meat of the rails page caching config
      # it adds .html to the end of the URL and then checks
      # the filesystem for that file. If it exists, then we
      # rewrite the URL to have explicit .html on the end
      # and then send it on its way to the next config rule.
      # If there is no file on the fs then it sets all the
      # necessary headers and proxies to our upstream unicorns.
      if (-f \$request_filename.html) {
        rewrite (.*) \$1.html break;
      }
      if (!-f \$request_filename) {
        proxy_pass http://app_server;
        break;
      }
    }

    error_page 500 502 503 504 /500.html;
    location /500.html {
      root /home/deploy/$APPNAME/current/public;
    }

  }
EOF

sudo ln -s "/etc/nginx/sites-available/$APPNAME" "/etc/nginx/sites-enabled/$APPNAME"

sudo apt-get -y install git-core

# ruby install from http://lenni.info/blog/2012/05/installing-ruby-1-9-3-on-ubuntu-12-04-precise-pengolin/
sudo apt-get update
sudo apt-get -y install ruby1.9.1 ruby1.9.1-dev \
  rubygems1.9.1 irb1.9.1 ri1.9.1 rdoc1.9.1 \
  build-essential libopenssl-ruby1.9.1 libssl-dev zlib1g-dev

sudo update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.9.1 400 \
         --slave   /usr/share/man/man1/ruby.1.gz ruby.1.gz \
                        /usr/share/man/man1/ruby1.9.1.1.gz \
        --slave   /usr/bin/ri ri /usr/bin/ri1.9.1 \
        --slave   /usr/bin/irb irb /usr/bin/irb1.9.1 \
        --slave   /usr/bin/rdoc rdoc /usr/bin/rdoc1.9.1

# choose your interpreter
# changes symlinks for /usr/bin/ruby , /usr/bin/gem
# /usr/bin/irb, /usr/bin/ri and man (1) ruby
sudo update-alternatives --config ruby
sudo update-alternatives --config gem

sudo gem install bundler

sudo mkdir -p /home/deploy
sudo chown "$USER_NAME" /home/deploy

# this will fail with a bad config (until we get our files in place via capistrano),
#  the goal here is to just start nginx
sudo /etc/init.d/nginx start
