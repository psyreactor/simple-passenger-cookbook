actions :run, :stop
default_action :run

property :name, String, required: true, name_attribute: true
property :user, String, required: true, default: 'passenger'

property :git_repo, String, required: true
property :git_revision, String, required: true, default: 'master'

property :ruby_version, String, required: true, default: '2.2.5'
property :bundler_version, String, required: true, default: '~> 1.12.0'

# passengerfile options are merged with sensible defaults
property :passengerfile_options, Hash, required: false, default: {}
property :passengerfile_mode, String, required: false, default: '764'

# defaults based on app name
property :app_root, String, required: false
property :log_file, String, required: false
property :pid_file, String, required: false

#property :app_root_mode, String, required: true, default: '744'
property :log_file_mode, String, required: true, default: '644'
property :pid_file_mode, String, required: true, default: '644'

property :logrotate_frequency, String, required: true, default: 'daily'
property :logrotate_rotate, Integer, required: true, default: 7
