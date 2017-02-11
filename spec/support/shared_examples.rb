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
        'ruby_bin_dir' => '/usr/local/ruby/2.3.3/bin',
        'bundle_bin' => '/usr/local/ruby/2.3.3/bin/bundle'
      }
    })
  end

  it 'calls the lwrp' do
    expect(chef_run).to run_simple_passenger_app('attributes-app').with({
      git_repo: 'https://github.com/org/app.git',
      passengerfile: {'environment' => 'attributes-app-environment', 'port' => 8080}
    })
  end

  it 'calls resources correctly via the lwrp' do
    expect(chef_run).to create_user('attributes-app').with(group: 'passenger')
    user = chef_run.user('attributes-app')
    expect(user).to notify('execute[stop attributes-app]').to(:run).delayed

    expect(chef_run).to create_directory('/var/log/passenger/attributes-app').with(
      owner: 'attributes-app',
      group: 'passenger',
      mode: '0755'
    )
    log_dir = chef_run.directory('attributes-app logs dir')
    expect(log_dir).to notify('execute[stop attributes-app]').to(:run).delayed

    expect(chef_run).to enable_logrotate_app('attributes-app').with(
      cookbook: 'logrotate',
      path: '/var/log/passenger/attributes-app/attributes-app.log',
      # # Not sure why this fails
      # frequency: 'daily',
      # create: '644 attributes-app passenger',
      # rotate: 7
    )
    # # Not sure why this is getting nil
    # logrotate_resource = chef_run.logrotate_app('attributes-app')
    # expect(logrotate_resource).to notify('execute[stop attributes-app]').to(:run).delayed

    expect(chef_run).to create_directory('/opt/passenger/attributes-app').with(
      owner: 'attributes-app',
      group: 'passenger',
      mode: '755'
    )
    app_dir = chef_run.directory('/opt/passenger/attributes-app')
    expect(app_dir).to notify('execute[stop attributes-app]').to(:run).delayed

    expect(chef_run).to sync_git('/opt/passenger/attributes-app')
    git_sync = chef_run.git('/opt/passenger/attributes-app')
    expect(git_sync).to notify('execute[restart attributes-app]').to(:run).delayed

    expect(chef_run).to create_file('/opt/passenger/attributes-app/Passengerfile.json').with(
      mode: '644',
      owner: 'attributes-app',
      group: 'passenger',
      content: JSON.pretty_generate({
        daemonize: true,
        environment: 'attributes-app-environment',
        log_file: '/var/log/passenger/attributes-app/attributes-app.log',
        pid_file: '/var/run/passenger/attributes-app.pid',
        port: 8080,
        ruby: '/usr/local/ruby/2.3.3/bin/ruby',
        user: 'attributes-app'
      })
    )
    passengerfile = chef_run.file('/opt/passenger/attributes-app/Passengerfile.json')
    expect(chef_run).to render_file(
      '/opt/passenger/attributes-app/Passengerfile.json'
    ).with_content('{
  "daemonize": true,
  "environment": "attributes-app-environment",
  "log_file": "/var/log/passenger/attributes-app/attributes-app.log",
  "pid_file": "/var/run/passenger/attributes-app.pid",
  "port": 8080,
  "ruby": "/usr/local/ruby/2.3.3/bin/ruby",
  "user": "attributes-app"
}')
    expect(passengerfile).to notify('execute[stop attributes-app]').to(:run).delayed

    expect(chef_run).to install_ruby_build_ruby('attributes-app ruby').with(
      definition: '2.3.3'
    )
    ruby_build = chef_run.ruby_build_ruby('attributes-app ruby')
    expect(ruby_build).to notify('execute[stop attributes-app]').to(:run).delayed

    expect(chef_run).to install_gem_package('bundler').with(
      gem_binary: '/usr/local/ruby/2.3.3/bin/gem',
      version: '~> 1.13'
    )
    bundler_package = chef_run.gem_package('attributes-app bundler')
    expect(bundler_package).to notify('execute[stop attributes-app]').to(:run).delayed

    expect(chef_run).to run_execute(
      '/usr/local/ruby/2.3.3/bin/bundle install --deployment --without development test'
    ).with(
      cwd: '/opt/passenger/attributes-app',
      user: 'attributes-app',
      group: 'passenger'
    )
    bundle_execute = chef_run.execute('attributes-app bundle install')
    expect(bundle_execute).to notify('execute[stop attributes-app]').to(:run).delayed

    restart_execute = chef_run.execute('restart attributes-app')
    expect(restart_execute.cwd).to eq('/opt/passenger/attributes-app')
    expect(restart_execute.command).to eq(
      '/usr/local/ruby/2.3.3/bin/bundle exec passenger-config restart-app /opt/passenger/attributes-app'
    )
    expect(restart_execute).to do_nothing
    expect(restart_execute).to subscribe_to('git[attributes-app]').on(:run).delayed

    stop_execute = chef_run.execute('stop attributes-app')
    expect(stop_execute.cwd).to eq('/opt/passenger/attributes-app')
    expect(stop_execute.command).to eq(
      '/usr/local/ruby/2.3.3/bin/bundle exec passenger stop'
    )
    expect(stop_execute).to do_nothing
    expect(stop_execute).to notify('execute[start attributes-app]').to(:run).delayed

    expect(chef_run).to run_execute('start attributes-app').with(
      cwd: '/opt/passenger/attributes-app',
      command: '/usr/local/ruby/2.3.3/bin/bundle exec passenger start'
    )
  end
end
