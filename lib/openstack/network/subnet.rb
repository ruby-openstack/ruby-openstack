module OpenStack
module Network
  class Subnet

    attr_reader :id
    attr_reader :network_id
    attr_reader :name
    attr_reader :ip_version
    attr_reader :cidr
    attr_reader :gateway_ip
    attr_reader :dns_nameservers
    attr_reader :allocation_pools
    attr_reader :host_routes
    attr_reader :enable_dhcp
    attr_reader :tenant_id

    def initialize(subnet_hash)
      @id = subnet_hash["id"]
      @network_id = subnet_hash["network_id"]
      @name = subnet_hash["name"]
      @ip_version = subnet_hash["ip_version"]
      @cidr = subnet_hash["cidr"]
      @gateway_ip = subnet_hash["gateway_ip"]
      @dns_nameservers = subnet_hash["dns_nameservers"]
      @allocation_pools = subnet_hash["allocation_pools"]
      @host_routes = subnet_hash["host_routes"]
      @enable_dhcp = subnet_hash["enable_dhcp"]
      @tenant_id = subnet_hash["tenant_id"]
    end

  end
end
end
