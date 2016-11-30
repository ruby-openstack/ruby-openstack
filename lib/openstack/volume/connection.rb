module OpenStack
module Volume

  class Connection

    attr_accessor   :connection
    attr_reader     :volumes_native
    attr_reader     :volume_path

    def initialize(connection)
      @connection = connection
      OpenStack::Authentication.init(@connection)
      @volumes_native, @volume_path = check_if_native("volumes")
      @snapshots_native, @snapshot_path = check_if_native("snapshots")
    end

    # Returns true if the authentication was successful and returns false otherwise.
    #
    #   cs.authok?
    #   => true
    def authok?
      @connection.authok
    end

    #require params:  {:display_name, :size}
    #optional params: {:display_description, :metadata=>{:key=>val, ...}, :availability_zone, :volume_type }
    #returns OpenStack::Volume::Volume object
    def create_volume(options)
      raise OpenStack::Exception::MissingArgument, ":display_name and :size must be specified to create a volume" unless (options[:display_name] && options[:size])
      data = JSON.generate(:volume => options)
      response = @connection.csreq("POST",@connection.service_host,"#{@connection.service_path}/#{@volume_path}",@connection.service_port,@connection.service_scheme,{'content-type' => 'application/json'},data)
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      volume_info = JSON.parse(response.body)["volume"]
      OpenStack::Volume::Volume.new(self, volume_info)
    end

    #no options documented in API at Nov 2012
    #(e.g. like limit/marker as used in Nova for servers)
    def list_volumes(options = {})
      path = options.empty? ? "/#{@volume_path}/detail" : "/#{@volume_path}/detail?#{options.to_query}"
      response = @connection.req("GET", path)
      volumes_hash = JSON.parse(response.body)["volumes"]
      volumes_hash.inject([]){|res, current| res << OpenStack::Volume::Volume.new(self, current); res}
    end
    alias :volumes :list_volumes


    def get_volume(vol_id)
      response = @connection.req("GET", "/#{@volume_path}/#{vol_id}")
      volume_hash = JSON.parse(response.body)["volume"]
      OpenStack::Volume::Volume.new(self, volume_hash)
    end
    alias :volume :get_volume

    def delete_volume(vol_id)
      response = @connection.req("DELETE", "/#{@volume_path}/#{vol_id}")
      true
    end

    def list_snapshots
      response = @connection.req("GET", "/#{@snapshot_path}")
      snapshot_hash = JSON.parse(response.body)["snapshots"]
      snapshot_hash.inject([]){|res, current| res << OpenStack::Volume::Snapshot.new(current); res}
    end
    alias :snapshots :list_snapshots

    def get_snapshot(snap_id)
      response = @connection.req("GET", "/#{@snapshot_path}/#{snap_id}")
      snapshot_hash = JSON.parse(response.body)["snapshot"]
      OpenStack::Volume::Snapshot.new(snapshot_hash)
    end
    alias :snapshot :get_snapshot

    #require params:  {:display_name, :volume_id}
    #optional params: {:display_description, :metadata=>{:key=>val, ...}, :availability_zone, :volume_type }
    #returns OpenStack::Volume::Snapshot object
    def create_snapshot(options)
      raise OpenStack::Exception::MissingArgument, ":volume_id and :display_name must be specified to create a snapshot" unless (options[:display_name] && options[:volume_id])
      #:force documented in API but not explained... clarify (fails without)
      options.merge!({:force=>"true"})
      data = JSON.generate(:snapshot => options)
      response = @connection.csreq("POST",@connection.service_host,"#{@connection.service_path}/#{@snapshot_path}",@connection.service_port,@connection.service_scheme,{'content-type' => 'application/json'},data)
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      snapshot_info = JSON.parse(response.body)["snapshot"]
      OpenStack::Volume::Snapshot.new(snapshot_info)
    end

    def delete_snapshot(snap_id)
      @connection.req("DELETE", "/#{@snapshot_path}/#{snap_id}")
      true
    end

    # [ {:extra_specs=>{:volume_backend_name=>"volumes-standard"}, :name=>"slow", :id=>"b3a104b6-fe70-4450-8681-e911a153f41f"},
    #   {:extra_specs=>{:volume_backend_name=>"volumes-speed"}, :name=>"fast", :id=>"0e278952-9baa-4aa8-88a7-fe8387f1d86c"} ]
    def list_volume_types
      response = @connection.req('GET', '/types')
      OpenStack.symbolize_keys(JSON.parse(response.body)['volume_types'])
    end
    alias :types :list_volume_types

    # get_quotas(1)
    # => { "volumes_slow"=>-1, "snapshots_slow"=>-1, "gigabytes_slow"=>-1,
    #      "volumes_fast"=>-1, "snapshots_fast"=>-1, "gigabytes_fast"=>-1,
    #      "volumes"=>10, "snapshots"=>10, "gigabytes"=>1001, "id"=>"1"}
    def get_quotas(tenant_id)
      response = @connection.req('GET', "/os-quota-sets/#{tenant_id}")
      JSON.parse(response.body)['quota_set']
    end

    # quota_set = { gigabytes: 500, gigabytes_slow: 200, gigabytes_fast: 300 }
    # cinder.update_quotas(1, quota_set)
    def update_quotas(tenant_id, quota_set)
      req_body = JSON.generate({'quota_set' => quota_set})
      response = @connection.req('PUT', "/os-quota-sets/#{tenant_id}", data: req_body)
      JSON.parse(response.body)['quota_set']
    end

    # Lists all back-end storage pools that are known to the scheduler service
    def get_pools(details = true)
      path = details ? "/scheduler-stats/get_pools?detail=true" : "/scheduler-stats/get_pools"
      response = @connection.req('GET', path)
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      JSON.parse(response.body)['pools']
    end

    private

    #fudge... not clear if volumes support is available as 'native' volume API or
    #as the os-volumes extension. Need to probe to find out (for now)
    #see https://lists.launchpad.net/openstack/msg16601.html
    def check_if_native(entity) #volumes or snapshots
      native = extension = false
      #check if 'native' volume API present:
      begin
        response = @connection.req("GET", "/#{entity}")
        native = true if response.code.match(/^20.$/)
        return true, entity
      rescue OpenStack::Exception::ItemNotFound => not_found
        native = false
      end
      #check if available as extension:
      begin
        response = @connection.req("GET", "/os-#{entity}")
        extension = true if response.code.match(/^20.$/)
        return false, "os-#{entity}"
      rescue OpenStack::Exception::ItemNotFound => not_found
        extension = false
      end
      raise OpenStack::Exception::NotImplemented.new("No Volumes support for this provider", 501, "No #{entity} Support") unless (native || extension)
    end




  end

end
end
