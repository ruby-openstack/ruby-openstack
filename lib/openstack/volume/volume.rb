module OpenStack
  module Volume
    class Volume

    attr_reader :id
    attr_reader :connection
    attr_reader :display_name
    attr_reader :display_description
    attr_reader :size
    attr_reader :volume_type
    attr_reader :metadata
    attr_reader :availability_zone
    attr_reader :snapshot_id
    attr_reader :attachments
    attr_reader :created_at
    attr_reader :status

    def initialize(connection, volume_info)
      @connection = connection.connection
      @volume_path = connection.volume_path
      self.populate(volume_info)
    end

    def populate(volume_info = nil)
      if not volume_info and @id
        response = @connection.req("GET", "/#{@volume_path}/#{@id}")
        volume_info = JSON.parse(response.body)["volume"]
      end

      @id  = volume_info["id"]
      @display_name  = volume_info["display_name"] || volume_info["displayName"] || volume_info["name"]
      @display_description  = volume_info["display_description"] || volume_info["displayDescription"]
      @size  = volume_info["size"]
      @volume_type  = volume_info["volume_type"] || volume_info["volumeType"]
      @metadata  = volume_info["metadata"]
      @availability_zone  = volume_info["availability_zone"] || volume_info["availabilityZone"]
      @snapshot_id  = volume_info["snapshot_id"] || volume_info["snapshotId"]
      @attachments  = volume_info["attachments"]
      @created_at  = volume_info["created_at"] || volume_info["createdAt"]
      @status = volume_info["status"]
    end

    def extend!(size)
      data = JSON.generate({'os-extend' => {'new_size' => size}})
      response = @connection.req('POST', "/#{@volume_path}/#{@id}/action", {:data => data})
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      self.populate
      true
    end

    def status!(status)
      data = JSON.generate({'os-reset_status' => {'status' => status}})
      response = @connection.req('POST', "/#{@volume_path}/#{@id}/action", {:data => data})
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      self.populate
      true
    end

    def delete!
      response = @connection.req("DELETE", "/#{@volume_path}/#{@id}")
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      true
    end

    end
  end
end
