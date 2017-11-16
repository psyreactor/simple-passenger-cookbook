require 'json'

property :app_name, String, required: true, name_attribute: true, regex: /^[\w\.-]+$/

property :git_repo, String, required: true
property :git_revision, String, required: true, default: 'master'

property :ruby_version, String, required: true, default: '2.3.3'
property :ruby_bin, String
property :bundler_version, String, required: true, default: '~> 1.13.7'

# passengerfile options are merged with sensible defaults
property :passengerfile, Hash, required: false, default: {}
property :passengerfile_mode, [String, Integer], required: false, default: '644'

property :log_dir_mode, [String, Integer], required: true, default: '0755'
property :logrotate_frequency, String, required: true, default: 'daily'
property :logrotate_rotate, Integer, required: true, default: 7


default_action :run

action :run do
  Chef::Log.info("simple_passenger_app run action called with #{new_resource.inspect}")

  node.run_state['passenger'][app_name] = {}
  node.run_state['passenger'][app_name]['app_root'] = ::File.join(
    node['passenger']['apps_dir'],
    new_resource.app_name
  )
  node.run_state['passenger'][app_name]['log_dir'] = ::File.join(
    node['passenger']['logs_root'],
    new_resource.app_name
  )
  node.run_state['passenger'][app_name]['log_file'] = ::File.join(
    node.run_state['passenger'][app_name]['log_dir'],
    "#{app_name}.log"
  )
  # run_state[...] cannot be passed into logrotate_app lwrp for some reason. Store this in run_state
  # and local var
  log_file = node.run_state['passenger'][app_name]['log_file']
  node.run_state['passenger'][app_name]['pid_file'] = ::File.join(
    node['passenger']['pid_files_dir'],
    "#{app_name}.pid"
  )
  if ruby_bin
    node.run_state['passenger'][app_name]['ruby_bin_dir'] = ::File.split(ruby_bin).first
  else
    node.run_state['passenger'][app_name]['ruby_bin_dir'] = ::File.join(
      node['ruby_build']['default_ruby_base_path'],
      ruby_version,
      'bin'
    )
  end
  node.run_state['passenger'][app_name]['bundle_bin'] = ::File.join(
    node.run_state['passenger'][app_name]['ruby_bin_dir'],
    'bundle'
  )

  # restart the app (if app was running)
  execute "restart #{app_name}" do
    action :nothing
    command "#{node.run_state['passenger'][app_name]['bundle_bin']} exec" \
      " passenger-config restart-app #{node.run_state['passenger'][app_name]['app_root']}"
    cwd node.run_state['passenger'][app_name]['app_root']
    # only restart the app if the app is already running
    only_if { ::File.exist?(node.run_state['passenger'][app_name]['pid_file']) }
    # should be run on any of the following changes
    subscribes :run, "git[#{app_name}]"
  end

  # stop the app (if something has changed)
  execute "stop #{app_name}" do
    action :nothing
    command "#{node.run_state['passenger'][app_name]['bundle_bin']} exec passenger stop"
    cwd node.run_state['passenger'][app_name]['app_root']
    # only stop the app if running
    only_if { ::File.exist?(node.run_state['passenger'][app_name]['pid_file']) }
    # start the app after stop (a dependency is updating, not just an app code upgrade)
    notifies :run, "execute[start #{app_name}]"
  end

  # create user for the app
  user app_name do
    group node['passenger']['group']
    notifies :run, "execute[stop #{app_name}]"
  end

  # create log dir for app
  directory "#{app_name} logs dir" do
    path node.run_state['passenger'][app_name]['log_dir']
    owner app_name
    group node['passenger']['group']
    mode log_dir_mode
    notifies :run, "execute[stop #{app_name}]"
  end

  # enable log rotation for the log
  logrotate_app app_name do
    cookbook 'logrotate'
    path log_file
    frequency logrotate_frequency
    create "644 #{app_name} #{node['passenger']['group']}"
    rotate logrotate_rotate
    notifies :run, "execute[stop #{app_name}]"
  end

  # create app root
  directory "#{app_name} dir" do
    path node.run_state['passenger'][app_name]['app_root']
    owner app_name
    group node['passenger']['group']
    mode '755'
    notifies :run, "execute[stop #{app_name}]"
  end

  # git app code
  git app_name do
    destination node.run_state['passenger'][app_name]['app_root']
    repository git_repo
    revision git_revision
    user app_name
    group node['passenger']['group']
    # this is somewhat unnecessary because restart resource already subscribes to this resource
    notifies :run, "execute[restart #{app_name}]"
  end

  # create the Passengerfile.json
  file "#{app_name} Passengerfile" do
    path ::File.join(node.run_state['passenger'][app_name]['app_root'], 'Passengerfile.json')
    mode passengerfile_mode
    owner app_name
    group node['passenger']['group']

    config = {
      daemonize: true,
      port: 80,
      environment: 'production',
      log_file: node.run_state['passenger'][app_name]['log_file'],
      pid_file: node.run_state['passenger'][app_name]['pid_file'],
      user: app_name,
      ruby: ::File.join(node.run_state['passenger'][app_name]['ruby_bin_dir'], 'ruby')
    }.merge(
      # convert all keys to symbols before merge
      Hash[passengerfile.map { |k,v| [k.to_sym,v] }]
    )
    content(JSON.pretty_generate(Hash[ config.sort_by { |k,_v| k.to_s } ]))

    notifies :run, "execute[stop #{app_name}]"
  end

  unless ruby_bin
    # install ruby
    ruby_build_ruby "#{app_name} ruby" do
      definition ruby_version
      notifies :run, "execute[stop #{app_name}]"
    end
  end

  # install bundler
  gem_package "#{app_name} bundler" do
    package_name 'bundler'
    gem_binary ::File.join(node.run_state['passenger'][app_name]['ruby_bin_dir'], 'gem')
    version bundler_version
    notifies :run, "execute[stop #{app_name}]"
  end

  # install gem dependencies
  execute "#{app_name} bundle install" do
    command "#{node.run_state['passenger'][app_name]['bundle_bin']} install --deployment" \
      " --without development test"
    cwd node.run_state['passenger'][app_name]['app_root']
    user app_name
    group node['passenger']['group']
    not_if "#{node.run_state['passenger'][app_name]['bundle_bin']} check",
      cwd: node.run_state['passenger'][app_name]['app_root']
    notifies :run, "execute[stop #{app_name}]"
  end

  # start the app (if app was not running)
  execute "start #{app_name}" do
    command "#{node.run_state['passenger'][app_name]['bundle_bin']} exec passenger start"
    cwd node.run_state['passenger'][app_name]['app_root']
    # dont start the app if the app is already running
    # this is somewhat unnecessary because start app should run if app is was stopped
    not_if { ::File.exist?(node.run_state['passenger'][app_name]['pid_file']) }
  end
