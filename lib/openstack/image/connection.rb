module OpenStack
module Image

  class Connection

    attr_accessor   :connection

    def initialize(connection)
      @connection = connection
      OpenStack::Authentication.init(@connection)
    end

  end

end
end
