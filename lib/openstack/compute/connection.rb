module OpenStack
module Compute

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

    # Returns the OpenStack::Compute::Server object identified by the given id.
    #
    #   >> server = cs.get_server(110917)
    #   => #<OpenStack::Compute::Server:0x101407ae8 ...>
    #   >> server.name
    #   => "MyServer"
    def get_server(id)
      OpenStack::Compute::Server.new(self,id)
    end
    alias :server :get_server

    # Returns an array of hashes, one for each server that exists under this account.  The hash keys are :name and :id.
    #
    # You can also provide :limit and :offset parameters to handle pagination.
    #
    #   >> cs.list_servers
    #   => [{:name=>"MyServer", :id=>110917}]
    #
    #   >> cs.list_servers(:limit => 2, :offset => 3)
    #   => [{:name=>"demo-standingcloud-lts", :id=>168867},
    #       {:name=>"demo-aicache1", :id=>187853}]
    def list_servers(options = {})
      anti_cache_param="cacheid=#{Time.now.to_i}"
      path = OpenStack.paginate(options).empty? ? "#{@connection.service_path}/servers?#{anti_cache_param}" : "#{@connection.service_path}/servers?#{OpenStack.paginate(options)}&#{anti_cache_param}"
      response = @connection.csreq("GET",@connection.service_host,path,@connection.service_port,@connection.service_scheme)
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      OpenStack.symbolize_keys(JSON.parse(response.body)["servers"])
    end
    alias :servers :list_servers

    # Returns an array of hashes with more details about each server that exists under this account.  Additional information
    # includes public and private IP addresses, status, hostID, and more.  All hash keys are symbols except for the metadata
    # hash, which are verbatim strings.
    #
    # You can also provide :limit and :offset parameters to handle pagination.
    #   >> cs.list_servers_detail
    #   => [{:name=>"MyServer", :addresses=>{:public=>["67.23.42.37"], :private=>["10.176.241.237"]}, :metadata=>{"MyData" => "Valid"}, :imageRef=>10, :progress=>100, :hostId=>"36143b12e9e48998c2aef79b50e144d2", :flavorRef=>1, :id=>110917, :status=>"ACTIVE"}]
    #
    #   >> cs.list_servers_detail(:limit => 2, :offset => 3)
    #   => [{:status=>"ACTIVE", :imageRef=>10, :progress=>100, :metadata=>{}, :addresses=>{:public=>["x.x.x.x"], :private=>["x.x.x.x"]}, :name=>"demo-standingcloud-lts", :id=>168867, :flavorRef=>1, :hostId=>"xxxxxx"},
    #       {:status=>"ACTIVE", :imageRef=>8, :progress=>100, :metadata=>{}, :addresses=>{:public=>["x.x.x.x"], :private=>["x.x.x.x"]}, :name=>"demo-aicache1", :id=>187853, :flavorRef=>3, :hostId=>"xxxxxx"}]
    def list_servers_detail(options = {})
      path = OpenStack.paginate(options).empty? ? "#{@connection.service_path}/servers/detail" : "#{@connection.service_path}/servers/detail?#{OpenStack.paginate(options)}"
      response = @connection.csreq("GET",@connection.service_host,path,@connection.service_port,@connection.service_scheme)
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      OpenStack.symbolize_keys(JSON.parse(response.body)["servers"])
    end
    alias :servers_detail :list_servers_detail

    # Creates a new server instance on OpenStack Compute
    #
    # The argument is a hash of options.  The keys :name, :flavorRef,
    # and :imageRef are required; :metadata and :personality are optional.
    #
    # :flavorRef and :imageRef are href strings identifying a particular
    # server flavor and image to use when building the server.  The :imageRef
    # can either be a stock image, or one of your own created with the
    # server.create_image method.
    #
    # The :metadata argument should be a hash of key/value pairs.  This
    # metadata will be applied to the server at the OpenStack Compute API level.
    #
    # The "Personality" option allows you to include up to five files, # of
    # 10Kb or less in size, that will be placed on the created server.
    # For :personality, pass a hash of the form {'local_path' => 'server_path'}.
    # The file located at local_path will be base64-encoded and placed at the
    # location identified by server_path on the new server.
    #
    # Returns a OpenStack::Compute::Server object.  The root password is
    # available in the adminPass instance method.
    #
    #   >> server = cs.create_server(
    #        :name        => 'NewServer',
    #        :imageRef    => '3',
    #        :flavorRef   => '1',
    #        :metadata    => {'Racker' => 'Fanatical'},
    #        :personality => {'/home/bob/wedding.jpg' => '/root/wedding.jpg'})
    #   => #<OpenStack::Compute::Server:0x101229eb0 ...>
    #   >> server.name
    #   => "NewServer"
    #   >> server.status
    #   => "BUILD"
    #   >> server.adminPass
    #   => "NewServerSHMGpvI"
    def create_server(options)
      raise OpenStack::Exception::MissingArgument, "Server name, flavorRef, and imageRef, must be supplied" unless (options[:name] && options[:flavorRef] && options[:imageRef])
      options[:personality] = Personalities.get_personality(options[:personality])
      data = JSON.generate(:server => options)
      response = @connection.csreq("POST",@connection.service_host,"#{@connection.service_path}/servers",@connection.service_port,@connection.service_scheme,{'content-type' => 'application/json'},data)
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      server_info = JSON.parse(response.body)['server']
      server = OpenStack::Compute::Server.new(self,server_info['id'])
      server.adminPass = server_info['adminPass']
      return server
    end

    # Returns an array of hashes listing available server images that you have access too,
    # including stock OpenStack Compute images and any that you have created.  The "id" key
    # in the hash can be used where imageRef is required. You can also provide :limit and
    # :offset parameters to handle pagination.
    #
    #   >> cs.list_images
    #   => [{:name=>"CentOS 5.2", :id=>2, :updated=>"2009-07-20T09:16:57-05:00", :status=>"ACTIVE", :created=>"2009-07-20T09:16:57-05:00"},
    #       {:name=>"Gentoo 2008.0", :id=>3, :updated=>"2009-07-20T09:16:57-05:00", :status=>"ACTIVE", :created=>"2009-07-20T09:16:57-05:00"},...
    #
    #   >> cs.list_images(:limit => 3, :offset => 2)
    #   => [{:status=>"ACTIVE", :name=>"Fedora 11 (Leonidas)", :updated=>"2009-12-08T13:50:45-06:00", :id=>13},
    #       {:status=>"ACTIVE", :name=>"CentOS 5.3", :updated=>"2009-08-26T14:59:52-05:00", :id=>7},
    #       {:status=>"ACTIVE", :name=>"CentOS 5.4", :updated=>"2009-12-16T01:02:17-06:00", :id=>187811}]
    def list_images(options = {})
      path = OpenStack.paginate(options).empty? ? "#{@connection.service_path}/images/detail" : "#{@connection.service_path}/images/detail?#{OpenStack.paginate(options)}"
      response = @connection.csreq("GET",@connection.service_host,path,@connection.service_port,@connection.service_scheme)
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      OpenStack.symbolize_keys(JSON.parse(response.body)['images'])
    end
    alias :images :list_images

    # Returns a OpenStack::Compute::Image object for the image identified by the provided id.
    #
    #   >> image = cs.get_image(8)
    #   => #<OpenStack::Compute::Image:0x101659698 ...>
    def get_image(id)
      OpenStack::Compute::Image.new(self,id)
    end
    alias :image :get_image

    # Returns an array of hashes listing all available server flavors.  The :id key in the hash can be used when flavorRef is required.
    #
    # You can also provide :limit and :offset parameters to handle pagination.
    #
    #   >> cs.list_flavors
    #   => [{:name=>"256 server", :id=>1, :ram=>256, :disk=>10},
    #       {:name=>"512 server", :id=>2, :ram=>512, :disk=>20},...
    #
    #   >> cs.list_flavors(:limit => 3, :offset => 2)
    #   => [{:ram=>1024, :disk=>40, :name=>"1GB server", :id=>3},
    #       {:ram=>2048, :disk=>80, :name=>"2GB server", :id=>4},
    #       {:ram=>4096, :disk=>160, :name=>"4GB server", :id=>5}]
    def list_flavors(options = {})
      path = OpenStack.paginate(options).empty? ? "#{@connection.service_path}/flavors/detail" : "#{@connection.service_path}/flavors/detail?#{OpenStack.paginate(options)}"
      response = @connection.csreq("GET",@connection.service_host,path,@connection.service_port,@connection.service_scheme)
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      OpenStack.symbolize_keys(JSON.parse(response.body)['flavors'])
    end
    alias :flavors :list_flavors

    # Returns a OpenStack::Compute::Flavor object for the flavor identified by the provided ID.
    #
    #   >> flavor = cs.flavor(1)
    #   => #<OpenStack::Compute::Flavor:0x10156dcc0 @name="256 server", @disk=10, @id=1, @ram=256>
    def get_flavor(id)
      OpenStack::Compute::Flavor.new(self,id)
    end
    alias :flavor :get_flavor

    # Returns the current state of the programatic API limits.  Each account has certain limits on the number of resources
    # allowed in the account, and a rate of API operations.
    #
    # The operation returns a hash.  The :absolute hash key reveals the account resource limits, including the maxmimum
    # amount of total RAM that can be allocated (combined among all servers), the maximum members of an IP group, and the
    # maximum number of IP groups that can be created.
    #
    # The :rate hash key returns an array of hashes indicating the limits on the number of operations that can be performed in a
    # given amount of time.  An entry in this array looks like:
    #
    #   {:regex=>"^/servers", :value=>50, :verb=>"POST", :remaining=>50, :unit=>"DAY", :resetTime=>1272399820, :URI=>"/servers*"}
    #
    # This indicates that you can only run 50 POST operations against URLs in the /servers URI space per day, we have not run
    # any operations today (50 remaining), and gives the Unix time that the limits reset.
    #
    # Another example is:
    #
    #   {:regex=>".*", :value=>10, :verb=>"PUT", :remaining=>10, :unit=>"MINUTE", :resetTime=>1272399820, :URI=>"*"}
    #
    # This says that you can run 10 PUT operations on all possible URLs per minute, and also gives the number remaining and the
    # time that the limit resets.
    #
    # Use this information as you're building your applications to put in relevant pauses if you approach your API limitations.
    def limits
      response = @connection.csreq("GET",@connection.service_host,"#{@connection.service_path}/limits",@connection.service_port,@connection.service_scheme)
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      OpenStack.symbolize_keys(JSON.parse(response.body)['limits'])
    end

  end
end
end
