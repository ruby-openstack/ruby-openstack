require File.dirname(__FILE__) + '/../test_helper'

class ServersTest < Test::Unit::TestCase
  include TestConnection

  def setup
    @comp=get_test_connection
  end

  def test_list_servers
    json_response = %{{
      "servers" : [
        {
          "id" : 1234,
          "name" : "sample-server",
          "image" : { "id": "2" },
          "flavor" : { "id" : "1" },
          "hostId" : "e4d909c290d0fb1ca068ffaddf22cbd0",
          "status" : "BUILD",
          "progress" : 60,
          "addresses" : {
              "public" : [
                  { "version" : 4, "addr" : "67.23.10.132" },
                  { "version" : 4, "addr" : "67.23.10.131" }
              ],
              "private" : [
                  { "version" : 4, "addr" : "10.176.42.16" }
              ]
          },
          "metadata" : {
              "Server Label" : "Web Head 1",
              "Image Version" : "2.1"
          }
        },
        {
          "id" : 5678,
          "name" : "sample-server2",
          "image" : { "id": "2" },
          "flavor" : { "id" : "1" },
          "hostId" : "9e107d9d372bb6826bd81d3542a419d6",
          "status" : "ACTIVE",
          "addresses" : {
              "public" : [
                  { "version" : 4, "addr" : "67.23.10.133" }
              ],
              "private" : [
                  { "version" : 4, "addr" : "10.176.42.17" }
              ]
          },
          "metadata" : {
              "Server Label" : "DB 1"
          }
        }
      ]
    }}
    response = mock()
    response.stubs(:code => "200", :body => json_response)
    @comp.connection.stubs(:csreq).returns(response)
    servers=@comp.list_servers
    assert_equal 2, servers.size
    assert_equal 1234, servers[0][:id]
    assert_equal "sample-server", servers[0][:name]
  end

  def test_filters_name_list_servers
    servers = list_servers
    assert_equal 1, servers.size
    assert_equal "a291599e-6de2-41a6-88df-c443ddcef70d", servers[0][:id]
    assert_equal "http://openstack.example.com/v2/openstack/servers/a291599e-6de2-41a6-88df-c443ddcef70d", servers[0][:links][0][:href]
    assert_equal "self", servers[0][:links][0][:rel]
    assert_equal "http://openstack.example.com/openstack/servers/a291599e-6de2-41a6-88df-c443ddcef70d", servers[0][:links][1][:href]
    assert_equal "bookmark", servers[0][:links][1][:rel]
    assert_equal "new-server-test", servers[0][:name]
  end

  def test_list_servers_detail
    json_response = list_servers_detail_json("SHUTOFF")

    response = mock()
    response.stubs(:code => "200", :body => json_response)
    @comp.connection.stubs(:csreq).returns(response)

    servers = @comp.list_servers_detail(status: "SHUTOFF")
    assert_equal "SHUTOFF", servers[0][:status]
  end

  def test_get_server
    server=get_test_server
    assert_equal "sample-server", server.name
    assert_equal "2", server.image['id']
    assert_equal "1", server.flavor['id']
    assert_equal "e4d909c290d0fb1ca068ffaddf22cbd0", server.hostId
    assert_equal "BUILD", server.status
    assert_equal 60, server.progress
    assert_equal "67.23.10.132", server.addresses[:public][0].address
    assert_equal "67.23.10.131", server.addresses[:public][1].address
    assert_equal "10.176.42.16", server.addresses[:private][0].address
  end

  def test_rebuild_server
    json_response = %{{
    "server": {
        "id": "52415800-8b69-11e0-9b19-734f565bc83b",
        "tenantId": "1234",
        "userId": "5678",
        "name": "newName",
        "created": "2010-11-11T12:00:00Z",
        "hostId": "e4d909c290d0fb1ca068ffaddf22cbd0",
        "accessIPv4" : "67.23.10.138",
        "accessIPv6" : "::babe:67.23.10.138",
        "progress": 0,
        "status": "REBUILD",
        "adminPass": "GFf1j9aP",
        "image" : {
            "id": "52415800-8b69-11e0-9b19-734f6f006e54",
            "name": "CentOS 5.2",
            "links": [
                {
                    "rel": "self",
                    "href": "http://servers.api.openstack.org/v1.1/1234/images/52415800-8b69-11e0-9b19-734f6f006e54"
                },
                {
                    "rel": "bookmark",
                    "href": "http://servers.api.openstack.org/1234/images/52415800-8b69-11e0-9b19-734f6f006e54"
                }
            ]
        },
        "flavor" : {
            "id": "52415800-8b69-11e0-9b19-734f1195ff37",
            "name": "256 MB Server",
            "links": [
                {
                    "rel": "self",
                    "href": "http://servers.api.openstack.org/v1.1/1234/flavors/52415800-8b69-11e0-9b19-734f1195ff37"
                },
                {
                    "rel": "bookmark",
                    "href": "http://servers.api.openstack.org/1234/flavors/52415800-8b69-11e0-9b19-734f1195ff37"
                }
            ]
        },
        "metadata": {
            "My Server Name": "Apache1"
        },
        "addresses": {
            "public" : [
                {
                    "version": 4,
                    "addr": "67.23.10.138"
                },
                {
                    "version": 6,
                    "addr": "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
                }
            ],
            "private" : [
                {
                    "version": 4,
                    "addr": "10.176.42.19"
                },
                {
                    "version": 6,
                    "addr": "fe80:0000:0000:0000:0202:b3ff:fe1e:8329"
                }
            ]
        },
        "links": [
            {
                "rel": "self",
                "href": "http://servers.api.openstack.org/v1.1/1234/servers/52415800-8b69-11e0-9b19-734fcece0043"
            },
            {
                "rel": "bookmark",
                "href": "http://servers.api.openstack.org/1234/servers/52415800-8b69-11e0-9b19-734fcece0043"
            }
        ]
    }
    }}

    server=get_test_server

    response = mock()
    response.stubs(:code => "200", :body => json_response)

    @comp.connection.stubs(:csreq).returns(response)
    server.rebuild!(:name => "newName")

    assert_not_nil server.adminPass
    assert_equal "newName", server.name
  end

