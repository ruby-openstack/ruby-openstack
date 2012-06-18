#Initial version of this code is based on and refactored from the rackspace/ruby-cloudfiles repo
#@ https://github.com/rackspace/ruby-cloudfiles - Copyright (c) 2011, Rackspace US, Inc.
# See COPYING for license information
#
module OpenStack
module Swift
  class StorageObject

    attr_reader :name
    attr_reader :container
    attr_reader :metadata

    # Builds a new OpenStack::Swift::StorageObject in the specified container.
    # If force_exist is set, the object must exist or a
    # OpenStack::Exception::ItemNotFound will be raised.
    # If not, an "empty" StorageObject will be returned, ready for data
    # via the write method
    #
    # The container parameter must be an OpenStack::Swift::Container object.
    #
    # This constructor is typically not called directly. You can get a reference to
    # an existing Object via OpenStack::Swift::Container::object method or create a
    # new Object via OpenStack::Swift::Container::create_object method
    #
    def initialize(container, objectname, force_exists = false)
      @container = container
      @containername = container.name
      @name = objectname

      if force_exists
        raise OpenStack::Exception::ItemNotFound.new("No Object \"#{@name}\" found in Container \"#{@containername}\"", "404", "") unless container.object_exists?(objectname)
      end
    end

    #create a new Object in a given Container
    #optional headers: {
    #                    :metadata=>{key=>value, key1=>value1, ...}
    #                    :content_type=>content type of created object
    #                    :etag=>MD5 checksum of object data to be compared to that on server side
    #                    :manifest=>set manifest header for segmented large object
    #                   }
    #
    # The container parameter must be an OpenStack::Swift::Container object.
    # Typically you'd create an Object by first getting a Container:
    # cont = os.container("foo_container")
    # cont.create_object("my_new_object", {}, "object data")
    #
    def self.create(container, objectname, headers={}, data=nil)
      provided_headers = (headers[:metadata] || {}).inject({}){|res, (k,v)| ((k.to_s.match /^X-Object-Meta-/i) ? res[k.to_s]=v : res["X-Object-Meta-#{k.to_s}"]=v) ;res}
      provided_headers["content-type"] = headers[:content_type] unless headers[:content_type].nil?
      provided_headers["ETag"] = headers[:etag] unless headers[:etag].nil?
      provided_headers["X-Object-Manifest"] = headers[:manifest] unless headers[:manifest].nil?
      if data.nil? #just create an empty object
        path = "/#{container.name}/#{objectname}"
        provided_headers["content-length"] = "0"
        container.swift.connection.req("PUT", URI.encode(path), {:headers=>provided_headers})
      else
        self.new(container, objectname).write(data, provided_headers)
      end
      self.new(container, objectname)
    end

    # Retrieves Metadata for the object
    #  object = container.object("conversion_helper.rb")
    #  => #<OpenStack::Swift::StorageObject:0xb7692488  ....
    #  object.object_metadata
    #  => {:manifest=>nil, :bytes=>"1918", :content_type=>"application/octet-stream", :metadata=>{"foo"=>"bar, "herpa"=>"derp"}, :etag=>"1e5b089a1d92052bcf759d86465143f8", :last_modified=>"Tue, 17 Apr 2012 08:46:35 GMT"}
    #
    def object_metadata
      path = "/#{@containername}/#{@name}"
      response = @container.swift.connection.req("HEAD", path)
      resphash = response.to_hash
      meta = { :bytes=>resphash["content-length"][0],
               :content_type=>resphash["content-type"][0],
               :last_modified=>resphash["last-modified"][0],
               :etag=>resphash["etag"][0],
               :manifest=> (resphash.has_key?("x-object-manifest") ? resphash["x-object-manifest"][0] : nil),
               :metadata=>{}}
      resphash.inject({}){|res, (k,v)| meta[:metadata].merge!({ k.gsub("x-object-meta-", "") => v.first }) if k.match(/^x-object-meta-/)}
      meta
    end

    #returns just the user defined custom metadata
    # obj.metadata
    # => {"foo"=>"bar, "herpa"=>"derp"}
    def metadata
      self.object_metadata[:metadata]
    end

    # Size of the object (in bytes)
    # obj.bytes
    # => "493009"
    def bytes
      self.object_metadata[:bytes]
    end

    # Date of the object's last modification
    # obj.last_modified
    # => "Thu, 26 Apr 2012 09:22:51 GMT"
    def last_modified
      self.object_metadata[:last_modified]
    end

    # ETag of the object data
    # obj.etag
    # => "494e444f92a8082dabac80a74cdf2c3b"
    def etag
      self.object_metadata[:etag]
    end

    # Content type of the object data
    # obj.content_type
    # => "application/json"
    def content_type
      self.object_metadata[:content_type]
    end

    # Retrieves the data from an object and stores the data in memory.  The data is returned as a string.
    # Throws a OpenStack::Exception::ItemNotFound if the object doesn't exist.
    #
    # If the optional size and range arguments are provided, the call will return the number of bytes provided by
    # size, starting from the offset provided in offset.
    #
    #   object.data
    #   => "This is the text stored in the file"
    def data(size = -1, offset = 0, headers = {})
      headers = {'content-type'=>'application/json'}
      if size.to_i > 0
        range = sprintf("bytes=%d-%d", offset.to_i, (offset.to_i + size.to_i) - 1)
        headers['Range'] = range
      end
      path = "/#{@containername}/#{@name}"
      begin
        response = @container.swift.connection.req("GET", URI.encode(path), {:headers=>headers})
        response.body
      rescue OpenStack::Exception::ItemNotFound => not_found
        msg = "No Object \"#{@name}\" found in Container \"#{@containername}\".  #{not_found.message}"
        raise OpenStack::Exception::ItemNotFound.new(msg, not_found.response_code, not_found.response_body)
      end
    end
    alias :read :data

    # Retrieves the data from an object and returns a stream that must be passed to a block.
    # Throws a OpenStack::Exception::ItemNotFound if the object doesn't exist.
    #
    # If the optional size and range arguments are provided, the call will return the number of bytes provided by
    # size, starting from the offset provided in offset.
    #
    # The method returns the HTTP response object
    #
    #   data = ""
    #   object.data_stream do |chunk| data += chunk end
    #   => #<Net::HTTPOK 200 OK readbody=true>
    #   data
    #   => "This is the text stored in the file"
    def data_stream(size = -1, offset = 0, &block)
      headers = {'content-type'=>'application/json'}
      if size.to_i > 0
        range = sprintf("bytes=%d-%d", offset.to_i, (offset.to_i + size.to_i) - 1)
        headers['Range'] = range
      end
      server = @container.swift.connection.service_host
      path = @container.swift.connection.service_path + URI.encode("/#{@containername}/#{@name}")
      port = @container.swift.connection.service_port
      scheme = @container.swift.connection.service_scheme
      response = @container.swift.connection.csreq("GET", server, path, port, scheme, headers, nil, 0, &block)
      raise OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      response
    end

    # Sets the metadata for an object.  By passing a hash as an argument, you can set the metadata for an object.
    # However, setting metadata will overwrite any existing metadata for the object. Returns true if the call
    # was successful. Throws OpenStack::Exception::ItemNotFound if the object doesn't exist.
    #
    # The OpenStack mandated 'X-Object-Meta' prefix is optional:
    #
    # obj.set_metadata({:foo=>"bar", "X-Object-Meta-herpa"=>"derp", "author"=>"me"})
    # => true
    #
    # obj.metadata
    # => {"foo"=>"bar", "author"=>"me", "herpa"=>"derp"}
    #
    def set_metadata(metadatahash)
      headers  = metadatahash.inject({}){|res, (k,v)| ((k.to_s.match /^X-Object-Meta-/i) ? res[k.to_s]=v : res["X-Object-Meta-#{k.to_s}"]=v ) ;res}
      headers['content-type'] = 'application/json'
      path = "/#{@containername}/#{@name}"
      begin
        response = @container.swift.connection.req("POST", URI.encode(path), {:headers=>headers})
      rescue OpenStack::Exception::ItemNotFound => not_found
        msg = "Can't set metadata: No Object \"#{@name}\" found in Container \"#{@containername}\".  #{not_found.message}"
        raise OpenStack::Exception::ItemNotFound.new(msg, not_found.response_code, not_found.response_body)
      end
      true
    end
    alias :metadata= :set_metadata


    # Returns the object's manifest.
    #
    #    object.manifest
    #    => "container/prefix"
    def manifest
      self.object_metadata[:manifest]
    end


    # Sets the manifest for an object.  By passing a string as an argument, you can set the manifest for an object.
    # However, setting manifest will overwrite any existing manifest for the object.
    #
    # Throws OpenStack::Exception::ItemNotFound if the object doesn't exist. Returns true if the call is successful.
    #
    def set_manifest(manifest)
      headers = {'X-Object-Manifest' => manifest}
      path = "/#{@containername}/#{@name}"
      begin
        response = @container.swift.connection.req("POST", URI.encode(path), {:headers=>headers})
      rescue OpenStack::Exception::ItemNotFound => not_found
        msg = "Can't set manifest: No Object \"#{@name}\" found in Container \"#{@containername}\".  #{not_found.message}"
        raise OpenStack::Exception::ItemNotFound.new(msg, not_found.response_code, not_found.response_body)
      end
      true
    end


    # Takes supplied data and writes it to the object, saving it.  You can supply an optional hash of headers, including
    # Content-Type and ETag, that will be applied to the object.
    #
    # If you would rather stream the data in chunks, instead of reading it all into memory at once, you can pass an
    # IO object for the data, such as: object.write(open('/path/to/file.mp3'))
    #
    # You can compute your own MD5 sum and send it in the "ETag" header.  If you provide yours, it will be compared to
    # the MD5 sum on the server side.
    #
    # Returns true on success, raises exceptions if stuff breaks.
    #
    #   object = container.create_object("newfile.txt")
    #
    #   object.write("This is new data")
    #   => true
    #
    #   object.data
    #   => "This is new data"
    #
    #
    def write(data, headers = {})
      server = @container.swift.connection.service_host
      path = @container.swift.connection.service_path + URI.encode("/#{@containername}/#{@name}")
      port = @container.swift.connection.service_port
      scheme = @container.swift.connection.service_scheme
      body = (data.is_a?(String))? StringIO.new(data) : data
      body.binmode if (body.respond_to?(:binmode))
      response = @container.swift.connection.put_object(server, path, port, scheme, headers, body, 0)
      raise OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      true
    end

    # Copy this object to a new location (optionally in a new container)
    #
    # You must supply a name for the new object as well as a container name.
    #
    #    new_object = object.copy("new_obj", "my_container")
    #
    # You may also supply a hash of headers to set Content-Type, or custom
    # key=>value metadata:
    #optional headers: {
    #                    :metadata=>{key=>value, key1=>value1, ...}
    #                    :content_type=>content type of created object
    #                  }
    #
    #    copied = object.copy('newfile.tmp', "my_container", {:content_type=>"text/plain", :metadata=>{:herp=>"derp", "X-Object-Meta-foo"=>"bar} } )
    #    => => #<OpenStack::Swift::StorageObject:0xb728974c  .....
    #
    # Returns the new OpenStack::Swift::StorageObject for the copied item.
    #
    def copy(object_name, container_name, headers = {})
      provided_headers = (headers[:metadata] || {}).inject({}){|res, (k,v)| ((k.to_s.match /^X-Object-Meta-/i) ? res[k.to_s]=v : res["X-Object-Meta-#{k.to_s}"]=v) ;res}
      provided_headers["content-type"] = headers[:content_type] unless headers[:content_type].nil?
      provided_headers["X-Copy-From"] = "/#{@containername}/#{@name}"
      provided_headers["content-length"] = "0"
      path = "/#{container_name}/#{object_name}"
      begin
        response = @container.swift.connection.req("PUT", URI.encode(path), {:headers=>provided_headers})
      rescue OpenStack::Exception::ItemNotFound => not_found
        msg = "Can't copy \"#{@name}\": No Object \"#{@name}\" found in Container \"#{@containername}\".  #{not_found.message}"
        raise OpenStack::Exception::ItemNotFound.new(msg, not_found.response_code, not_found.response_body)
      end
      OpenStack::Swift::StorageObject.new(@container.swift.container(container_name), object_name)
    end

    # Takes the same options as the copy method, only it does a copy followed by a delete on the original object.
    #
    # Returns the new OpenStack::Swift::StorageObject for the moved item.
    # You should not attempt to use the old object after doing
    # a move.
    # optional headers: {
    #                    :metadata=>{key=>value, key1=>value1, ...}
    #                    :content_type=>content type of created object
    #                  }
    def move(object_name, container_name, headers={})
      new_object = self.copy(object_name, container_name, headers)
      @container.delete_object(@name)
      new_object
    end

    def to_s # :nodoc:
      @name
    end

  end
end
end
