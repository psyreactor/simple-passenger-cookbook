require 'spec_helper'

describe 'simple_passenger::default' do
  context 'runs Passenger app(s) from attributes' do
    let(:passengerfile) { '/opt/passenger/attributes-app/Passengerfile.json' }
    let(:passengerfile_options) { JSON.parse(File.read(passengerfile)) }

    it 'creates Passengerfile.json' do
      expect(file(passengerfile)).to be_file
      expect(passengerfile_options).to eq({
        'daemonize' => true,
        'environment' => 'attributes-app-environment',
        'log_file' => '/var/log/passenger/attributes-app/attributes-app.log',
        'pid_file' => '/var/run/passenger/attributes-app.pid',
        'port' => 8080,
        'ruby' => '/usr/local/ruby/2.2.5/bin/ruby',
        'user' => 'attributes-app'
      })
    end

    context 'simple sinatra app' do
      it 'is running' do
        res = Net::HTTP.get_response(URI('http://localhost:8080/'))
        expect(res.code).to eq('200')
        expect(res.body).to eq(
          "SimpleApp is up and running!\nrack app environment: attributes-app-environment\n"
        )
      end
    end
  end
end

describe 'another cookbook calls the lwrp to run a Passenger app' do
  # simple_passenger_app 'fixture-cookbook-app' do
  #   app_name 'lwrp-app'
  #   git_repo 'https://github.com/atheiman/simple-sinatra.git'
  #   bundler_version '= 1.12.6'
  #   passengerfile_options ruby: '/opt/chef/embedded/bin/ruby'
  #   passengerfile_mode '777'
  #   logrotate_frequency 'monthly'
  # end

  context 'simple sinatra app' do
    it 'is running' do
      res = Net::HTTP.get_response(URI('http://localhost/'))
      expect(res.code).to eq('200')
      expect(res.body).to eq(
        "SimpleApp is up and running!\nrack app environment: production\n"
      )
    end
  end
end
