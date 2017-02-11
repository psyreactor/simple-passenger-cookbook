if defined?(ChefSpec)
  ChefSpec.define_matcher(:simple_passenger_app)
  def run_simple_passenger_app(name)
    ChefSpec::Matchers::ResourceMatcher.new(:simple_passenger_app, :run, name)
  end
  def stop_simple_passenger_app(name)
    ChefSpec::Matchers::ResourceMatcher.new(:simple_passenger_app, :stop, name)
  end
end
