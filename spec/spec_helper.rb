require 'chefspec'
require 'chefspec/berkshelf'

current_dir = File.dirname(File.expand_path(__FILE__))

Dir[File.join(current_dir, 'support/**/*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.log_level = :fatal
end

# https://github.com/chef-rbenv/ruby_build/pull/51 submitted to upstream
ChefSpec.define_matcher(:ruby_build_ruby)
def install_ruby_build_ruby(name)
  ChefSpec::Matchers::ResourceMatcher.new(:ruby_build_ruby, :install, name)
end
def reinstall_ruby_build_ruby(name)
  ChefSpec::Matchers::ResourceMatcher.new(:ruby_build_ruby, :reinstall, name)
end

# https://github.com/stevendanna/logrotate/pull/103 submitted to upstream
ChefSpec.define_matcher(:logrotate_app)

at_exit { ChefSpec::Coverage.report! }
