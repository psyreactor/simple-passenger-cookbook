#
# Cookbook Name:: simple_passenger
# Spec:: default
#
# Copyright (c) 2016 Austin Heiman, All Rights Reserved.

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

  let(:git_revision) { 'master' }

  let(:ruby_version) { '2.2.5' }
  let(:passenger_user) { 'passenger' }
  let(:passenger_group) { 'passenger' }
  let(:app_name) { 'default_app' }
  let(:ruby_bin_dir) { "/usr/local/ruby/#{ruby_version}/bin" }
  let(:app_dir) { '/opt/default_app' }
  let(:log_dir) { '/var/log/default_app' }
  let(:pid_dir) { '/var/run/default_app' }
  let(:passengerfile_options) do
    {
      'daemonize' => true,
      'port' => 80,
      'environment' => 'production',
      'log_file' => '/var/log/default_app/default_app',
      'pid_file' => '/var/run/default_app/default_app.pid',
      'user' => 'passenger',
      'ruby' => "/usr/local/ruby/#{ruby_version}/bin/ruby"
    }
  end

  context 'centos' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.6') do |node|
        node.set['passenger']['git_repo'] = git_repo
      end.converge(described_recipe)
    end

    include_examples 'common attribute setting and resource behavior'

    it 'installs ruby devel dependencies' do
      expect(chef_run).to install_package('ruby devel dependencies').with(
        package_name: %w(bzip2 openssl-devel readline-devel zlib-devel)
      )
    end
  end

  context 'ubuntu' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '16.04') do |node|
        node.set['passenger']['git_repo'] = git_repo
      end.converge(described_recipe)
    end

    include_examples 'common attribute setting and resource behavior'

    it 'installs ruby devel dependencies' do
      expect(chef_run).to install_package('ruby devel dependencies').with(
        package_name: %w(libssl-dev libreadline-dev zlib1g-dev)
      )
    end
  end
end
