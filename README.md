LEMUR
=====

A Linode Stack Script which will setup Linux - Nginx - MySQL - Unicorn - Rails

Ruby 1.9.3  
Tested on Ubuntu 12.04


Getting Started
-------------
1.  Install with stack script on linode  (make sure to update the SSH keys in the script so you can login to the server)  
2.  Update your gemfile to look like this:
```ruby
source 'https://rubygems.org'

gem 'rails', '3.2.6'

gem 'mysql'
gem 'unicorn'
gem 'capistrano-deploy', :group => :development, :require => false

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'
```
3.  Create a Capfile in root and make it look like this:
```ruby
require 'capistrano-deploy'
use_recipes :git, :bundle, :rails, :unicorn, :rails_assets

server '50.116.0.17', :web, :app, :db, :primary => true
set :user, 'deploy'
set :deploy_to, '/home/deploy/yourapplication'
set :repository, 'git@github.com:RyanonRails/test-repo.git'

ssh_options[:forward_agent] = true

after 'deploy:update', 'bundle:install'
after 'deploy:update', 'deploy:assets:precompile'
after 'deploy:restart', 'unicorn:reload'
```
4.  Create a file unicorn.rb (in the config folder) and make it look like this:
```ruby
# unicorn_rails -c config/unicorn.rb -E production -D
#
# Sample verbose configuration file for Unicorn (not Rack)
#
# This configuration file documents many features of Unicorn
# that may not be needed for some applications. See
# http://unicorn.bogomips.org/examples/unicorn.conf.minimal.rb
# for a much simpler configuration file.
#
# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.
application = "yourapplication"

rails_env = ENV['RACK_ENV'] || 'production'

# Use at least one worker per core if you're on a dedicated server,
# more will usually help for _short_ waits on databases/caches.
worker_processes (2)

# Help ensure your application will always spawn in the symlinked
# "current" directory that Capistrano sets up.
working_directory "/home/deploy/#{application}/current" # available in 0.94.0+

# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
listen "/home/deploy/#{application}/current/tmp/sockets/unicorn.sock", :backlog => 2048
#listen 8080, :tcp_nopush => true

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

# feel free to point this anywhere accessible on the filesystem
pid "/home/deploy/#{application}/current/tmp/pids/unicorn.pid"

# By default, the Unicorn logger will write to stderr.
# Additionally, ome applications/frameworks log to stderr or stdout,
# so prevent them from going to /dev/null when daemonized here:
stderr_path "/home/deploy/#{application}/current/log/unicorn.stderr.log"
stdout_path "/home/deploy#{application}/current/log/unicorn.stdout.log"

# combine REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
    GC.copy_on_write_friendly = true

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  defined?(ActiveRecord::Base) and
      ActiveRecord::Base.connection.disconnect!

  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end

  # The following is only recommended for memory/DB-constrained
  # installations.  It is not needed if your system can house
  # twice as many worker_processes as you have configured.
  #
  # # This allows a new master process to incrementally
  # # phase out the old master process with SIGTTOU to avoid a
  # # thundering herd (especially in the "preload_app false" case)
  # # when doing a transparent upgrade.  The last worker spawned
  # # will then kill off the old master process with a SIGQUIT.
  # old_pid = "#{server.config[:pid]}.oldbin"
  # if old_pid != server.pid
  #   begin
  #     sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
  #     Process.kill(sig, File.read(old_pid).to_i)
  #   rescue Errno::ENOENT, Errno::ESRCH
  #   end
  # end
  #
  # # *optionally* throttle the master from forking too quickly by sleeping
  # sleep 1
end

after_fork do |server, worker|
  # per-process listener ports for debugging/admin/migrations
  # addr = "127.0.0.1:#{9293 + worker.nr}"
  # server.listen(addr, :tries => -1, :delay => 5, :tcp_nopush => true)

  # the following is *required* for Rails + "preload_app true",
  defined?(ActiveRecord::Base) and
      ActiveRecord::Base.establish_connection

  # if preload_app is true, then you may also want to check and
  # restart any other shared sockets/descriptors such as Memcached,
  # and Redis.  TokyoCabinet file handles are safe to reuse
  # between any number of forked children (assuming your kernel
  # correctly implements pread()/pwrite() system calls)
end
```
4.  run 'bundle install'
5.  Push all of your code to your repo on github
6.  run 'cap deploy:setup'
7.  then run 'cap deploy:migrations'
8.  run 'cap deploy'




Start the web server
sudo /etc/init.d/nginx start

Fire up the Unicorns
mkdir /home/deploy/yourapplication/current/tmp/pids/
bundle exec unicorn -c /home/deploy/yourapplication/current/config/unicorn.rb -D





# do on remote box
ssh -T git@github.com
  ssh-keyscan github.com | tee /home/$1/.ssh/known_hosts
  chown $1:$1 /home/$1/.ssh/known_hosts

Nginx will fail until you deploy with capistrano, once you've deployed run:

sudo /etc/init.d/nginx start

unicorn_rails -c /home/deploy/yourapplication/current/config/unicorn.rb -D