shared_examples 'default recipe behavior' do
  it 'calls common resources' do
    expect(chef_run).to create_group('passenger')

    expect(chef_run).to create_directory('/opt/passenger').with(
      group: 'passenger',
      mode: '0755'
    )

    expect(chef_run).to create_directory('/var/log/passenger').with(
      group: 'passenger',
      mode: '0755'
    )

    expect(chef_run).to include_recipe('logrotate')

    expect(chef_run).to create_directory('/var/run/passenger').with(
      group: 'passenger',
      mode: '0755'
    )

    expect(chef_run).to install_package('git')

    expect(chef_run).to include_recipe('build-essential')

    expect(chef_run).to include_recipe('ruby_build')
  end

  it 'sets run_state local vars correctly in the lwrp action' do
    expect(chef_run.node.run_state['passenger']).to eq({
      'attributes-app' => {
        'app_root' => '/opt/passenger/attributes-app',
        'log_dir' => '/var/log/passenger/attributes-app',
        'log_file' => '/var/log/passenger/attributes-app/attributes-app.log',
        'pid_file' => '/var/run/passenger/attributes-app.pid',
        'ruby_bin_dir' => '/usr/local/ruby/2.2.5/bin',
        'bundle_bin' => '/usr/local/ruby/2.2.5/bin/bundle'
      }
    })
  end

  it 'calls the lwrp' do
    expect(chef_run).to run_simple_passenger_app('attributes-app').with({
      git_repo: 'https://github.com/org/app.git',
      passengerfile_options: {'environment' => 'attributes-app-environment', 'port' => 8080}
    })
  end

  it 'calls resources correctly via the lwrp' do
    expect(chef_run).to create_user('attributes-app').with(group: 'passenger')
    user = chef_run.user('attributes-app')
    expect(user).to notify('execute[stop attributes-app]').to(:run).delayed

    # # create log dir for app
    # directory "#{app_name} logs dir" do
    #   path node.run_state['passenger'][app_name]['log_dir']
    #   owner app_name
    #   group node['passenger']['group']
    #   mode log_dir_mode
    #   notifies :run, "execute[stop #{app_name}]"
    # end

    # # enable log rotation for the log
    # logrotate_app app_name do
    #   cookbook 'logrotate'
    #   path log_file
    #   frequency logrotate_frequency
    #   create "644 #{app_name} #{node['passenger']['group']}"
    #   rotate logrotate_rotate
    #   notifies :run, "execute[stop #{app_name}]"
    # end

    # # create app root
    # directory "#{app_name} dir" do
    #   path node.run_state['passenger'][app_name]['app_root']
    #   owner app_name
    #   group node['passenger']['group']
    #   mode '755'
    #   notifies :run, "execute[stop #{app_name}]"
    # end

    # # git app code
    # git app_name do
    #   destination node.run_state['passenger'][app_name]['app_root']
    #   repository git_repo
    #   revision git_revision
    #   user app_name
    #   group node['passenger']['group']
    #   # this is somewhat unnecessary because restart resource already subscribes to this resource
    #   notifies :run, "execute[restart #{app_name}]"
    # end

    # # create the Passengerfile.json
    # template "#{app_name} Passengerfile" do
    #   path ::File.join(node.run_state['passenger'][app_name]['app_root'], 'Passengerfile.json')
    #   source 'Passengerfile.json.erb'
    #   cookbook 'simple_passenger'
    #   mode passengerfile_mode
    #   owner app_name
    #   group node['passenger']['group']
    #   variables({
    #     options: {
    #       daemonize: true,
    #       port: 80,
    #       environment: 'production',
    #       log_file: node.run_state['passenger'][app_name]['log_file'],
    #       pid_file: node.run_state['passenger'][app_name]['pid_file'],
    #       user: app_name,
    #       ruby: ::File.join(node.run_state['passenger'][app_name]['ruby_bin_dir'], 'ruby')
    #     }.merge(
    #       # convert all keys to symbols before merge
    #       Hash[passengerfile_options.map { |k,v| [k.to_sym,v] }]
    #     )
    #   })
    #   notifies :run, "execute[stop #{app_name}]"
    # end

    # # install ruby
    # ruby_build_ruby "#{app_name} ruby" do
    #   definition ruby_version
    #   notifies :run, "execute[stop #{app_name}]"
    # end

    # # install bundler
    # gem_package "#{app_name} bundler" do
    #   package_name 'bundler'
    #   gem_binary ::File.join(node.run_state['passenger'][app_name]['ruby_bin_dir'], 'gem')
    #   version bundler_version
    #   notifies :run, "execute[stop #{app_name}]"
    # end


  end
