require File.dirname(__FILE__) + '/test_helper'

class ExceptionTest < Test::Unit::TestCase

  def test_400_cloud_servers_fault
    response = mock()
    response.stubs(:code => "400", :body => "{\"ComputeFault\":{\"message\":\"422 Unprocessable Entity: We could not process your request at this time. We have been notified and are looking into the issue.  [E03]\",\"details\":\"com.rackspace.cloud.service.servers.OpenStack::ComputeFault: Fault occured\",\"code\":400}}" )
    exception=nil
    begin
      OpenStack::Exception.raise_exception(response)
    rescue Exception => e
      exception=e
    end
    assert_equal(OpenStack::Exception::ComputeFault, e.class)
    assert_equal("400", e.response_code)
    assert_not_nil(e.response_body)
  end

  def test_413_over_limit
    response = mock()
    response.stubs(:code => "413", :body => "{\"overLimit\":{\"message\":\"Too many requests...\",\"code\":413,\"retryAfter\":\"2010-08-25T10:47:57.890-05:00\"}}")
    exception=nil
    begin
      OpenStack::Exception.raise_exception(response)
    rescue Exception => e
      exception=e
    end
    assert_equal(OpenStack::Exception::OverLimit, e.class)
    assert_equal("413", e.response_code)
    assert_not_nil(e.response_body)
  end

  def test_other
    response = mock()
    body="{\"blahblah\":{\"message\":\"Failed...\",\"code\":500}}"
    response.stubs(:code => "500", :body => body)
    exception=nil
    begin
      OpenStack::Exception.raise_exception(response)
    rescue Exception => e
      exception=e
    end
    assert_equal(OpenStack::Exception::Other, exception.class)
    assert_equal("500", exception.response_code)
    assert_not_nil(exception.response_body)
    assert_equal(body, exception.response_body)
  end

end
