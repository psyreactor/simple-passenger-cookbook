shared_examples 'common attribute setting and resource behavior' do
  it 'sets attributes' do
    expect(chef_run.node.run_state['ruby_bin_dir']).to eq(ruby_bin_dir)
    expect(chef_run.node.run_state['app_dir']).to eq(app_dir)
    expect(chef_run.node.run_state['log_dir']).to eq(log_dir)
    expect(chef_run.node.run_state['pid_dir']).to eq(pid_dir)
    expect(chef_run.node.run_state['passengerfile_options']).to eq(passengerfile_options)

    expect(chef_run.node['passenger']).to eq(
      { 'user' => passenger_user,
        'group' => passenger_group,
        'app_name' => app_name,
        'log_dir_mode' => '0774',
        'app_dir_mode' => '0774',
        'git_revision' => git_revision,
        'ruby_version' => ruby_version,
        'bundler_version' => '~> 1.12.0',
        'pid_dir_mode' => '0774',
        'passengerfile_mode' => '0664',
        'passengerfile' => { 'daemonize' => true, 'port' => 80, 'environment' => 'production' },
        'git_repo' => git_repo }
    )
  end

  it 'creates the user and group to run the app' do
    expect(chef_run).to create_group(passenger_group)
    expect(chef_run.user('passenger')).to notify('execute[stop app]').to(:run).delayed
    expect(chef_run).to create_user(passenger_user).with(group: passenger_group)
    expect(chef_run.group('passenger')).to notify('execute[stop app]').to(:run).delayed
  end

  it 'creates the log directory with logrotate' do
    expect(chef_run).to create_directory(log_dir).with(
      owner: passenger_user,
      group: passenger_group,
      mode: '0774'
    )
    expect(chef_run.directory(log_dir)).to notify('execute[stop app]').to(:run).delayed

    expect(chef_run).to enable_logrotate_app(app_name).with(
      cookbook: 'logrotate',
      path: log_dir,
      frequency: 'daily',
      create: "644 #{passenger_user} #{passenger_group}",
      rotate: 7
    )
    # not sure how to do this:
    #expect(chef_run.log_rotate(app_name)).to notify('execute[stop app]').to(:run).delayed
  end

  it 'creates directories for the app' do
    expect(chef_run).to create_directory(pid_dir).with(
      user: passenger_user,
      group: passenger_group,
      mode: '0774'
    )
    expect(chef_run.directory(pid_dir)).to notify('execute[stop app]').to(:run).delayed

    expect(chef_run).to create_directory(app_dir).with(
      user: passenger_user,
      group: passenger_group,
      mode: '0774'
    )
    expect(chef_run.directory(app_dir)).to notify('execute[stop app]').to(:run).delayed

    expect(chef_run).to install_package('git')
    expect(chef_run).to sync_git('app').with(
      destination: app_dir,
      repository: git_repo,
      revision: git_revision,
      user: passenger_user,
      group: passenger_group
    )
    expect(chef_run.git('app')).to notify('execute[restart app]').to(:run).delayed
  end

  it 'templates the passengerfile' do
    expect(chef_run).to create_template(File.join(app_dir, 'Passengerfile.json')).with(
      mode: '0664',
      owner: passenger_user,
      group: passenger_group,
      variables: {options: passengerfile_options}
    )

    expect(chef_run).to render_file(File.join(app_dir, 'Passengerfile.json')).with_content(
      Chef::JSONCompat.to_json_pretty(Hash[passengerfile_options.sort])
    )
    expect(
      chef_run.template(File.join(app_dir, 'Passengerfile.json'))
    ).to notify('execute[stop app]').to(:run).delayed
  end

  it 'installs ruby' do
    expect(chef_run).to include_recipe('build-essential')
    expect(chef_run.package('ruby devel dependencies')).to notify('execute[stop app]').to(:run).delayed

    expect(chef_run).to include_recipe('ruby_build')
    expect(chef_run).to install_ruby_build_ruby("app ruby version #{ruby_version}").with(
      definition: ruby_version
    )
    # not sure how to do this:
    #expect(
    #  chef_run.ruby_build_ruby("app ruby version #{ruby_version}")
    #).to notify('execute[stop app]').to(:run).delayed
    expect(chef_run).to install_gem_package('bundler').with(
      gem_binary: File.join(ruby_bin_dir, 'gem'),
      version: '~> 1.12.0'
    )
    expect(chef_run.gem_package('bundler')).to notify('execute[stop app]').to(:run).delayed

    expect(chef_run).to run_execute(
      "#{ruby_bin_dir}/bundle install --deployment --without development test"
    ).with(
      cwd: app_dir,
      user: passenger_user,
      group: passenger_group
    )
    expect(chef_run.execute('bundle install')).to notify('execute[stop app]').to(:run).delayed
  end

  it 'has resources for starting, stopping, and restarting the app' do
    # restart execute resource
    restart_execute = chef_run.execute('restart app')
    expect(restart_execute.cwd).to eq(app_dir)
    expect(restart_execute.command).to eq(
      "#{ruby_bin_dir}/bundle exec passenger-config restart-app #{app_dir}"
    )
    expect(restart_execute).to do_nothing
    expect(restart_execute).to subscribe_to('git[app]').on(:run).delayed

    # stop execute resource
    stop_execute = chef_run.execute('stop app')
    expect(stop_execute.cwd).to eq(app_dir)
    expect(stop_execute.command).to eq(
      "#{ruby_bin_dir}/bundle exec passenger stop"
    )
    expect(stop_execute).to do_nothing
    expect(stop_execute).to notify('execute[start app]').to(:run).delayed

    # start execute resource
    expect(chef_run).to run_execute('start app').with(
      cwd: app_dir,
      command: "#{ruby_bin_dir}/bundle exec passenger start"
    )
  end
end
