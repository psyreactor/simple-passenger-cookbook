# derived attributes / conditional assignment
# https://christinemdraper.wordpress.com/2014/10/06/avoiding-the-possible-pitfalls-of-derived-attributes/
ruby_bin_dir = File.join(
  node['ruby_build']['default_ruby_base_path'],
  node['passenger']['ruby_version'],
  'bin'
)
app_dir = node['passenger']['app_dir'] || File.join('/opt', node['passenger']['app_name'])
log_dir = node['passenger']['log_dir'] || File.join('/var/log', node['passenger']['app_name'])
pid_dir = node['passenger']['pid_dir'] || File.join('/var/run', node['passenger']['app_name'])
passengerfile_options = node['passenger']['passengerfile'].to_hash
passengerfile_options['log_file'] = node['passenger']['passengerfile']['log_file'] || File.join(
  log_dir,
  node['passenger']['app_name']
)
passengerfile_options['pid_file'] = node['passenger']['passengerfile']['pid_file'] || File.join(
  pid_dir,
  node['passenger']['app_name'] + '.pid'
)
passengerfile_options['user'] = node['passenger']['passengerfile']['user'] || \
                                node['passenger']['user']
passengerfile_options['ruby'] = node['passenger']['passengerfile']['ruby'] || File.join(
  ruby_bin_dir,
  'ruby'
)

# restart the app (if app was running)
execute 'restart app' do
  action :nothing
  command "#{File.join(ruby_bin_dir, 'bundle')} exec passenger-config restart-app #{app_dir}"
  cwd app_dir
  # only restart the app if the app is already running
  only_if { File.exist?(passengerfile_options['pid_file']) }
  # should be run on any of the following changes
  subscribes :run, 'git[app]'
end

# stop the app (if something has changed)
execute 'stop app' do
  action :nothing
  command "#{File.join(ruby_bin_dir, 'bundle')} exec passenger stop"
  cwd app_dir
  # only stop the app if running
  only_if { File.exist?(passengerfile_options['pid_file']) }
  # start the app immediately after stop
  notifies :run, 'execute[start app]'
end

# create user and group
group 'passenger group' do
  group_name node['passenger']['group']
  notifies :run, 'execute[stop app]'
end
user 'passenger user' do
  username node['passenger']['user']
  group node['passenger']['group']
  notifies :run, 'execute[stop app]'
end

# create log directory
directory 'app log dir' do
  path log_dir
  owner node['passenger']['user']
  group node['passenger']['group']
  mode node['passenger']['log_dir_mode']
  notifies :run, 'execute[stop app]'
end

# enable log rotation for the log directory
include_recipe 'logrotate'
logrotate_app node['passenger']['app_name'] do
  cookbook 'logrotate'
  path passengerfile_options['log_file']
  frequency 'daily'
  create "644 #{node['passenger']['user']} #{node['passenger']['group']}"
  rotate 7
  notifies :run, 'execute[stop app]'
end

# create pid dir
directory 'pid dir' do
  path pid_dir
  owner node['passenger']['user']
  group node['passenger']['group']
  mode node['passenger']['pid_dir_mode']
  notifies :run, 'execute[stop app]'
end

# create app root
directory 'app dir' do
  path app_dir
  owner node['passenger']['user']
  group node['passenger']['group']
  mode node['passenger']['app_dir_mode']
  notifies :run, 'execute[stop app]'
end

# git app
package 'git'
git 'app' do
  destination app_dir
  repository node['passenger']['git_repo']
  revision node['passenger']['git_revision']
  user node['passenger']['user']
  group node['passenger']['group']
  notifies :run, 'execute[restart app]'
end

# create the Passengerfile.json
template 'passengerfile' do
  path File.join(app_dir, 'Passengerfile.json')
  source 'Passengerfile.json.erb'
  mode node['passenger']['passengerfile_mode']
  owner node['passenger']['user']
  group node['passenger']['group']
  variables options: passengerfile_options
  notifies :run, 'execute[stop app]'
end

# prep system for ruby
include_recipe 'build-essential'
case node['platform']
when 'debian', 'ubuntu'
  package 'ruby devel dependencies' do
    package_name %w(libssl-dev libreadline-dev zlib1g-dev)
    notifies :run, 'execute[stop app]'
  end
when 'centos', 'redhat', 'amazon', 'scientific', 'oracle', 'fedora'
  package 'ruby devel dependencies' do
    package_name %w(bzip2 openssl-devel readline-devel zlib-devel)
    notifies :run, 'execute[stop app]'
  end
end

# install ruby
include_recipe 'ruby_build'
ruby_build_ruby "app ruby version #{node['passenger']['ruby_version']}" do
  definition node['passenger']['ruby_version']
  notifies :run, 'execute[stop app]'
end

# install bundler
gem_package 'bundler' do
  gem_binary File.join(
    node['ruby_build']['default_ruby_base_path'],
    node['passenger']['ruby_version'],
    'bin',
    'gem'
  )
  version node['passenger']['bundler_version']
  notifies :run, 'execute[stop app]'
end

# install gem dependencies
execute 'bundle install' do
  command "#{File.join(ruby_bin_dir, 'bundle')} install --deployment --without development test"
  cwd app_dir
  user node['passenger']['user']
  group node['passenger']['group']
  not_if "#{File.join(ruby_bin_dir, 'bundle')} check", :cwd => app_dir
  notifies :run, 'execute[stop app]'
end

# start the app (if app was not running)
execute 'start app' do
  command "#{File.join(ruby_bin_dir, 'bundle')} exec passenger start"
  cwd app_dir
  # dont start the app if the app is already running
  not_if { File.exist?(passengerfile_options['pid_file']) }
end
