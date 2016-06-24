require 'spec_helper'
require 'net/http'

describe 'simple_passenger::default' do
  it 'runs the simple sinatra app' do
    uri = URI('http://localhost/')
    res = Net::HTTP.get_response(uri)
    expect(res.code).to eq('200')
    expect(res.body).to eq("SimpleApp is up and running!\nrack app environment: production\n")
  end
end
