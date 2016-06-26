require 'bundler/setup'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc 'Run Test Kitchen integration tests'
namespace :integration do
  desc 'Run integration tests with kitchen-docker'
  task :docker do
    require 'kitchen'
    Kitchen.logger = Kitchen.default_file_logger
    @loader = Kitchen::Loader::YAML.new(local_config: '.kitchen.docker.yml')
    threads = []
    Kitchen::Config.new(loader: @loader).instances.each do |instance|
      threads << Thread.new do
        instance.test(:always)
      end
    end
    threads.map(&:join)
  end
end
