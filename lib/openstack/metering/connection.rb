module OpenStack
module Metering

  class Connection

    attr_accessor   :connection

    def initialize(connection)
      @connection = connection
      OpenStack::Authentication.init(@connection)
    end

    # Returns true if the authentication was successful and returns false otherwise.
    #
    #   cs.authok?
    #   => true
    def authok?
      @connection.authok
    end

    def query_samples(data = {})
      response = @connection.req('POST', "/query/samples", {data: JSON.generate(data)})
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      JSON.parse(response.body)
    end

  end

end
end
