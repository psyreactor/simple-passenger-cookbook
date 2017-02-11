require 'spec_helper'

describe 'another cookbook calls the lwrp to run a Passenger app' do
  let(:passengerfile_path) { '/opt/passenger/lwrp-app/Passengerfile.json' }
  let(:passengerfile) { JSON.parse(File.read(passengerfile_path)) }

  it 'creates Passengerfile.json' do
    expect(file(passengerfile_path)).to be_file
    expect(passengerfile).to eq({
      'daemonize' => true,
      'environment' => 'production',
      'log_file' => '/var/log/passenger/lwrp-app/lwrp-app.log',
      'pid_file' => '/var/run/passenger/lwrp-app.pid',
      'port' => 80,
      'ruby' => '/usr/local/ruby/2.3.3/bin/ruby',
      'user' => 'lwrp-app'
    })
  end

  it 'app is running' do
    res = Net::HTTP.get_response(URI('http://localhost/'))
    expect(res.code).to eq('200')
    expect(res.body).to eq(
      "SimpleApp is up and running!\nrack app environment: production\n"
    )
  end
end