private
  def get_test_server
    json_response = %{{
      "server" : {
          "id" : 1234,
          "name" : "sample-server",
          "image" : { "id": "2" },
          "flavor" : { "id" : "1" },
          "hostId" : "e4d909c290d0fb1ca068ffaddf22cbd0",
          "status" : "BUILD",
          "progress" : 60,
          "addresses" : {
              "public" : [
                  { "version" : 4, "addr" : "67.23.10.132" },
                  { "version" : 4, "addr" : "67.23.10.131" }
              ],
              "private" : [
                  { "version" : 4, "addr" : "10.176.42.16" }
              ]
          },
          "metadata" : {
              "Server Label" : "Web Head 1",
              "Image Version" : "2.1"
          }
      }
    }}

    response = mock()
    response.stubs(:code => "200", :body => json_response)
    @comp.connection.stubs(:csreq).returns(response)
    return @comp.server(1234)
  end

  def list_servers
    json_response = %{{
      "servers": [
          {
              "id": "a291599e-6de2-41a6-88df-c443ddcef70d",
              "links": [
                  {
                      "href": "http://openstack.example.com/v2/openstack/servers/a291599e-6de2-41a6-88df-c443ddcef70d",
                      "rel": "self"
                  },
                  {
                      "href": "http://openstack.example.com/openstack/servers/a291599e-6de2-41a6-88df-c443ddcef70d",
                      "rel": "bookmark"
                  }
              ],
              "name": "new-server-test"
          }
      ]
    }}
    response = mock()
    response.stubs(:code => "200", :body => json_response)
    @comp.connection.stubs(:csreq).returns(response)
    @comp.list_servers(name: "new-server-test")
  end

  def list_servers_detail_json(status= "ACTIVE")
    %{{
      "servers": [
          {
              "addresses": {
                  "private": [
                      {
                          "addr": "192.168.0.3",
                          "OS-EXT-IPS-MAC:mac_addr": "aa:bb:cc:dd:ee:ff",
                          "OS-EXT-IPS:type": "fixed",
                          "version": 4
                      }
                  ]
              },
              "created": "2013-09-23T13:53:12Z",
              "flavor": {
                  "id": "1",
                  "links": [
                      {
                          "href": "http://openstack.example.com/openstack/flavors/1",
                          "rel": "bookmark"
                      }
                  ]
              },
              "hostId": "f1e160ad2bf07084f3d3e0dfdd0795d80da18a60825322c15775c0dd",
              "id": "9cbefc35-d372-40c5-88e2-9fda1b6ea12c",
              "image": {
                  "id": "70a599e0-31e7-49b7-b260-868f441e862b",
                  "links": [
                      {
                          "href": "http://openstack.example.com/openstack/images/70a599e0-31e7-49b7-b260-868f441e862b",
                          "rel": "bookmark"
                      }
                  ]
              },
              "key_name": null,
              "links": [
                  {
                      "href": "http://openstack.example.com/v2/openstack/servers/9cbefc35-d372-40c5-88e2-9fda1b6ea12c",
                      "rel": "self"
                  },
                  {
                      "href": "http://openstack.example.com/openstack/servers/9cbefc35-d372-40c5-88e2-9fda1b6ea12c",
                      "rel": "bookmark"
                  }
              ],
              "metadata": {
                  "My Server Name": "Apache1"
              },
              "name": "new-server-test",
              "accessIPv4": "",
              "accessIPv6": "",
              "config_drive": "",
              "OS-DCF:diskConfig": "AUTO",
              "OS-EXT-AZ:availability_zone": "nova",
              "OS-EXT-SRV-ATTR:host": "c3f14e9812ad496baf92ccfb3c61e15f",
              "OS-EXT-SRV-ATTR:hypervisor_hostname": "fake-mini",
              "OS-EXT-SRV-ATTR:instance_name": "instance-00000001",
              "OS-EXT-STS:power_state": 1,
              "OS-EXT-STS:task_state": null,
              "OS-EXT-STS:vm_state": "active",
              "os-extended-volumes:volumes_attached": [],
              "OS-SRV-USG:launched_at": "2013-09-23T13:53:12.774549",
              "OS-SRV-USG:terminated_at": null,
              "progress": 0,
              "security_groups": [
                  {
                      "name": "default"
                  }
              ],
              "status": "#{status}",
              "host_status": "UP",
              "tenant_id": "openstack",
              "updated": "2013-10-31T06:32:32Z",
              "user_id": "fake"
          }
      ]
    }}
  end
end
