#
# Cookbook Name:: simple_passenger
# Spec:: default
#
# Copyright (c) 2016 Austin Heiman, All Rights Reserved.

require 'spec_helper'

describe 'simple_passenger::default' do
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        node.set['passenger']['git_repo'] = 'https://github.com/atheiman/simple-sinatra.git'
      end
    end

    it 'converges successfully' do
      stub_command(/bundle check/).and_return(false) # force bundle install
      stub_command(/bundle install/) # this should always work
      stub_command(/bundle exec/) # this should always work
      chef_run.converge(described_recipe)
    end
  end
end
