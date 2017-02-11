require 'spec_helper'

describe 'simple_passenger::default' do
  # required attributes
  let(:git_repo) { 'https://github.com/some-org/some-app.git' }
  let(:app) do
    {
      'git_repo' => 'https://github.com/org/app.git',
      'passengerfile' => {
        'port' => 8080,
        environment: 'attributes-app-environment'
      }
    }
  end

  before do
    stub_command('git --version >/dev/null')
    stub_command(/bundle check/).and_return(false) # force bundle install
    stub_command(/bundle install/) # this should always work
    stub_command(/bundle exec/) # this should always work
  end

  context 'centos' do
    context 'install ruby with ruby-build' do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(step_into: ['simple_passenger_app']) do |node|
          node.set['passenger']['apps']['attributes-app'] = app
        end.converge(described_recipe)
      end

      include_examples 'default recipe behavior'

      it 'installs rhel-specific ruby devel dependencies' do
        expect(chef_run).to install_package('ruby devel dependencies').with(
          package_name: %w(bzip2 openssl-devel readline-devel zlib-devel)
        )
      end
    end

    context 'other ruby specified' do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(step_into: ['simple_passenger_app']) do |node|
          node.set['passenger']['apps']['attributes-app'] = app.merge(
            ruby_bin: '/opt/chef/embedded/bin/ruby'
          )
        end.converge(described_recipe)
      end

      include_examples 'runs app with Chef embedded ruby'
    end
  end

  context 'ubuntu' do
    context 'install ruby with ruby-build' do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(
          step_into: ['simple_passenger_app'],
          platform: 'ubuntu',
          version: '16.04'
        ) do |node|
          node.set['passenger']['apps']['attributes-app'] = app
        end.converge(described_recipe)
      end

      include_examples 'default recipe behavior'

      it 'installs ubuntu-specific ruby devel dependencies' do
        expect(chef_run).to install_package('ruby devel dependencies').with(
          package_name: %w(libssl-dev libreadline-dev zlib1g-dev)
        )
      end
    end

    context 'other ruby specified' do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(
          step_into: ['simple_passenger_app'],
          platform: 'ubuntu',
          version: '16.04'
        ) do |node|
          node.set['passenger']['apps']['attributes-app'] = app.merge(
            ruby_bin: '/opt/chef/embedded/bin/ruby'
          )
        end.converge(described_recipe)
      end

      include_examples 'runs app with Chef embedded ruby'
    end
  end
end
