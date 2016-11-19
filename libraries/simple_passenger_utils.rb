module SimplePassengerUtils
  # complex defaulting of resource properties

  def passengerfile_options(resource)
    {
      'daemonize' => true,
      'port' => 80,
      'environment' => 'production',
      'log_file' => log_file(resource),
      'pid_file' => pid_file(resource),
      'user' => node['passenger']['user'],
      'ruby' => File.join(ruby_bin_dir(resource), 'ruby')
    }.merge(resource.passengerfile_options)
  end

  def ruby_bin_dir(resource)
    File.join(
      node['ruby_build']['default_ruby_base_path'],
      resource.ruby_version,
      'bin'
    )
  end

  def app_root(resource)
    resource.app_root || File.join(node['passenger']['apps_dir'], resource.name)
  end

  def log_file(resource)
    resource.log_file || File.join(node['passenger']['logs_dir'], "#{resource.name}.log")
  end

  def pid_file(resource)
    resource.pid_file || File.join(node['passenger']['pid_files_dir'], "#{resource.name}.pid")
  end
end
