if defined?(ChefSpec)
  ChefSpec.define_matcher(:simple_passenger_app)
  def run_simple_passenger_app(name)
    ChefSpec::Matchers::ResourceMatcher.new(:simple_passenger_app, :run, name)
  end
  def stop_simple_passenger_app(name)
    ChefSpec::Matchers::ResourceMatcher.new(:simple_passenger_app, :stop, name)
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
end
