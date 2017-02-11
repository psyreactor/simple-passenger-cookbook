simple_passenger_app 'fixture-cookbook-app' do
  app_name 'lwrp-app'
  git_repo 'https://github.com/atheiman/simple-sinatra.git'
  bundler_version '= 1.12.6'
  ruby_version '2.3.3'
end
