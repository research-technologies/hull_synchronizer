# frozen_string_literal: true

# see https://github.com/puma/puma/blob/master/examples/config.rb
# see https://www.digitalocean.com/community/tutorials/how-to-deploy-a-rails-app-with-puma-and-nginx-on-ubuntu-14-04#configure-puma
# see https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server
# see https://stackoverflow.com/questions/19946153/how-do-i-use-pumas-configuration-file

# Setup paths
# log_dir = ENV.fetch('LOGS_PATH', ENV.fetch('RAILS_TMP', 'tmp'))
pids_dir = ENV.fetch('PIDS_PATH', ENV.fetch('RAILS_TMP', 'tmp'))

# The directory to operate out of.
# The default is the current directory.
# directory 'path'

# Load “path” as a rackup file.
# The default is “config.ru”.
# rackup 'path'

# Disable request logging.
# The default is 'false'.
quiet

# Code to run before doing a restart. This code should
# close log files, database connections, etc.
#
# This can be called multiple times to add code each time.
#
# on_restart do
#   puts 'On restart...'
# end

# Command to use to restart puma. This should be just how to
# load puma itself (ie. 'ruby -Ilib bin/puma'), not the arguments
# to puma, as those are the same as the original process.
#
# restart_command '/u/app/lolcat/bin/restart_puma'

# Configure “min” to be the minimum number of threads to use to answer
# requests and “max” the maximum.
# The default is “0, 16”.
threads_count = ENV.fetch('RAILS_MAX_THREADS') { 5 }.to_i
threads threads_count, threads_count

# Set the environment in which the rack's app will run. The value must be a string.
# The default is development'.

environment ENV.fetch('RAILS_ENV') { 'development' }

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

# Daemonize the server into the background. Highly suggest that
# this be combined with 'pidfile' and 'stdout_redirect'.
# The default is 'false'.

# daemonize
daemonize true if ENV['RAILS_ENV'] == 'production'

# Bind the server to "url". "tcp://", "unix://" and "ssl://" are the only
# accepted protocols.
#
# The default is "tcp://0.0.0.0:9292".
#
# bind 'tcp://0.0.0.0:9292'
# bind 'unix:///var/run/puma.sock'
# bind 'unix:///var/run/puma.sock?umask=0111'
# bind 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert'

# Instead of "bind 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert'" you
# can also use the "ssl_bind" option.
#
# ssl_bind '127.0.0.1', '9292', {
#   key: path_to_key,
#   cert: path_to_cert
# }
# for JRuby additional keys are required:
# keystore: path_to_keystore,
# keystore_pass: password

if ENV['RAILS_ENV'] == 'production'

  port ENV.fetch('PORT') { 3000 }
  bind "unix://#{File.join(pids_dir, 'puma.sock')}"

  # Redirect STDOUT and STDERR to files specified. The 3rd parameter
  # (“append”) specifies whether the output is appended, the default is
  # “false”.
  # stdout_redirect File.join(log_dir, 'puma.stdout.log'), File.join(log_dir, 'puma.stderr.log'), true

  # Store the pid of the server in the file at “path”.
  pidfile File.join(pids_dir, 'puma.pid')

  # Use “path” as the file to store the server info state. This is
  # used by “pumactl” to query and control the server.
  state_path File.join(pids_dir, 'puma.state')

end

# === Cluster mode ===

# How many worker processes to run.
# The default is “0”.
# workers 0

# Code to run when a worker boots to setup the process before booting
# the app.
# This can be called multiple times to add hooks.

# on_worker_boot do
#   puts 'On worker boot...'
# end

# === Puma control rack application ===

# Start the puma control rack application on “url”. This application can
# be communicated with to control the main server. Additionally, you can
# provide an authentication token, so all requests to the control server
# will need to include that token as a query parameter. This allows for
# simple authentication.

# Check out https://github.com/puma/puma/blob/master/lib/puma/app/status.rb
# to see what the app has available.

# activate_control_app 'unix:///var/run/pumactl.sock'
# activate_control_app 'unix:///var/run/pumactl.sock', { auth_token: '12345' }
# activate_control_app 'unix:///var/run/pumactl.sock', { no_token: true }
