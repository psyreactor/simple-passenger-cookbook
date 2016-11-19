group 'Passenger' do
  group_name node['passenger']['group']
end

directory 'Passenger apps dir' do
  path node['passenger']['apps_dir']
  group node['passenger']['group']
  mode node['passenger']['apps_dir_mode']
end

directory 'Passenger logs root' do
  path node['passenger']['logs_root']
  group node['passenger']['group']
  mode node['passenger']['logs_root_mode']
end

# make logrotate_app lwrp available
include_recipe 'logrotate'

directory 'Passenger pid files dir' do
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


node.run_state['passenger'] = {}

# build apps from attributes
if node['passenger']['apps'].is_a?(Hash)
  node['passenger']['apps'].each do |app_name, app_definition|
    Chef::Log.info(
      "Deploying Passenger app from attribute definition at node['passenger']['apps'][#{app_name.inspect}]"
    )

    simple_passenger_app app_name do
      app_definition.each do |property, value|
        send(property, value)
      end
    end
  end
else
  Chef::Log.info("No Passenger apps found to deploy in node['passenger']['apps'].")
end
