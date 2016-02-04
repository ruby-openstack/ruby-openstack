require File.dirname(__FILE__) + '/../test_helper'

class IdentityConnectionTest < Test::Unit::TestCase
  def identity_connection
    conn_response = { 'x-server-management-url' => 'http://server-manage.example.com/path', 'x-auth-token' => 'dummy_token' }
    conn_response.stubs(code: '200', body: auth_server_json_response)
    server = mock(start: true, finish: true)
    server.stubs(post: conn_response, started?: true)
    Net::HTTP.stubs(:new).returns(server)
    OpenStack::Connection.create(
      username: 'test_account',
      api_key: 'AABBCCDD11',
      auth_url: 'http://a.b.c:35357/v2.0',
      service_type: 'identity'
    )
  end

  def auth_server_json_response
    %({
      "access": {
        "token": {
          "issued_at": "2016-02-04T15:23:30.918500",
          "expires": "2016-02-04T16:23:30Z",
          "id": "123",
          "tenant": {
            "description": "Tenant for the openstack services",
            "enabled": true,
            "id": "123",
            "name": "openstack"
          }
        },
        "serviceCatalog": [
          {
            "endpoints": [
              {
                "adminURL": "http://a.b.c:35357/v2.0",
                "region": "RegionOne",
                "internalURL": "http://a.b.c:35357/v2.0",
                "id": "14f9f17088774c0b95068fece76f3411",
                "publicURL": "http://ha-pub.suop:5000/v2.0"
              }
            ],
            "endpoints_links": [],
            "type": "identity",
            "name": "keystone"
          }
        ],
        "user": {
          "username": "test",
          "roles_links": [],
          "id": "37ee959016b6492ab096abb1d9961bda",
          "roles": [
            {
              "name": "admin"
            }
          ],
          "name": "test"
        },
        "metadata": {
          "is_admin": 0,
          "roles": [
            "a5f062de2c274dcfa651b544dd59a0ab"
          ]
        }
      }
    })
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
