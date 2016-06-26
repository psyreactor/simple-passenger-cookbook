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
    require 'kitchen'
    Kitchen.logger = Kitchen.default_file_logger
    action = 'test' if action.nil?
    config = { loader: Kitchen::Loader::YAML.new(loader_config) }

    # minimum concurrent threads is 1
    concurrency = concurrency.to_i < 2 ? 1 : concurrency.to_i
    threads = []
    kitchen_instances(regexp, config).each do |instance|
      until threads.map {|t| t.alive?}.count(true) < concurrency do sleep 5 end
      threads << Thread.new { instance.send(action) }
    end
    threads.map(&:join)
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
