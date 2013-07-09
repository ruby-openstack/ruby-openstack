module OpenStack
  module Volume
    class Volume

    attr_reader :id
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

    def initialize(volume_info)
      @id  = volume_info["id"]
      @display_name  = volume_info["display_name"] || volume_info["displayName"]
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

    end
  end
end
