require File.dirname(__FILE__) + '/test_helper'

class AuthenticationTest < Test::Unit::TestCase
  
  def test_good_authentication
    response = {'x-server-management-url' => 'http://server-manage.example.com/path', 'x-auth-token' => 'dummy_token'}
    response.stubs(:code).returns('204')
    server = mock(:use_ssl= => true, :verify_mode= => true, :start => true, :finish => true)
    server.stubs(:get).returns(response)
    Net::HTTP.stubs(:new).returns(server)
    connection = stub(:authuser => 'good_user', :authtenant => 'good_tenant', :authkey => 'bad_key', :auth_host => "a.b.c", :auth_port => "443", :auth_scheme => "https", :auth_path => "/v1.0", :authok= => true, :authtoken= => true, :svrmgmthost= => "", :svrmgmtpath= => "", :svrmgmtpath => "", :svrmgmtport= => "", :svrmgmtscheme= => "", :proxy_host => nil, :proxy_port => nil, :api_path => '/foo')
    result = OpenStack::Compute::Authentication.init(connection)
    assert_equal result.class, OpenStack::Compute::AuthV10
  end
  
  def test_bad_authentication
    response = mock()
    response.stubs(:code).returns('499')
    server = mock(:use_ssl= => true, :verify_mode= => true, :start => true)
    server.stubs(:get).returns(response)
    Net::HTTP.stubs(:new).returns(server)
    connection = stub(:authuser => 'bad_user', :authtenant => 'good_tenant', :authkey => 'bad_key', :auth_host => "a.b.c", :auth_port => "443", :auth_scheme => "https", :auth_path => "/v1.0", :authok= => true, :authtoken= => true, :proxy_host => nil, :proxy_port => nil, :api_path => '/foo')
    assert_raises(OpenStack::Compute::Exception::Authentication) do
      result = OpenStack::Compute::Authentication.init(connection)
    end
  end
    
  def test_bad_hostname
    Net::HTTP.stubs(:new).raises(OpenStack::Compute::Exception::Connection)
    connection = stub(:authuser => 'bad_user', :authtenant => 'good_tenant', :authkey => 'bad_key', :auth_host => "a.b.c", :auth_port => "443", :auth_scheme => "https", :auth_path => "/v1.0", :authok= => true, :authtoken= => true, :proxy_host => nil, :proxy_port => nil, :api_path => '/foo')
    assert_raises(OpenStack::Compute::Exception::Connection) do
      result = OpenStack::Compute::Authentication.init(connection)
    end
  end
  
  def test_service_region
    server = get_test_auth_server
    Net::HTTP.stubs(:new).returns(server)
    connection = stub(:authuser => 'good_user', :authtenant => 'good_tenant', :authkey => 'bad_key', :auth_host => "a.b.c", :auth_port => "443", :auth_scheme => "https", :auth_path => "/v2.0", :authok= => true, :authtoken= => true, :svrmgmthost= => "", :svrmgmtpath= => "", :svrmgmtpath => "", :svrmgmtport= => "", :svrmgmtscheme= => "", :proxy_host => nil, :proxy_port => nil, :api_path => '/foo', :service_type => "compute", :service_name => "cloudServers", :region => "South")
    result = OpenStack::Compute::Authentication.init(connection)
    assert_equal("compute.south.host", result.uri.host)  
  end
  
  def test_service_name
    server = get_test_auth_server
    Net::HTTP.stubs(:new).returns(server)
    connection = stub(:authuser => 'good_user', :authtenant => 'good_tenant', :authkey => 'bad_key', :auth_host => "a.b.c", :auth_port => "443", :auth_scheme => "https", :auth_path => "/v2.0", :authok= => true, :authtoken= => true, :svrmgmthost= => "", :svrmgmtpath= => "", :svrmgmtpath => "", :svrmgmtport= => "", :svrmgmtscheme= => "", :proxy_host => nil, :proxy_port => nil, :api_path => '/foo', :service_type => "nova", :service_name => "cloudCompute", :region => "South")
    result = OpenStack::Compute::Authentication.init(connection)
    assert_equal("nova.south.host", result.uri.host)  
  end
  
  def test_service_type
    server = get_test_auth_server
    Net::HTTP.stubs(:new).returns(server)
    connection = stub(:authuser => 'good_user', :authtenant => 'good_tenant', :authkey => 'bad_key', :auth_host => "a.b.c", :auth_port => "443", :auth_scheme => "https", :auth_path => "/v2.0", :authok= => true, :authtoken= => true, :svrmgmthost= => "", :svrmgmtpath= => "", :svrmgmtpath => "", :svrmgmtport= => "", :svrmgmtscheme= => "", :proxy_host => nil, :proxy_port => nil, :api_path => '/foo', :service_type => "nova", :service_name => nil, :region => "North")
    result = OpenStack::Compute::Authentication.init(connection)
    assert_equal("nova.north.host", result.uri.host)  
  end
  
  
  private
  def get_test_auth_server
    json_response = %{{
        "access":{
            "token":{
                "id":"asdasdasd-adsasdads-asdasdasd-adsadsasd",
                "expires":"2010-11-01T03:32:15-05:00"
            },
            "user":{
                "id":"123",
                "name":"testName",
                "roles":[{
                        "id":"234",
                        "name":"compute:admin"
                    },
    				{
                        "id":"235",
                        "name":"object-store:admin",
                        "tenantId":"1"
                    }                       
                ],
                "roles_links":[]
            },
            "serviceCatalog":[{
                    "name":"cloudServers",
                    "type":"compute",
                    "endpoints":[{
                            "publicURL":"https://compute.north.host/v1.1",
                            "region":"North"
                        },
                        {
                            "publicURL":"https://compute.south.host/v1.1",
                            "region":"South"
                        }
                    ],
                    "endpoints_links":[]
                },
                {
                    "name":"cloudCompute",
                    "type":"nova",
                    "endpoints":[{
                            "publicURL":"https://nova.north.host/v1.1",
                            "region":"North"
                        },
                        {
                            "publicURL":"https://nova.south.host/v1.1",
                            "region":"South"
                        }
                    ],
                    "endpoints_links":[{
                            "rel":"next",
                            "href":"https://identity.north.host/v2.0/endpoints?marker=2"
                        }
                    ]
                }
            ],
            "serviceCatalog_links":[{
                    "rel":"next",
                    "href":"https://identity.host/v2.0/endpoints?session=2hfh8Ar&marker=2"
                }
            ]
        }
    }}

    response = {'x-server-management-url' => 'http://server-manage.example.com/path', 'x-auth-token' => 'dummy_token'}
    response.stubs(:code => "200", :body => json_response)
    server = mock(:use_ssl= => true, :verify_mode= => true, :start => true, :finish => true)
    server.stubs(:post).returns(response)
    return server  
  end
end
