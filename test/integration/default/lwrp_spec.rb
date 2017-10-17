describe json('/opt/passenger/lwrp-app/Passengerfile.json') do
  its('daemonize') { should eq true }
  its('environment') { should eq 'production' }
  its('log_file') { should eq '/var/log/passenger/lwrp-app/lwrp-app.log' }
  its('pid_file') { should eq '/var/run/passenger/lwrp-app.pid' }
  its('port') { should eq 80 }
  its('ruby') { should eq '/usr/local/ruby/2.4.0/bin/ruby' }
  its('user') { should eq 'lwrp-app' }
end

describe command('curl http://localhost/') do
  its('exit_status') { should eq 0 }
  its('stdout') do
    should eq "SimpleApp is up and running!\nrack app environment: production\n"
  end
end
