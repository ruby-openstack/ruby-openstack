require File.dirname(__FILE__) + '/test_helper'

class ComputeConnectionTest < Test::Unit::TestCase

  def setup
    connection = stub()
    OpenStack::Authentication.stubs(:init).returns(connection)
  end

  def test_init_connection_no_credentials
    assert_raises(OpenStack::Exception::MissingArgument) do
      conn = OpenStack::Connection.create(:api_key => "AABBCCDD11", :auth_url => "a.b.c")
    end
  end

  def test_init_connection_no_password
    assert_raises(OpenStack::Exception::MissingArgument) do
      conn = OpenStack::Connection.create(:username => "test_account", :auth_url => "a.b.c")
    end
  end

  def test_init_connection_no_auth_url
    assert_raises(OpenStack::Exception::MissingArgument) do
      conn = OpenStack::Connection.create(:username => "test_account", :api_key => "AABBCCDD11")
    end
  end

  def test_init_connection_bad_auth_url
    assert_raises(OpenStack::Exception::InvalidArgument) do
      conn = OpenStack::Connection.create(:username => "test_account", :api_key => "AABBCCDD11", :auth_url => "***")
    end
  end

  def test_init_connection
      conn = OpenStack::Connection.create(:username => "test_account", :api_key => "AABBCCDD11", :auth_url => "https://a.b.c")
      assert_not_nil conn, "Connection.new returned nil."
  end

end
