require File.dirname(__FILE__) + '/../test_helper'

class VolumeConnectionTest < Test::Unit::TestCase
  def volume_connection
    OpenStack::Volume::Connection.any_instance.stubs(:check_if_native).returns(true)

    conn_response = { 'x-server-management-url' => 'http://server-manage.example.com/path', 'x-auth-token' => 'dummy_token' }
    conn_response.stubs(code: '200', body: auth_server_json_response)
    server = mock(start: true, finish: true)
    server.stubs(post: conn_response, started?: true)
    Net::HTTP.stubs(:new).returns(server)
    OpenStack::Connection.create(
      username: 'test_account',
      api_key: 'AABBCCDD11',
      auth_url: 'http://a.b.c:35357/v2.0',
      service_type: 'volume'
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
                "adminURL": "http://a.b.c:8776/v1/9bf44ea27d8b4573b2c590a8937b118f",
                "region": "RegionOne",
                "internalURL": "http://a.b.c:8776/v1/9bf44ea27d8b4573b2c590a8937b118f",
                "id": "066f938aa5344421bbbf4317d3f73b21",
                "publicURL": "http://a.b.c:8776/v1/9bf44ea27d8b4573b2c590a8937b118f"
              }
            ],
            "endpoints_links": [],
            "type": "volume",
            "name": "cinder"
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
    @cinder = volume_connection
  end

  def test_list_volume_types
    json_response = %{{
      "volume_types": [
        {"extra_specs": {"volume_backend_name": "volumes-standard"}, "name": "slow", "id": "b3a104b6-fe70-4450-8681-e911a153f41f"},
        {"extra_specs": {"volume_backend_name": "volumes-speed"}, "name": "fast", "id": "0e278952-9baa-4aa8-88a7-fe8387f1d86c"}
      ]
    }}

    response = mock
    response.stubs(code: '200', body: json_response)
    @cinder.connection.stubs(:req).returns(response)

    types = @cinder.list_volume_types
    assert_equal types.size, 2
    assert_equal types[0][:name], 'slow'
    assert_equal types[0][:id], 'b3a104b6-fe70-4450-8681-e911a153f41f'
  end

  def test_get_quotas
    json_response = %{{
      "quota_set": {
        "volumes_slow": -1, "snapshots_slow": -1, "gigabytes_slow": -1,
        "volumes_fast": -1, "snapshots_fast": -1, "gigabytes_fast": -1,
        "volumes": 10, "snapshots": 10, "gigabytes": 100, "id": "1"
      }
    }}

    response = mock
    response.stubs(code: '200', body: json_response)
    @cinder.connection.stubs(:req).returns(response)

    quotas = @cinder.get_quotas(1)
    assert_equal quotas['id'], '1'
    assert_equal quotas['volumes'], 10
    assert_equal quotas['snapshots'], 10
    assert_equal quotas['gigabytes'], 100
    assert_equal quotas['volumes_slow'], -1
  end

  def test_update_quotas
    json_response = %{{
      "quota_set": {
        "volumes_slow": -1, "snapshots_slow": -1, "gigabytes_slow": 200,
        "volumes_fast": -1, "snapshots_fast": -1, "gigabytes_fast": 300,
        "volumes": 10, "snapshots": 10, "gigabytes": 500
      }
    }}

    response = mock
    response.stubs(code: '200', body: json_response)
    @cinder.connection.stubs(:req).returns(response)

    quota_set = { gigabytes: 500, gigabytes_slow: 200, gigabytes_fast: 300 }
    quotas = @cinder.update_quotas(1, quota_set)
    assert_equal quotas['volumes'], 10
    assert_equal quotas['snapshots'], 10
    assert_equal quotas['gigabytes'], 500
    assert_equal quotas['gigabytes_slow'], 200
    assert_equal quotas['gigabytes_fast'], 300
    assert_equal quotas['volumes_slow'], -1
  end

  def test_force_delete_volume!
    response = mock()
    response.stubs(code: '202')
    @cinder.connection.stubs(:req).returns(response)

    result = @cinder.force_delete_volume!('0ebf71f1-fe6b-4c61-af79-553901394e26')
    assert_equal result, true
  end
end
