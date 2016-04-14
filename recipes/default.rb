# create user and group
group 'passenger group' do
  group_name node['passenger']['group']
end
user 'passenger user' do
  username node['passenger']['user']
  group node['passenger']['group']
end

# create log directory
directory 'app log dir' do
  path node['passenger']['log_dir']
  owner node['passenger']['user']
  group node['passenger']['group']
  mode node['passenger']['log_dir_mode']
end

# enable log rotation for the log directory
include_recipe 'logrotate'
logrotate_app node['passenger']['app_name'] do
  cookbook 'logrotate'
  path node['passenger']['passengerfile']['log_file']
  frequency 'daily'
  create "644 #{node['passenger']['user']} #{node['passenger']['group']}"
  rotate 7
end

# create pid dir
directory 'pid dir' do
  path node['passenger']['pid_dir']
  owner node['passenger']['user']
  group node['passenger']['group']
  mode node['passenger']['pid_dir_mode']
end

# create app root
directory 'app dir' do
  path node['passenger']['app_dir']
  owner node['passenger']['user']
  group node['passenger']['group']
  mode node['passenger']['app_dir_mode']
end

# git app
package 'git'
git 'app' do
  destination node['passenger']['app_dir']
  repository node['passenger']['git_repo']
  revision node['passenger']['git_revision']
  user node['passenger']['user']
  group node['passenger']['group']
end

# create the Passengerfile.json
template 'passengerfile' do
  path File.join(node['passenger']['app_dir'], 'Passengerfile.json')
  source 'Passengerfile.json.erb'
  mode node['passenger']['passengerfile_mode']
  owner node['passenger']['user']
  group node['passenger']['group']
  variables settings: node['passenger']['passengerfile']
end

# install ruby
['gcc', 'openssl-devel', 'readline-devel', 'zlib-devel'].each do |pkg|
  yum_package pkg
end
include_recipe 'ruby_build'
ruby_build_ruby 'app ruby' do
  definition node['passenger']['ruby_version']
  prefix_path node['passenger']['ruby_dir']
end

# install bundler
gem_package 'bundler' do
  gem_binary File.join(node['passenger']['ruby_dir'], 'bin/gem')
end

# install gem dependencies
execute 'bundle install' do
  command "bundle install --deployment --without development test"
  environment 'PATH' => "#{File.join(node['passenger']['ruby_dir'], 'bin')}:#{ENV['PATH']}"
  cwd node['passenger']['app_dir']
  user node['passenger']['user']
  group node['passenger']['group']
  not_if 'bundle check', :cwd => node['passenger']['app_dir'], :environment => {
    'PATH' => "#{File.join(node['passenger']['ruby_dir'], 'bin')}:#{ENV['PATH']}"
  }
end

# # restart the app (if app was running)
# execute 'restart app' do
#   command "bundle exec passenger-config restart-app #{node['passenger']['app_dir']}"
#   environment 'PATH' => "#{File.join(node['passenger']['ruby_dir'], 'bin')}:#{ENV['PATH']}"
#   cwd node['passenger']['app_dir']
#   action :nothing
#   # only restart the app if the app is already running
#   only_if { File.exist?(node['passenger']['passengerfile']['pid_file']) }
#   # should be run on any of the following changes
#   subscribes :run, 'group[passenger group]'
#   subscribes :run, 'user[passenger user]'
#   subscribes :run, 'directory[app log dir]'
#   subscribes :run, 'directory[pid dir]'
#   subscribes :run, 'directory[app dir]'
#   subscribes :run, 'git[app]'
#   subscribes :run, 'template[passengerfile]'
#   subscribes :run, 'ruby_build_ruby[app ruby]'
#   subscribes :run, 'gem_package[bundler]'
#   subscribes :run, 'execute[bundle install]'
# end

# stop the app (if something has changed)
execute 'stop app' do
  command "bundle exec passenger stop"
  environment 'PATH' => "#{File.join(node['passenger']['ruby_dir'], 'bin')}:#{ENV['PATH']}"
  cwd node['passenger']['app_dir']
  action :nothing
  # only stop the app if running
  only_if { File.exist?(node['passenger']['passengerfile']['pid_file']) }
  # should be run on any of the following changes
  subscribes :run, 'group[passenger group]'
  subscribes :run, 'user[passenger user]'
  subscribes :run, 'directory[app log dir]'
  subscribes :run, 'directory[pid dir]'
  subscribes :run, 'directory[app dir]'
  subscribes :run, 'git[app]'
  subscribes :run, 'template[passengerfile]'
  subscribes :run, 'ruby_build_ruby[app ruby]'
  subscribes :run, 'gem_package[bundler]'
  subscribes :run, 'execute[bundle install]'
  # start the app immediately after stop
  notifies :run, 'execute[start app]', :immediately
end

# start the app (if app was not running)
execute 'start app' do
  command "bundle exec passenger start"
  environment 'PATH' => "#{File.join(node['passenger']['ruby_dir'], 'bin')}:#{ENV['PATH']}"
  cwd node['passenger']['app_dir']
  # dont start the app if the app is already running
  not_if { File.exist?(node['passenger']['passengerfile']['pid_file']) }
end
