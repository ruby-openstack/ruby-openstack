require File.dirname(__FILE__) + '/../test_helper'

class IdentityConnectionTest < Test::Unit::TestCase
  def identity_connection
    conn_response = { 'x-server-management-url' => 'http://server-manage.example.com/path', 'x-auth-token' => 'dummy_token' }
    conn_response.stubs(:code).returns('200')
    server = mock(start: true, finish: true)
    server.stubs(:get => conn_response, :use_ssl= => true, :verify_mode= => true)

    Net::HTTP.stubs(:new).returns(server)
    OpenStack::Connection.create(
      username: 'test_account',
      api_key: 'AABBCCDD11',
      auth_url: 'http://a.b.c:35357/v2.0',
      service_type: 'identity'
    )
  end

  def setup
    @comp = identity_connection
  end

  def test_list_tenants
    json_response = %({
      "tenants_links": [],
      "tenants": [
        {
          "description": "test1",
          "enabled": true,
          "id": "19f722a65fb94959bae14961196106c6",
          "name": "test1"
        },
        {
          "description": "test2",
          "enabled": true,
          "id": "1df59660b4984ecdb0da80ee8410bb83",
          "name": "test2"
        }
      ]
    })

    response = mock
    response.stubs(code: '200', body: json_response)
    @comp.connection.stubs(:csreq).returns(response)
    tenants = @comp.list_tenants
    assert_equal 2, tenants.count
    assert_equal 'test2', tenants.last.name
  end
end