end

action :stop do
  Chef::Log.info("simple_passenger_app stop action called with #{new_resource.inspect}")

  node.run_state['passenger'][app_name] = {}
  node.run_state['passenger'][app_name]['app_root'] = ::File.join(
    node['passenger']['apps_dir'],
    new_resource.app_name
  )
  node.run_state['passenger'][app_name]['pid_file'] = ::File.join(
    node['passenger']['pid_files_dir'],
    "#{app_name}.pid"
  )
  if ruby_bin
    node.run_state['passenger'][app_name]['ruby_bin_dir'] = ::File.split(ruby_bin).first
  else
    node.run_state['passenger'][app_name]['ruby_bin_dir'] = ::File.join(
      node['ruby_build']['default_ruby_base_path'],
      ruby_version,
      'bin'
    )
  end
  node.run_state['passenger'][app_name]['bundle_bin'] = ::File.join(
    node.run_state['passenger'][app_name]['ruby_bin_dir'],
    'bundle'
  )

  # stop the app
  execute "stop #{app_name}" do
    action :nothing
    command "#{node.run_state['passenger'][app_name]['bundle_bin']} exec passenger stop"
    cwd node.run_state['passenger'][app_name]['app_root']
    # only stop the app if running
    only_if { ::File.exist?(node.run_state['passenger'][app_name]['pid_file']) }
  end
end
