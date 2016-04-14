default['passenger']['user'] = 'passenger'
default['passenger']['group'] = 'passenger'
default['passenger']['app_name'] = 'default_app'
default['passenger']['log_dir'] = File.join('/var/log', default.passenger.app_name)
default['passenger']['log_dir_mode'] = '0774'
default['passenger']['app_dir'] = File.join('/opt', default.passenger.app_name)
default['passenger']['app_dir_mode'] = '0774'
default['passenger']['git_repo'] = 'https://github.com/atheiman/simple-sinatra.git'
default['passenger']['git_revision'] = 'master'
default['passenger']['ruby_version'] = '2.2.3'
default['passenger']['ruby_dir'] = File.join(default.ruby_build.default_ruby_base_path,
                                             default.passenger.ruby_version)
default['passenger']['pid_dir'] = File.join('/var/run/', default.passenger.app_name)
default['passenger']['pid_dir_mode'] = '0774'

# passenger server config - https://www.phusionpassenger.com/library/config/standalone/reference/
default['passenger']['passengerfile_mode'] = '0664'
default['passenger']['passengerfile']['daemonize'] = true
default['passenger']['passengerfile']['port'] = 80
default['passenger']['passengerfile']['log_file'] = File.join(default.passenger.log_dir, default.passenger.app_name)
default['passenger']['passengerfile']['pid_file'] = File.join(default.passenger.pid_dir, default.passenger.app_name + '.pid')
default['passenger']['passengerfile']['user'] = default.passenger.user
default['passenger']['passengerfile']['ruby'] = File.join(default.passenger.ruby_dir, 'bin/ruby')
default['passenger']['passengerfile']['environment'] = 'production'
