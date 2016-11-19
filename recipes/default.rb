group 'passenger' do
  group_name node['passenger']['group']
end

directory 'passenger apps' do
  path node['passenger']['apps_dir']
  group node['passenger']['group']
  mode node['passenger']['apps_dir_mode']
end

directory 'passenger logs' do
  path node['passenger']['logs_dir']
  group node['passenger']['group']
  mode node['passenger']['logs_dir_mode']
end

include_recipe 'logrotate'

directory 'passenger pid files' do
  path node['passenger']['pid_files_dir']
  group node['passenger']['group']
  mode node['passenger']['pid_files_dir_mode']
end

package 'git'

# prep system for ruby
include_recipe 'build-essential'
case node['platform']
when 'debian', 'ubuntu'
  package 'ruby devel dependencies' do
    package_name %w(libssl-dev libreadline-dev zlib1g-dev)
  end
when 'centos', 'redhat', 'amazon', 'scientific', 'oracle', 'fedora'
  package 'ruby devel dependencies' do
    package_name %w(bzip2 openssl-devel readline-devel zlib-devel)
  end
end

include_recipe 'ruby_build'
