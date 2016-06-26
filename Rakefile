require 'bundler/setup'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc 'Run Test Kitchen integration tests'
namespace :integration do
  def kitchen_instances(regexp, config)
    instances = Kitchen::Config.new(config).instances
    instances = instances.get_all(Regexp.new(regexp)) unless regexp.nil? || regexp == 'all'
    raise Kitchen::UserError, "regexp '#{regexp}' matched 0 instances" if instances.empty?
    instances
  end

  def correct_concurrency(concurrency)
    # minimum concurrent threads is 1
    concurrency.to_i < 2 ? 1 : concurrency.to_i
  end

  def apply_action_threaded(instances, action, concurrency)
    threads = []
    instances.each do |instance|
      sleep 3 until threads.map(&:alive?).count(true) < concurrency
      threads << Thread.new { instance.send(action) }
    end
    threads.map(&:join)
  end

  def run_kitchen(action, regexp, concurrency, loader_config = {})
    require 'kitchen'
    Kitchen.logger = Kitchen.default_file_logger
    config = { loader: Kitchen::Loader::YAML.new(loader_config) }

    concurrency = correct_concurrency(concurrency)
    apply_action_threaded(
      kitchen_instances(regexp, config),
      action || 'test',
      correct_concurrency(concurrency)
    )
  end

  desc 'Run integration tests with kitchen-vagrant'
  task :vagrant, [:action, :regexp, :concurrency] do |_t, args|
    run_kitchen(args.action, args.regexp, args.concurrency)
  end

  desc 'Run integration tests with kitchen-docker'
  task :docker, [:action, :regexp, :concurrency] do |_t, args|
    run_kitchen(args.action, args.regexp, args.concurrency, local_config: '.kitchen.docker.yml')
  end
end