end
  # it 'creates the user and group to run the app' do
  #   expect(chef_run).to create_group(passenger_group)
  #   expect(chef_run.user('passenger')).to notify('execute[stop app]').to(:run).delayed
  #   expect(chef_run).to create_user(passenger_user).with(group: passenger_group)
  #   expect(chef_run.group('passenger')).to notify('execute[stop app]').to(:run).delayed
  # end

  # it 'creates the log directory with logrotate' do
  #   expect(chef_run).to create_directory(log_dir).with(
  #     owner: passenger_user,
  #     group: passenger_group,
  #     mode: '0774'
  #   )
  #   expect(chef_run.directory(log_dir)).to notify('execute[stop app]').to(:run).delayed

  #   expect(chef_run).to enable_logrotate_app(app_name).with(
  #     cookbook: 'logrotate',
  #     path: log_dir,
  #     frequency: 'daily',
  #     create: "644 #{passenger_user} #{passenger_group}",
  #     rotate: 7
  #   )
  #   # not sure how to do this:
  #   #expect(chef_run.log_rotate(app_name)).to notify('execute[stop app]').to(:run).delayed
  # end

  # it 'creates directories for the app' do
  #   expect(chef_run).to create_directory(pid_dir).with(
  #     user: passenger_user,
  #     group: passenger_group,
  #     mode: '0774'
  #   )
  #   expect(chef_run.directory(pid_dir)).to notify('execute[stop app]').to(:run).delayed

  #   expect(chef_run).to create_directory(app_dir).with(
  #     user: passenger_user,
  #     group: passenger_group,
  #     mode: '0774'
  #   )
  #   expect(chef_run.directory(app_dir)).to notify('execute[stop app]').to(:run).delayed

  #   expect(chef_run).to install_package('git')
  #   expect(chef_run).to sync_git('app').with(
  #     destination: app_dir,
  #     repository: git_repo,
  #     revision: git_revision,
  #     user: passenger_user,
  #     group: passenger_group
  #   )
  #   expect(chef_run.git('app')).to notify('execute[restart app]').to(:run).delayed
  # end

  # it 'templates the passengerfile' do
  #   expect(chef_run).to create_template(File.join(app_dir, 'Passengerfile.json')).with(
  #     mode: '0664',
  #     owner: passenger_user,
  #     group: passenger_group,
  #     variables: {options: passengerfile_options}
  #   )

  #   expect(chef_run).to render_file(File.join(app_dir, 'Passengerfile.json')).with_content(
  #     Chef::JSONCompat.to_json_pretty(Hash[passengerfile_options.sort])
  #   )
  #   expect(
  #     chef_run.template(File.join(app_dir, 'Passengerfile.json'))
  #   ).to notify('execute[stop app]').to(:run).delayed
  # end

  # it 'installs ruby' do
  #   expect(chef_run).to include_recipe('build-essential')
  #   expect(chef_run.package('ruby devel dependencies')).to notify('execute[stop app]').to(:run).delayed

  #   expect(chef_run).to include_recipe('ruby_build')
  #   expect(chef_run).to install_ruby_build_ruby("app ruby version #{ruby_version}").with(
  #     definition: ruby_version
  #   )
  #   # not sure how to do this:
  #   #expect(
  #   #  chef_run.ruby_build_ruby("app ruby version #{ruby_version}")
  #   #).to notify('execute[stop app]').to(:run).delayed
  #   expect(chef_run).to install_gem_package('bundler').with(
  #     gem_binary: File.join(ruby_bin_dir, 'gem'),
  #     version: '~> 1.12.0'
  #   )
  #   expect(chef_run.gem_package('bundler')).to notify('execute[stop app]').to(:run).delayed

  #   expect(chef_run).to run_execute(
  #     "#{ruby_bin_dir}/bundle install --deployment --without development test"
  #   ).with(
  #     cwd: app_dir,
  #     user: passenger_user,
  #     group: passenger_group
  #   )
  #   expect(chef_run.execute('bundle install')).to notify('execute[stop app]').to(:run).delayed
  # end

  # it 'has resources for starting, stopping, and restarting the app' do
  #   # restart execute resource
  #   restart_execute = chef_run.execute('restart app')
  #   expect(restart_execute.cwd).to eq(app_dir)
  #   expect(restart_execute.command).to eq(
  #     "#{ruby_bin_dir}/bundle exec passenger-config restart-app #{app_dir}"
  #   )
  #   expect(restart_execute).to do_nothing
  #   expect(restart_execute).to subscribe_to('git[app]').on(:run).delayed

  #   # stop execute resource
  #   stop_execute = chef_run.execute('stop app')
  #   expect(stop_execute.cwd).to eq(app_dir)
  #   expect(stop_execute.command).to eq(
  #     "#{ruby_bin_dir}/bundle exec passenger stop"
  #   )
  #   expect(stop_execute).to do_nothing
  #   expect(stop_execute).to notify('execute[start app]').to(:run).delayed

  #   # start execute resource
  #   expect(chef_run).to run_execute('start app').with(
  #     cwd: app_dir,
  #     command: "#{ruby_bin_dir}/bundle exec passenger start"
  #   )
  # end
