simple_passenger_app 'fixture-cookbook-app' do
  app_name 'lwrp-app'
  git_repo 'https://github.com/atheiman/simple-sinatra.git'
  bundler_version '= 1.12.6'
  passengerfile ruby: '/opt/chef/embedded/bin/ruby'
end
