module OpenStack
module Compute

  class Connection

    attr_accessor   :connection
    attr_accessor   :extensions

    def initialize(connection)
      @extensions = nil
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
      json_server_list = JSON.parse(response.body)["servers"]
      json_server_list.each do |server|
        server["addresses"] = OpenStack::Compute::Address.fix_labels(server["addresses"])
      end
      OpenStack.symbolize_keys(json_server_list)
    end
    alias :servers_detail :list_servers_detail

    # Creates a new server instance on OpenStack Compute
    #
    # The argument is a hash of options.  The keys :name, :flavorRef,
    # and :imageRef are required; :metadata, :security_groups,
    # :key_name and :personality are optional.
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
    #        :personality => {'/home/bob/wedding.jpg' => '/root/wedding.jpg'},
    #        :key_name    => "mykey",
    #        :security_groups => [ "devel", "test"])
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
      options[:security_groups] = (options[:security_groups] || []).inject([]){|res, c| res << {"name"=>c} ;res}
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

# ==============================
#  API EXTENSIONS
#
#  http://nova.openstack.org/api_ext/index.html
#  http://api.openstack.org/ (grep 'Compute API Extensions')
#


    #query the openstack provider for any implemented extensions to the compute API
    #returns a hash with openstack service provider's returned details
    #about the implemented extensions, e.g.:
    #
    # { :os-floating_ips =>  { :links=>[],
    #                       :updated=>"2011-06-16T00:00:00+00:00",
    #                       :description=>"Floating IPs support",
    #                       :namespace=>"http://docs.openstack.org/ext/floating_ips/api/v1.1",
    #                       :name=>"Floating_ips", :alias=>"os-floating-ips"},
    #   :os-keypairs     =>  { :links=>[],
    #                       :updated=>"2011-08-08T00:00:00+00:00",
    #                       :description=>"Keypair Support",
    #                       :namespace=>"http://docs.openstack.org/ext/keypairs/api/v1.1",
    #                       :name=>"Keypairs",
    #                       :alias=>"os-keypairs"}
    # }
    #
    def api_extensions
      if @extensions.nil?
        response = @connection.req("GET", "/extensions")
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
        res = OpenStack.symbolize_keys(JSON.parse(response.body))
        @extensions = res[:extensions].inject({}){|result, c| result[c[:alias].to_sym] = c  ; result}
      end
      @extensions
    end

    # Retrieve a list of key pairs associated with the current authenticated account
    # Will return a hash:
    #  { :key_one => {  :fingerprint  =>  "3f:12:4d:d1:54:f1:f4:3f:fe:a8:12:ec:1a:fb:35:b2",
    #                   :public_key   =>  "ssh-rsa AAAAB3Nza923kJU123AADAQABAAAAg928JUwydszi029kIJudfOzQ7o160Ll1ItybDzYYcCAJ/N02loIKJU17264520bmXZFSsaZf2ErX3nSBNI3K+2zQzu832jkhkfdsa7GHH5hvNOxO7u800894312JKLJLHP/R91fdsajHKKJADSAgQ== nova@nv-zz2232-api0002\n",
    #                   :name         =>  "key_one"},
    #
    #    :key_two =>  { :fingerprint  =>  "6b:32:dd:d2:51:c1:f2:3a:fb:a2:52:3a:1a:bb:25:1b",
    #                   :public_key   =>  "ssh-rsa AKIJUuw71645kJU123AADAQABAAAAg928019oiUJY12765IJudfOzQ7o160Ll1ItybDzYYcCAJ/N80438012480321jhkhKJlfdsazu832jkhkfdsa7GHH5fdasfdsajlj2999789799987989894312JKLJLHP/R91fdsajHKKJADSAgQ== nova@bv-fdsa32-api0002\n",
    #                   :name         =>  "key_two"}
    #  }
    #
    # Raises OpenStack::Exception::NotImplemented if the current provider doesn't
    # offer the os-keypairs extension
    #
    def keypairs
      begin
        response = @connection.req("GET", "/os-keypairs")
        res = OpenStack.symbolize_keys(JSON.parse(response.body))
        res[:keypairs].inject({}){|result, c| result[c[:keypair][:name].to_sym] = c[:keypair] ; result }
      rescue OpenStack::Exception::ItemNotFound => not_found
        msg = "The os-keypairs extension is not implemented for the provider you are talking to "+
              "- #{@connection.http.keys.first}"
        raise OpenStack::Exception::NotImplemented.new(msg, 501, "#{not_found.message}")
      end
    end

    # Create a new keypair for use with launching servers. Raises
    # a OpenStack::Exception::NotImplemented if os-keypairs extension
    # is not implemented (or not advertised) by the OpenStack provider.
    #
    # The 'name' parameter MUST be supplied, otherwise a
    # OpenStack::Exception::MissingArgument will be raised.
    #
    # Optionally requests can specify a 'public_key' parameter,
    # with the full public ssh key (String) to be used to create the keypair
    # (i.e. import a existing key).
    #
    # Returns a hash with details of the new key; the :private_key attribute
    # must be saved must be saved by caller (not retrievable thereafter).
    # NOTE: when the optional :public_key parameter is given, the response
    # will obviously NOT contain the :private_key attribute.
    #
    # >> os.create_keypair({:name=>"test_key"})
    # => {  :name         =>  "test_key",
    #       :fingerprint  =>  "f1:f3:a2:d3:ca:75:da:f1:06:f4:f7:dc:cc:7d:e1:ca",
    #       :user_id      =>  "dev_41247879706381",
    #       :public_key   =>  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDgGhDH3z9uMAvPV8ziE9BCEjHCPXGufy5bOgY5mY5jOSfdmKspdbl0z/LimHVKRDNX6HoL5qRg5V/tGH/NYP5sX2zF/XRKz16lfBxiUL1EONXA9fsTEBR3FGp8NcA7hW2+YiUxWafms4If3NFqttTQ11XqTU8JCMvms4D81lhbiQ== nova@use03147k5-eth0\n",
    #       :private_key  =>  "-----BEGIN RSA PRIVATE KEY-----\nMIICXwIBAAKBgQDgGhDH3z9uMAvPV8ziE9BCEjHCPXGufy5bOgY5mY5jOSfdmKsp\ndbl0z/LimHVKRDNX6HoL5qRg5V/tGH/NYP5sX2zF/XRKz16lfBxiUL1EONXA9fsT\nEBR3FGp8NcA7hW2+YiUxWafms4If3NFqttTQ11XqTU8JCMvms4D81lhbiQIDAQAB\nAoGBAJ1akAfXwNEc2V4IV2sy4FtULS4nOKh+0szpjC9rm+gd3Nki9qQQ7lyQGwpy\nZID2LFsAeJnco/UJefaf6jUKcvnS7tlxMuQB8DBlepiDqnnec0EiEAVmmt9GWlYZ\nJgfGWqDzI1WtouDCIsOhx1Vq7Foue6pgOnibktg2kfYnH9IRAkEA9tKzhlr9rFui\nbVDkiRJK3VTIhKyk4davDjqPJFLJ+4+77wRW164sGxwReD7HtW6qVtJd1MFvqLDO\nqJJEsqDvXQJBAOhvGaWiAPSuP+/z6GE6VXB1pADQFTYIp2DXUa5DcStTGe7hGF1b\nDeAxpDNBbLO3YKYqi2L9vJcIsp5PkHlEVh0CQQCVLIkWBb5VQliryv0knuqiVFCQ\nZyuL1s2cQuYqZOLwaFGERtIZrom3pMImM4NN82F98cyF/pb2lE2CckyUzVF9AkEA\nqhwFjS9Pu8N7j8XWoLHsre2rJd0kaPNUbI+pe/xn6ula5XVgO5LUSOyL2+daAv2G\ngpZIhR5m07LN5wccGWRmEQJBALZRenXaSyX2R2C9ag9r2gaU8/h+aU9he5kjXIt8\n+B8wvpvfOkpOAVCQEMxtsDkEixUtI98YKZP60uw+Xzh40YU=\n-----END RSA PRIVATE KEY-----\n"
    #   }
    #
    # Will raise an OpenStack::Exception::BadRequest if an invalid public_key is provided:
    # >> os.create_keypair({:name=>"marios_keypair_test_invalid", :public_key=>"derp"})
    # => OpenStack::Exception::BadRequest: Unexpected error while running command.
    #    Stdout: '/tmp/tmp4kI12a/import.pub is not a public key file.\n'
    #
    def create_keypair(options)
      raise OpenStack::Exception::NotImplemented.new("os-keypairs not implemented by #{@connection.http.keys.first}", 501, "NOT IMPLEMENTED") unless api_extensions[:"os-keypairs"]
      raise OpenStack::Exception::MissingArgument, "Keypair name must be supplied" unless (options[:name])
      data = JSON.generate(:keypair => options)
      response = @connection.req("POST", "/os-keypairs", {:data=>data})
      res = OpenStack.symbolize_keys(JSON.parse(response.body))
      res[:keypair]
    end

    # Delete an existing keypair. Raises OpenStack::Exception::NotImplemented
    # if os-keypairs extension is not implemented (or not advertised) by the OpenStack provider.
    #
    # Returns true if succesful.
    # >> os.delete_keypair("marios_keypair")
    # => true
    #
    # Will raise OpenStack::Exception::ItemNotFound if specified keypair doesn't exist
    #
    def delete_keypair(keypair_name)
      raise OpenStack::Exception::NotImplemented.new("os-keypairs not implemented by #{@connection.http.keys.first}", 501, "NOT IMPLEMENTED") unless api_extensions[:"os-keypairs"]
      @connection.req("DELETE", "/os-keypairs/#{keypair_name}")
      true
    end

    #Security Groups:
    #Returns a hash with the security group IDs as keys:
    #=> { "1381" => { :tenant_id=>"12345678909876", :id=>1381, :name=>"default", :description=>"default",
    #                 :rules=> [
    #                           {:from_port=>22, :group=>{}, :ip_protocol=>"tcp", :to_port=>22,
    #                            :parent_group_id=>1381, :ip_range=>{:cidr=>"0.0.0.0/0"}, :id=>4902},
    #                           {:from_port=>80, :group=>{}, :ip_protocol=>"tcp", :to_port=>80,
    #                            :parent_group_id=>1381, :ip_range=>{:cidr=>"0.0.0.0/0"}, :id=>4903},
    #                           {:from_port=>443, :group=>{}, :ip_protocol=>"tcp", :to_port=>443,
    #                            :parent_group_id=>1381, :ip_range=>{:cidr=>"0.0.0.0/0"}, :id=>4904},
    #                           {:from_port=>-1, :group=>{}, :ip_protocol=>"icmp", :to_port=>-1,
    #                            :parent_group_id=>1381, :ip_range=>{:cidr=>"0.0.0.0/0"}, :id=>4905}],
    #                          ]
    #               },
    #     "1234" => { ... } }
    #
    def security_groups
      raise OpenStack::Exception::NotImplemented.new("os-security-groups not implemented by #{@connection.http.keys.first}", 501, "NOT IMPLEMENTED") unless api_extensions[:"os-security-groups"] or api_extensions[:security_groups]
      response = @connection.req("GET", "/os-security-groups")
      res = OpenStack.symbolize_keys(JSON.parse(response.body))
      res[:security_groups].inject({}){|result, c| result[c[:id].to_s] = c ; result }
    end

    def security_group(id)
      raise OpenStack::Exception::NotImplemented.new("os-security-groups not implemented by #{@connection.http.keys.first}", 501, "NOT IMPLEMENTED") unless api_extensions[:"os-security-groups"] or api_extensions[:security_groups]
      response = @connection.req("GET", "/os-security-groups/#{id}")
      res = OpenStack.symbolize_keys(JSON.parse(response.body))
      {res[:security_group][:id].to_s => res[:security_group]}
    end

    def create_security_group(name, description)
      raise OpenStack::Exception::NotImplemented.new("os-security-groups not implemented by #{@connection.http.keys.first}", 501, "NOT IMPLEMENTED") unless api_extensions[:"os-security-groups"] or api_extensions[:security_groups]
      data = JSON.generate(:security_group => { "name" => name, "description" => description})
      response = @connection.req("POST", "/os-security-groups", {:data => data})
      res = OpenStack.symbolize_keys(JSON.parse(response.body))
      {res[:security_group][:id].to_s => res[:security_group]}
    end

    def delete_security_group(id)
      raise OpenStack::Exception::NotImplemented.new("os-security-groups not implemented by #{@connection.http.keys.first}", 501, "NOT IMPLEMENTED") unless api_extensions[:"os-security-groups"] or api_extensions[:security_groups]
      response = @connection.req("DELETE", "/os-security-groups/#{id}")
      true
    end

    #params: { :ip_protocol=>"tcp", :from_port=>"123", :to_port=>"123", :cidr=>"192.168.0.1/16", :group_id:="123" }
    #observed behaviour against Openstack@HP cloud - can specify either cidr OR group_id as source, but not both
    #if both specified, the group is used and the cidr ignored.
    def create_security_group_rule(security_group_id, params)
      raise OpenStack::Exception::NotImplemented.new("os-security-groups not implemented by #{@connection.http.keys.first}", 501, "NOT IMPLEMENTED") unless api_extensions[:"os-security-groups"] or api_extensions[:security_groups]
      params.merge!({:parent_group_id=>security_group_id.to_s})
      data = JSON.generate(:security_group_rule => params)
      response = @connection.req("POST", "/os-security-group-rules", {:data => data})
      res = OpenStack.symbolize_keys(JSON.parse(response.body))
      {res[:security_group_rule][:id].to_s => res[:security_group_rule]}
    end

    def delete_security_group_rule(id)
      raise OpenStack::Exception::NotImplemented.new("os-security-groups not implemented by #{@connection.http.keys.first}", 501, "NOT IMPLEMENTED") unless api_extensions[:"os-security-groups"] or api_extensions[:security_groups]
      response = @connection.req("DELETE", "/os-security-group-rules/#{id}")
      true
    end

