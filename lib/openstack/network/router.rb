module OpenStack
module Network
  class Router

    attr_reader :id
    attr_reader :name
    attr_reader :admin_state_up
    attr_reader :status
    attr_reader :external_gateway_info
    attr_reader :tenant_ip
    attr_reader :enable_snat
    attr_reader :admin_state_up

    def initialize(router_info={})
      @name = router_info['name']
      @status = router_info['status']
      @external_geteway_info = router_info['external_gateway_info']
      @admin_state_up = router_info['admin_state_up']
      @tenant_ip = router_info['tenant_ip']
      @id = router_info['id']
      @enable_snat = router_info['enable_snat']
#      @admin_state_up = router_info['external_gateway_info']['admin_state_up']
#      @network_id = router_info['external_gateway_info']['network_id']
    end
  end
end
end
