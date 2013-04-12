module OpenStack
module Network
  class Network

  attr_reader :id
  attr_reader :name
  attr_reader :admin_state_up
  attr_reader :status
  attr_reader :subnets
  attr_reader :shared
  attr_reader :tenant_id

  def initialize(net_info={})
    @id = net_info["id"]
    @name = net_info["name"]
    @admin_state_up = net_info["admin_state_up"]
    @status = net_info["status"]
    @subnets = net_info["subnets"]
    @shared = net_info["shared"]
    @tenant_id = net_info["tenant_id"]
  end

  end
end
end

