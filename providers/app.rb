include SimplePassengerUtils

action :run do
  # restart the app (if app was running)
  execute "restart #{new_resource.name}" do
    action :nothing
    command "#{File.join(ruby_bin_dir(new_resource), 'bundle')} exec passenger-config restart-app #{app_root(new_resource)}"
    cwd app_root(new_resource)
    # only restart the app if the app is already running
    only_if { File.exist?(pid_file(new_resource)) }
    # should be run on any of the following changes
    subscribes :run, "git[#{new_resource.name}]"
  end

  # stop the app (if something has changed)
  execute "stop #{new_resource.name}" do
    action :nothing
    command "#{File.join(ruby_bin_dir(new_resource), 'bundle')} exec passenger stop"
    cwd app_root(new_resource)
    # only stop the app if running
    only_if { File.exist?(pid_file(new_resource)) }
    # start the app after stop (a dependency is updating, not just an app code upgrade)
    notifies :run, "execute[start #{new_resource.name}]"
  end

  user new_resource.user do
    group node['passenger']['group']
  end

  # enable log rotation for the log directory
  logrotate_app new_resource.name do
    cookbook 'logrotate'
    path log_file(new_resource)
    frequency new_resource.logrotate_frequency
    create "644 #{new_resource.user} #{node['passenger']['group']}"
    rotate new_resource.logrotate_rotate
    notifies :run, "execute[stop #{new_resource.name}]"
  end

  # # create app root
  # directory "#{new_resource.name} dir" do
  #   path app_root(new_resource)
  #   owner new_resource.user
  #   group node['passenger']['group']
  #   mode new_resource.app_root_mode
  #   notifies :run, "execute[stop #{new_resource.name}]"
  # end

  git new_resource.name do
    destination app_root(new_resource)
    repository new_resource.git_repo
    revision new_resource.git_revision
    user new_resource.user
    group node['passenger']['group']
    # this is somewhat unnecessary because restart resource already subscribes to this resource
    notifies :run, "execute[restart #{new_resource.name}]"
  end

  # create the Passengerfile.json
  template "#{new_resource.name} Passengerfile" do
    path File.join(app_root(new_resource), 'Passengerfile.json')
    source 'Passengerfile.json.erb'
    mode new_resource.passengerfile_mode
    owner new_resource.user
    group node['passenger']['group']
    variables options: passengerfile_options(new_resource)
    notifies :run, "execute[stop #{new_resource.name}]"
  end

  # install ruby
  ruby_build_ruby "#{new_resource.name} ruby" do
    definition new_resource.ruby_version
    notifies :run, "execute[stop #{new_resource.name}]"
  end

  # install bundler
  gem_package "#{new_resource.name} bundler" do
    gem_binary File.join(ruby_bin_dir(new_resource), 'gem')
    version new_resource.bundler_version
    notifies :run, "execute[stop #{new_resource.name}]"
  end

  # install gem dependencies
  execute "#{new_resource.name} bundle install" do
    command "#{File.join(ruby_bin_dir(new_resource), 'bundle')} install --deployment --without development test"
    cwd app_root(new_resource)
    user new_resource.user
    group node['passenger']['group']
    not_if "#{File.join(ruby_bin_dir(new_resource), 'bundle')} check", cwd: app_root(new_resource)
    notifies :run, "execute[stop #{new_resource.name}]"
  end

  # start the app (if app was not running)
  execute "start #{new_resource.name}" do
    command "#{File.join(ruby_bin_dir(new_resource), 'bundle')} exec passenger start"
    cwd app_root(new_resource)
    # dont start the app if the app is already running
    # this is somewhat unnecessary because start app should run if app is was stopped
    not_if { File.exist?(pid_file(new_resource)) }
  end
end

action :stop do
  execute "stop #{new_resource.name}" do
    action :nothing
    command "#{File.join(ruby_bin_dir(new_resource), 'bundle')} exec passenger stop"
    cwd app_root(new_resource)
    # only stop the app if running
    only_if { File.exist?(pid_file(new_resource)) }
  end
end
