#Initial version of this code is based on and refactored from the rackspace/ruby-cloudfiles repo
#@ https://github.com/rackspace/ruby-cloudfiles - Copyright (c) 2011, Rackspace US, Inc.
# See COPYING for license information
#
module OpenStack
module Swift
  class Container

    attr_reader :name
    attr_reader :swift
    attr_reader :metadata

    def initialize(swift, name)
      @swift = swift
      @name = name
      @metadata = container_metadata
    end

    # Retrieves Metadata for the container
    def container_metadata
      path = "/#{URI.encode(@name.to_s)}"
      response = @swift.connection.req("HEAD", path)
      resphash = response.to_hash
      meta = {:bytes=>resphash["x-container-bytes-used"][0], :count=>resphash["x-container-object-count"][0], :metadata=>{}}
      resphash.inject({}){|res, (k,v)| meta[:metadata].merge!({ k.gsub("x-container-meta-", "") => v.first }) if k.match(/^x-container-meta-/)}
      meta
    end

    # Returns the container's metadata as a Hash, stripping off the X-Meta-Object-
    # prefix that OpenStack prepends to the metadata key name.
    #
    #    object.metadata
    #    => {"ruby"=>"cool", "foo"=>"bar"}
    def metadata
      metahash = {}
      self.container_metadata[:metadata].each{ |key, value| metahash[key.gsub(/x-container-meta-/, '').gsub(/%20/, ' ')] = URI.decode(value).gsub(/\+\-/, ' ') }
      metahash
    end

    # Sets the metadata for a container.  By passing a hash as an argument, you can set the metadata for an object.
    # New calls to set metadata are additive.  To remove metadata, set the value of the key to nil.
    # Including the X-Container-Meta- prefix for each metadata key is optional:
    #
    # container = os.container("foo")
    # container.set_metadata({"X-Container-Meta-Author"=> "msa", "version"=>"1.2", :date=>"today"})
    # => true
    # container.metadata
    # => {"date"=>"today", "author"=>"msa", "version"=>"1.2"}
    #
    # Returns true if operation is successful;  Throws OpenStack::Exception::ItemNotFound if the
    # container doesn't exist.
    #
    def set_metadata(metadatahash)
      headers = metadatahash.inject({}){|res, (k,v)| ((k.to_s.match /^X-Container-Meta-/i) ? res[k.to_s]=v : res["X-Container-Meta-#{k}"]=v ) ; res}
      headers.merge!({'content-type'=>'application/json'})
      begin
        response = @swift.connection.req("POST", URI.encode("/#{@name.to_s}"), {:headers=>headers} )
        true
      rescue OpenStack::Exception::ItemNotFound => not_found
        msg = "Cannot set metadata - container: \"#{@name}\" does not exist!.  #{not_found.message}"
        raise OpenStack::Exception::ItemNotFound.new(msg, not_found.response_code, not_found.response_body)
      end
    end

    # Size of the container (in bytes)
    def bytes
      container_metadata[:bytes]
    end

    # Number of objects in the container
    def count
      container_metadata[:count]
    end

    # Returns the OpenStack::Swift::StorageObject for the named object.
    # Refer to the OpenStack::Swift::StorageObject class for available methods.
    # If the object exists, it will be returned.  If the object does not exist,
    # a OpenStack::Exception::ItemNotFound will be thrown.
    #
    #   object = container.object('test.txt')
    #   object.data
    #   => "This is test data"
    #
    #   object = container.object('newfile.txt')
    #   => OpenStack::Exception::ItemNotFound: No Object "newfile.txt" found in Container "another_container_foo"
    #
    def object(objectname)
      o = OpenStack::Swift::StorageObject.new(self, objectname, true)
      return o
    end
    alias :get_object :object


    # Gathers a list of all available objects in the current container and returns an array of object names.
    #   container = cf.container("My Container")
    #   container.objects
    #   => [ "cat", "dog", "donkey", "monkeydir", "monkeydir/capuchin"]
    # Pass a limit argument to limit the list to a number of objects:
    #   container.objects(:limit => 1)                  #=> [ "cat" ]
    # Pass an marker with or without a limit to start the list at a certain object:
    #   container.objects(:limit => 1, :marker => 'dog')                #=> [ "donkey" ]
    # Pass a prefix to search for objects that start with a certain string:
    #   container.objects(:prefix => "do")       #=> [ "dog", "donkey" ]
    # Only search within a certain pseudo-filesystem path:
    #   container.objects(:path => 'monkeydir')     #=> ["monkeydir/capuchin"]
    # Only grab "virtual directories", based on a single-character delimiter (no "directory" objects required):
    #   container.objects(:delimiter => '/')      #=> ["monkeydir"]
    # All arguments to this method are optional.
    #
    # Returns an empty array if no object exist in the container.
    # if the request fails.
    def objects(params = {})
      path = "/#{@name.to_s}"
      path = (params.empty?)? path : OpenStack.get_query_params(params, [:limit, :marker, :prefix, :path, :delimiter], path)
      response = @swift.connection.req("GET", URI.encode(path))
      OpenStack.symbolize_keys(JSON.parse(response.body)).inject([]){|res, cur| res << cur[:name]; res }
    end
    alias :list_objects :objects

    # Retrieves a list of all objects in the current container along with their size
    # in bytes, hash, and content_type. If no objects exist, an empty hash is returned.
    #
    # Accepts the same options as 'objects' method to limit the returned set.
    #
    #   container.objects_detail
    #   => {"test.txt"=>{:content_type=>"application/octet-stream",
    #                    :hash=>"e2a6fcb4771aa3509f6b27b6a97da55b",
    #                    :last_modified=>Mon Jan 19 10:43:36 -0600 2009,
    #                    :bytes=>"16"},
    #       "new.txt"=>{:content_type=>"application/octet-stream",
    #                   :hash=>"0aa820d91aed05d2ef291d324e47bc96",
    #                   :last_modified=>Wed Jan 28 10:16:26 -0600 2009,
    #                   :bytes=>"22"}
    #      }
    def objects_detail(params = {})
      path = "/#{@name.to_s}"
      path = (params.empty?)? path : OpenStack.get_query_params(params, [:limit, :marker, :prefix, :path, :delimiter], path)
      response = @swift.connection.req("GET", URI.encode(path))
      OpenStack.symbolize_keys(JSON.parse(response.body)).inject({}){|res, current| res.merge!({current[:name]=>{:bytes=>current[:bytes].to_s, :content_type=>current[:content_type].to_s, :last_modified=>current[:last_modified], :hash=>current[:hash]}}) ; res }
    end
    alias :list_objects_info :objects_detail

    # Returns true if a container is empty and returns false otherwise.
    #
    #   new_container.empty?
    #   => true
    #
    #   full_container.empty?
    #   => false
    def empty?
      return (container_metadata[:count].to_i == 0)? true : false
    end

    # Returns true if object exists and returns false otherwise.
    #
    #   container.object_exists?('goodfile.txt')
    #   => true
    #
    #   container.object_exists?('badfile.txt')
    #   => false
    def object_exists?(objectname)
      path = "/#{@name.to_s}/#{objectname}"
      begin
        response = @swift.connection.req("HEAD", URI.encode(path))
        true
      rescue OpenStack::Exception::ItemNotFound
        false
      end
    end

    # Creates a new OpenStack::Swift::StorageObject in the current container.
    #
    # If an object with the specified name exists in the current container, that object will be overwritten
    #
    #optional headers: {
    #                    :metadata=>{key=>value, key1=>value1, ...}
    #                    :content_type=>content type of created object
    #                    :etag=>MD5 checksum of object data to be compared to that on server side
    #                    :manifest=>set manifest header for segmented large object
    #                   }
    # The optional data can be a File or a String - see StorageObject.create and .write methods
    def create_object(objectname, headers={}, data=nil)
      OpenStack::Swift::StorageObject.create(self, objectname, headers, data)
    end

    # Removes an OpenStack::Swift::StorageObject from a container.
    # True is returned if the removal is successful.
    # Throws  OpenStack::Exception::ItemNotFound if the object doesn't exist.
    #
    #   container.delete_object('new.txt')
    #   => true
    #
    #   container.delete_object('Foo')
    #   =>OpenStack::Exception::ItemNotFound: The object: "Foo" does not exist in container "another_containerfoo".  The resource could not be found
    #
    def delete_object(objectname)
      path = "/#{@name.to_s}/#{objectname}"
      begin
        response = @swift.connection.req("DELETE", URI.encode(path))
        true
      rescue OpenStack::Exception::ItemNotFound => not_found
        msg = "The object: \"#{objectname}\" does not exist in container \"#{@name}\".  #{not_found.message}"
        raise OpenStack::Exception::ItemNotFound.new(msg, not_found.response_code, not_found.response_body)
      end
    end


    def to_s # :nodoc:
      @name
    end

  end
end
end
