module OpenStack
module Volume

  class Connection

    attr_accessor   :connection
    attr_reader     :volumes_native

    def initialize(connection)
      @connection = connection
      OpenStack::Authentication.init(@connection)
      @volumes_native, @volume_path = check_if_native
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
      volume_info = JSON.parse(response.body)["volume"]
      volume = OpenStack::Volume::Volume.new(volume_info)
    end

    #no options documented in API at Nov 2012
    #(e.g. like limit/marker as used in Nova for servers)
    def list_volumes
      response = @connection.req("GET", "/#{@volume_path}")
      volumes_hash = JSON.parse(response.body)["volumes"]
      volumes_hash.inject([]){|res, current| res << OpenStack::Volume::Volume.new(current); res}
    end
    alias :volumes :list_volumes


    def get_volume(vol_id)
      response = @connection.req("GET", "/#{@volume_path}/#{vol_id}")
      volume_hash = JSON.parse(response.body)["volume"]
      OpenStack::Volume::Volume.new(volume_hash)
    end
    alias :volume :get_volume

    def delete_volume(vol_id)
      response = @connection.req("DELETE", "/#{@volume_path}/#{vol_id}")
      true
    end

    #TODO SNAPSHOTS

    private

    #fudge... not clear if volumes support is available as 'native' volume API or
    #as the os-volumes extension. Need to probe to find out (for now)
    #see https://lists.launchpad.net/openstack/msg16601.html
    def check_if_native
      native = extension = false
      #check if 'native' volume API present:
      begin
        response = @connection.req("GET", "/volumes")
        native = true if response.code.match(/^20.$/)
        return true, "volumes"
      rescue OpenStack::Exception::ItemNotFound => not_found
        native = false
      end
      #check if available as extension:
      begin
        response = @connection.req("GET", "/os-volumes")
        extension = true if response.code.match(/^20.$/)
        return false, "os-volumes"
      rescue OpenStack::Exception::ItemNotFound => not_found
        extension = false
      end
      raise OpenStack::Exception::NotImplemented.new("No Volumes support for this provider", 501, "No Volumes Support") unless (native || extension)
    end




  end

end
end
