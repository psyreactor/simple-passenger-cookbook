require 'bundler/setup'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc 'Run Test Kitchen integration tests'
namespace :integration do
  def kitchen_instances(regexp, config)
    instances = Kitchen::Config.new(config).instances
    return instances if regexp.nil? || regexp == 'all'
    instances.get_all(Regexp.new(regexp))
  end

  def run_kitchen(action, regexp, concurrency, loader_config = {})
    action = 'test' if action.nil?
    require 'kitchen'
    Kitchen.logger = Kitchen.default_file_logger
    config = { loader: Kitchen::Loader::YAML.new(loader_config) }
    if concurrency
      threads = []
      kitchen_instances(regexp, config).each do |instance|
        threads << Thread.new do
          instance.send(action)
        end
      end
      threads.map(&:join)
    else
      kitchen_instances(regexp, config).each { |i| i.send(action) }
    end
  end

  def bool(str)
    %w(true yes 1).include?(str.to_s.downcase.strip)
  end

  desc 'Run integration tests with kitchen-vagrant'
  task :vagrant, [:action, :regexp, :concurrency] do |_t, args|
    run_kitchen(args.action, args.regexp, bool(args.concurrency))
  end

  desc 'Run integration tests with kitchen-docker'
  task :docker, [:action, :regexp, :concurrency] do |_t, args|
    run_kitchen(
      args.action,
      args.regexp,
      bool(args.concurrency),
      local_config: '.kitchen.docker.yml'
    )
  end
end
