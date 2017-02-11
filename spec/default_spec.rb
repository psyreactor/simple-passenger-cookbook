require 'spec_helper'

describe 'simple_passenger::default' do
  # required attributes
  let(:git_repo) { 'https://github.com/some-org/some-app.git' }

  before do
    stub_command('git --version >/dev/null')
    stub_command(/bundle check/).and_return(false) # force bundle install
    stub_command(/bundle install/) # this should always work
    stub_command(/bundle exec/) # this should always work
  end

  context 'centos' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(
        step_into: ['simple_passenger_app'],
        platform: 'centos',
        version: '6.6'
      ) do |node|
        node.set['passenger']['apps']['attributes-app'].tap do |app|
          app['git_repo'] = 'https://github.com/org/app.git'
          app['passengerfile'] = {
            'port' => 8080,
            environment: 'attributes-app-environment'
          }
        end
      end.converge(described_recipe)
    end

    include_examples 'default recipe behavior'

    it 'installs rhel-specific ruby devel dependencies' do
      expect(chef_run).to install_package('ruby devel dependencies').with(
        package_name: %w(bzip2 openssl-devel readline-devel zlib-devel)
      )
    end
  end

  context 'ubuntu' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(
        step_into: ['simple_passenger_app'],
        platform: 'ubuntu',
        version: '16.04'
      ) do |node|
        node.set['passenger']['apps']['attributes-app'].tap do |app|
          app['git_repo'] = 'https://github.com/org/app.git'
          app['passengerfile'] = {
            'port' => 8080,
            environment: 'attributes-app-environment'
          }
        end
      end.converge(described_recipe)
    end

    include_examples 'default recipe behavior'

    it 'installs ubuntu-specific ruby devel dependencies' do
      expect(chef_run).to install_package('ruby devel dependencies').with(
        package_name: %w(libssl-dev libreadline-dev zlib1g-dev)
      )
    end
  end
end
