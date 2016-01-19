require 'rubygems'
require 'test/unit'
require 'mocha/test_unit'

$:.unshift File.dirname(__FILE__) + '/../lib'

require 'openstack'

module TestConnection
  def get_test_connection
    conn_response = {'x-server-management-url' => 'http://server-manage.example.com/path', 'x-auth-token' => 'dummy_token'}
    conn_response.stubs(:code).returns('204')
    server = mock(:start => true, :finish => true)
    server.stubs(:get => conn_response, :use_ssl= => true, :verify_mode= => true)

    Net::HTTP.stubs(:new).returns(server)
    OpenStack::Connection.create(:username => "test_account", :api_key => "AABBCCDD11", :auth_url => "http://a.b.c")
  end
end
