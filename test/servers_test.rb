require File.dirname(__FILE__) + '/test_helper'

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

end
