require 'spec_helper'

describe 'simple_passenger::default' do
  context 'runs Passenger app(s) from attributes' do
    let(:passengerfile_path) { '/opt/passenger/attributes-app/Passengerfile.json' }
    let(:passengerfile) { JSON.parse(File.read(passengerfile_path)) }

    it 'creates Passengerfile.json' do
      expect(file(passengerfile_path)).to be_file
      expect(passengerfile).to eq({
        'daemonize' => true,
        'environment' => 'attributes-app-environment',
        'log_file' => '/var/log/passenger/attributes-app/attributes-app.log',
        'pid_file' => '/var/run/passenger/attributes-app.pid',
        'port' => 8080,
        'ruby' => '/usr/local/ruby/2.2.5/bin/ruby',
        'user' => 'attributes-app'
      })
    end

    it 'app is running' do
      res = Net::HTTP.get_response(URI('http://localhost:8080/'))
      expect(res.code).to eq('200')
      expect(res.body).to eq(
        "SimpleApp is up and running!\nrack app environment: attributes-app-environment\n"
      )
    end
  end
end