#VOLUMES - attach detach
    def attach_volume(server_id, volume_id, device_id)
      raise OpenStack::Exception::NotImplemented.new("os-volumes not implemented by #{@connection.http.keys.first}", 501, "NOT IMPLEMENTED") unless api_extensions[:"os-volumes"]
      data = JSON.generate(:volumeAttachment => {"volumeId" => volume_id, "device"=> device_id})
      response = @connection.req("POST", "/servers/#{server_id}/os-volume_attachments", {:data=>data})
      true
    end

    def list_attachments(server_id)
      raise OpenStack::Exception::NotImplemented.new("os-volumes not implemented by #{@connection.http.keys.first}", 501, "NOT IMPLEMENTED") unless api_extensions[:"os-volumes"]
      response = @connection.req("GET", "/servers/#{server_id}/os-volume_attachments")
      OpenStack.symbolize_keys(JSON.parse(response.body))
    end

    def detach_volume(server_id, attachment_id)
      raise OpenStack::Exception::NotImplemented.new("os-volumes not implemented by #{@connection.http.keys.first}", 501, "NOT IMPLEMENTED") unless api_extensions[:"os-volumes"]
      response = @connection.req("DELETE", "/servers/#{server_id}/os-volume_attachments/#{attachment_id}")
      true
    end


