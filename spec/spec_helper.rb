require 'chefspec'
require 'chefspec/berkshelf'

current_dir = File.dirname(File.expand_path(__FILE__))

Dir[File.join(current_dir, 'support/**/*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.log_level = :fatal
end

# currently no chefspec matcher is provided by https://github.com/chef-rbenv/ruby_build
def install_ruby_build_ruby(resource)
  ChefSpec::Matchers::ResourceMatcher.new(:ruby_build_ruby, :install, resource)
end

at_exit { ChefSpec::Coverage.report! }
