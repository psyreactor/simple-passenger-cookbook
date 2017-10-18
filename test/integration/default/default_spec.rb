describe json('/opt/passenger/attributes-app/Passengerfile.json') do
  its('daemonize') { should eq true }
  its('environment') { should eq 'attributes-app-environment' }
  its('log_file') { should eq '/var/log/passenger/attributes-app/attributes-app.log' }
  its('pid_file') { should eq '/var/run/passenger/attributes-app.pid' }
  its('port') { should eq 8080 }
  its('ruby') { should eq '/opt/chef/embedded/bin/ruby' }
  its('user') { should eq 'attributes-app' }
end

describe command('curl http://localhost:8080/') do
  its('exit_status') { should eq 0 }
  its('stdout') do
    should eq "SimpleApp is up and running!\nrack app environment: attributes-app-environment\n"
  end
end