#FLOATING IPs:
  #list all float ips associated with tennant or account
    def get_floating_ips
      check_extension("os-floating-ips")
      response = @connection.req("GET", "/os-floating-ips")
      res = JSON.parse(response.body)["floating_ips"]
      res.inject([]){|result, c| result<< OpenStack::Compute::FloatingIPAddress.new(c) ; result }
    end
    alias :floating_ips :get_floating_ips

    #get details of a specific floating_ip by its id
    def get_floating_ip(id)
      check_extension("os-floating-ips")
      response = @connection.req("GET", "/os-floating-ips/#{id}")
      res = JSON.parse(response.body)["floating_ip"]
      OpenStack::Compute::FloatingIPAddress.new(res)
    end
    alias :floating_ip :get_floating_ip


    #can optionally pass the :pool parameter
    def create_floating_ip(opts={})
      check_extension("os-floating-ips")
      data = opts[:pool] ? JSON.generate(opts) : JSON.generate({:pool=>nil})
      response = @connection.req("POST", "/os-floating-ips",{:data=>data} )
      res = JSON.parse(response.body)["floating_ip"]
      OpenStack::Compute::FloatingIPAddress.new(res)
    end
    alias :allocate_floating_ip :create_floating_ip

    #delete or deallocate a floating IP using its id
    def delete_floating_ip(id)
      check_extension("os-floating-ips")
      response = @connection.req("DELETE", "/os-floating-ips/#{id}")
      true
    end

    #add or attach a floating IP to a runnin g server
    def attach_floating_ip(opts={:server_id=>"", :ip_id => ""})
      check_extension("os-floating-ips")
      #first get the address:
      addr = get_floating_ip(opts[:ip_id]).ip
      data = JSON.generate({:addFloatingIp=>{:address=>addr}})
      response = @connection.req("POST", "/servers/#{opts[:server_id]}/action", {:data=>data})
      true
    end

    def detach_floating_ip(opts={:server_id=>"", :ip_id => ""})
      check_extension("os-floating-ips")
      #first get the address:
      addr = get_floating_ip(opts[:ip_id]).ip
      data = JSON.generate({:removeFloatingIp=>{:address=>addr}})
      response = @connection.req("POST", "/servers/#{opts[:server_id]}/action", {:data=>data})
      true
    end

    private

    def check_extension(name)
      raise OpenStack::Exception::NotImplemented.new("#{name} not implemented by #{@connection.http.keys.first}", 501, "NOT IMPLEMENTED") unless api_extensions[name.to_sym]
      true
    end


end

end
end
