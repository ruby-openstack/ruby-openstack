require File.dirname(__FILE__) + '/../test_helper'

class FlavorsTest < Test::Unit::TestCase
  include TestConnection

  def setup
    @comp = get_test_connection
  end

  def test_get_flavor
    json_response = %{{
      "flavor": {
        "name": "test",
        "links": [
          {"href": "http://a.b.c:8774/v2/9bf44ea27d8b4573b2c590a8937b118f/flavors/1", "rel": "self"},
          {"href": "http://a.b.c:8774/9bf44ea27d8b4573b2c590a8937b118f/flavors/1", "rel": "bookmark"}
        ],
        "ram": 4096,
        "OS-FLV-DISABLED:disabled": false,
        "vcpus": 2,
        "swap": "",
        "os-flavor-access:is_public": true,
        "rxtx_factor": 1.0,
        "OS-FLV-EXT-DATA:ephemeral": 0,
        "disk": 50,
        "id": "1"
      }}
    }
    response = mock()
    response.stubs(:code => "200", :body => json_response)
    @comp.connection.stubs(:csreq).returns(response)
    flavor = @comp.get_flavor(1)
    assert_equal flavor.id, '1'
    assert_equal flavor.name, 'test'
    assert_equal flavor.ram, 4096
    assert_equal flavor.disk, 50
    assert_equal flavor.vcpus, 2
  end

  def test_list_flavors
    json_response = %{{
      "flavors": [
          {
              "OS-FLV-DISABLED:disabled": false,
              "disk": 1,
              "OS-FLV-EXT-DATA:ephemeral": 0,
              "os-flavor-access:is_public": true,
              "id": "1",
              "links": [
                  {
                      "href": "http://openstack.example.com/v2.1/openstack/flavors/1",
                      "rel": "self"
                  },
                  {
                      "href": "http://openstack.example.com/openstack/flavors/1",
                      "rel": "bookmark"
                  }
              ],
              "name": "m1.tiny",
              "ram": 512,
              "swap": "",
              "vcpus": 1
          }
      ]
    }}
    response = mock()
    response.stubs(:code => "200", :body => json_response)
    @comp.connection.stubs(:csreq).returns(response)
    flavor = @comp.list_flavors(tenant_id: "5a978754183d4765bf96aaf847e5d463", limit: 1)
    assert_equal flavor[0][:id], '1'
    assert_equal flavor[0][:name], 'm1.tiny'
    assert_equal flavor[0][:ram], 512
    assert_equal flavor[0][:swap], ""
    assert_equal flavor[0][:vcpus], 1
  end

  def test_create_flavor
    json_response = %{{
      "flavor": {
        "name": "small",
        "links": [
          {"href": "http://a.b.c:8774/v2/9bf44ea27d8b4573b2c590a8937b118f/flavors/d011e330-06a9-4074-9f59-cc43a706cf2b", "rel": "self"},
          {"href": "http://a.b.c:8774/9bf44ea27d8b4573b2c590a8937b118f/flavors/d011e330-06a9-4074-9f59-cc43a706cf2b", "rel": "bookmark"}
        ],
        "ram": 1024,
        "OS-FLV-DISABLED:disabled": false,
        "vcpus": 2,
        "swap": "",
        "os-flavor-access:is_public": true,
        "rxtx_factor": 1.0,
        "OS-FLV-EXT-DATA:ephemeral": 0,
        "disk": 50,
        "id": "d011e330-06a9-4074-9f59-cc43a706cf2b"
      }}
    }
    response = mock()
    response.stubs(:code => "200", :body => json_response)
    @comp.connection.stubs(:csreq).returns(response)
    flavor = @comp.create_flavor({name: 'small', vcpus: 2, ram: 1024, disk: 50}, true)
    assert_equal flavor.id, 'd011e330-06a9-4074-9f59-cc43a706cf2b'
    assert_equal flavor.name, 'small'
    assert_equal flavor.ram, 1024
    assert_equal flavor.disk, 50
    assert_equal flavor.vcpus, 2
  end

  def test_delete_flavor
    response = mock()
    response.stubs(:code => "202")
    @comp.connection.stubs(:csreq).returns(response)
    result = @comp.delete_flavor(1)
    assert_equal result, true
  end

  def test_add_tenant_to_flavor
    json_response = %{{
      "flavor_access": [
        {"tenant_id": "5a978754183d4765bf96aaf847e5d463", "flavor_id": "5a7af7d3-3ff6-496d-b300-f4a870c46181"}
      ]
    }}
    response = mock()
    response.stubs(:code => "200", :body => json_response)
    @comp.connection.stubs(:csreq).returns(response)
    result = @comp.add_tenant_to_flavor('5a7af7d3-3ff6-496d-b300-f4a870c46181', '5a978754183d4765bf96aaf847e5d463')
    assert_equal result['flavor_access'].last['flavor_id'], '5a7af7d3-3ff6-496d-b300-f4a870c46181'
  end

  def test_delete_tenant_from_flavor
    json_response = %{{"flavor_access": []}}
    response = mock()
    response.stubs(:code => "200", :body => json_response)
    @comp.connection.stubs(:csreq).returns(response)
    result = @comp.delete_tenant_from_flavor('5a7af7d3-3ff6-496d-b300-f4a870c46181', '5a978754183d4765bf96aaf847e5d463')
    assert_equal result['flavor_access'], []
  end
end
