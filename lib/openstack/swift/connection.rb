#Initial version of this code is based on and refactored from the rackspace/ruby-cloudfiles repo
#@ https://github.com/rackspace/ruby-cloudfiles - Copyright (c) 2011, Rackspace US, Inc.
# See COPYING for license information
#
module OpenStack
module Swift
  class Connection

    attr_accessor :connection

    def initialize(connection)
      @connection = connection
      OpenStack::Authentication.init(@connection)
    end

    # Returns true if the authentication was successful and returns false otherwise.
    #
    #   cf.authok?
    #   => true
    def authok?
      @connection.authok
    end

    # Returns an OpenStack::Swift::Container object that can be manipulated easily.
    # Throws a OpenStack::Exception::ItemNotFound if the container doesn't exist.
    #
    #    container = cf.container('test')
    #    container.count
    #    => 2
    #    container = cf.container("no_such_container")
    #    => OpenStack::Exception::ItemNotFound: The resource could not be found
    #
    def container(name)
      OpenStack::Swift::Container.new(self, name)
    end
    alias :get_container :container

    # Sets instance variables for the bytes of storage used for this account/connection, as well as the number of containers
    # stored under the account.  Returns a hash with :bytes and :count keys, and also sets the instance variables.
    #
    #   cf.get_info
    #   => {:count=>8, :bytes=>42438527}
    #   cf.bytes
    #   => 42438527
    # Hostname of the storage server
    def get_info
        raise OpenStack::Exception::Authentication, "Not authenticated" unless authok?
        response = @connection.req("HEAD", "")
        @bytes = response["x-account-bytes-used"].to_i
        @count = response["x-account-container-count"].to_i
        {:bytes => @bytes, :count => @count}
    end

    # The total size in bytes under this connection
    def bytes
      get_info[:bytes]
    end

    # The total number of containers under this connection
    def count
      get_info[:count]
    end

    # Gathers a list of the containers that exist for the account and returns the list of container names
    # as an array.  If no containers exist, an empty array is returned.
    #
    # If you supply the optional limit and marker parameters, the call will return the number of containers
    # specified in limit, starting after the object named in marker.
    #
    #   cf.containers
    #   => ["backup", "Books", "cftest", "test", "video", "webpics"]
    #
    #   cf.containers(2,'cftest')
    #   => ["test", "video"]
    def containers(limit = nil, marker = nil)
      path = OpenStack.get_query_params({:limit=>limit, :marker=>marker}, [:limit, :marker], "")
      response = @connection.req("GET", URI.encode(path))
      OpenStack.symbolize_keys(JSON.parse(response.body)).inject([]){|res,cur| res << cur[:name]; res }
    end
    alias :list_containers :containers

    # Retrieves a list of containers on the account along with their sizes (in bytes) and counts of the objects
    # held within them.  If no containers exist, an empty hash is returned.
    #
    # If you supply the optional limit and marker parameters, the call will return the number of containers
    # specified in limit, starting after the object named in marker.
    #
    #   cf.containers_detail
    #   => { "container1" => { :bytes => "36543", :count => "146" },
    #        "container2" => { :bytes => "105943", :count => "25" } }
    def containers_detail(limit = nil, marker = nil)
      path = OpenStack.get_query_params({:limit=>limit, :marker=>marker}, [:limit, :marker], "")
      response = @connection.req("GET", URI.encode(path))
      OpenStack.symbolize_keys(JSON.parse(response.body)).inject({}){|res,current| res.merge!({current[:name]=>{:bytes=>current[:bytes].to_s,:count=>current[:count].to_s}}) ; res }
    end
    alias :list_containers_info :containers_detail

    # Returns true if the requested container exists and returns false otherwise.
    #
    #   cf.container_exists?('good_container')
    #   => true
    #
    #   cf.container_exists?('bad_container')
    #   => false
    def container_exists?(containername)
      path = "/#{URI.encode(containername.to_s)}"
      begin
        response = @connection.req("HEAD", path)
      rescue OpenStack::Exception::ItemNotFound
        return false
      end
      true
    end

    # Creates a new container and returns the OpenStack::Swift::Container object.
    #
    # "/" is not valid in a container name.  The container name is limited to
    # 256 characters or less.
    #
    #   container = cf.create_container('new_container')
    #   container.name
    #   => "new_container"
    #
    #   container = cf.create_container('bad/name')
    #   => OpenStack::Exception::InvalidArgument: Container name cannot contain '/'
    def create_container(containername)
      raise OpenStack::Exception::InvalidArgument.new("Container name cannot contain '/'") if containername.match("/")
      raise OpenStack::Exception::InvalidArgument.new("Container name is limited to 256 characters") if containername.length > 256
      path = "/#{URI.encode(containername.to_s)}"
      @connection.req("PUT", path, {:headers=>{"Content-Length"=>"0"}})
      OpenStack::Swift::Container.new(self, containername)
    end

    # Deletes a container from the account.  Throws a OpenStack::Exception::ResourceStateConflict
    # if the container still contains objects.  Throws a OpenStack::Exception::ItemNotFound if the
    # container doesn't exist.
    #
    #   cf.delete_container('new_container')
    #   => true
    #
    #   cf.delete_container('video')
    #   => OpenStack::Exception::ResourceStateConflict: The container: "video" is not empty. There was a conflict with the state of the resource
    #
    #
    #   cf.delete_container('nonexistent')
    #   => OpenStack::Exception::ItemNotFound: The container: "nonexistant" does not exist. The resource could not be found
    def delete_container(containername)
      path = "/#{URI.encode(containername.to_s)}"
      begin
        @connection.req("DELETE", path)
      rescue OpenStack::Exception::ResourceStateConflict => conflict
        msg = "The container: \"#{containername}\" is not empty. #{conflict.message}"
        raise OpenStack::Exception::ResourceStateConflict.new(msg, conflict.response_code, conflict.response_body)
      rescue OpenStack::Exception::ItemNotFound => not_found
        msg = "The container: \"#{containername}\" does not exist. #{not_found.message}"
        raise OpenStack::Exception::ItemNotFound.new(msg, not_found.response_code, not_found.response_body)
      end
      true
    end

  end

#used for PUT object with body_stream for http data
#see OpenStack::Connection::put_object
  class ChunkedConnectionWrapper
    def initialize(data, chunk_size)
      @size = chunk_size
      @file = data
    end

    def read(foo)
      @file.read(@size)
    end

    def eof!
      @file.eof!
    end
    def eof?
      @file.eof?
    end
  end


end
end
