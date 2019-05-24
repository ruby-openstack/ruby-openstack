module OpenStack
  module Network
    class Port

      attr_reader :id
      attr_reader :network_id
      attr_reader :name
      attr_reader :admin_state_up
      attr_reader :status
      attr_reader :mac_address
      attr_reader :fixed_ips
      attr_reader :device_id
      attr_reader :device_owner
      attr_reader :tenant_id
      attr_reader :qos_policy_id
      attr_reader :allowed_address_pairs
      attr_reader :updated_at

      def initialize(port_hash={})
        @id = port_hash["id"]
        @network_id = port_hash["network_id"]
        @name = port_hash["name"]
        @admin_state_up = port_hash["admin_state_up"]
        @status = port_hash["status"]
        @mac_address = port_hash["mac_address"]
        @fixed_ips = port_hash["fixed_ips"]
        @device_id = port_hash["device_id"]
        @device_owner = port_hash["device_owner"]
        @tenant_id = port_hash["tenant_id"]
        @qos_policy_id = port_hash["qos_policy_id"]
        @allowed_address_pairs = port_hash["allowed_address_pairs"]
        @updated_at = port_hash["updated_at"]
      end

    end
  end
end
