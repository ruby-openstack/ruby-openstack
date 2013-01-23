module OpenStack
  module Volume
    class Snapshot

      attr_reader :id
      attr_reader :display_name
      attr_reader :display_description
      attr_reader :volume_id
      attr_reader :status
      attr_reader :size
      attr_reader :created_at

      def initialize(snap_info)
        @id = snap_info["id"]
        @display_name = snap_info["display_name"] || snap_info["displayName"]
        @display_description = snap_info["display_description"] || snap_info["displayDescription"]
        @volume_id = snap_info["volume_id"] || snap_info["volumeId"]
        @status = snap_info["status"]
        @size  = snap_info["size"]
        @created_at = snap_info["created_at"] || snap_info["createdAt"]
      end

    end
  end
end
