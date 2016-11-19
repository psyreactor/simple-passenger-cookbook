# Commented attributes may be set, otherwise they will be defaulted in a recipe. Search in the
# recipes to determine the default value.
# More information on this approach:
# https://christinemdraper.wordpress.com/2014/10/06/avoiding-the-possible-pitfalls-of-derived-attributes/

default['passenger']['user'] = 'passenger'
default['passenger']['group'] = 'passenger'
default['passenger']['app_name'] = 'default_app'
# default['passenger']['log_dir']
default['passenger']['log_dir_mode'] = '0774'
# default['passenger']['app_dir']
default['passenger']['app_dir_mode'] = '0774'
default['passenger']['git_revision'] = 'master'
default['passenger']['ruby_version'] = '2.2.5'
default['passenger']['bundler_version'] = '~> 1.12.0'
# default['passenger']['pid_dir']
default['passenger']['pid_dir_mode'] = '0774'

default['passenger']['passengerfile_mode'] = '0664'
# passenger server config
# https://www.phusionpassenger.com/library/config/standalone/reference/
default['passenger']['passengerfile']['daemonize'] = true
default['passenger']['passengerfile']['port'] = 80
# default['passenger']['passengerfile']['log_file']
# default['passenger']['passengerfile']['pid_file']
# default['passenger']['passengerfile']['user']
# default['passenger']['passengerfile']['ruby']
default['passenger']['passengerfile']['environment'] = 'production'
