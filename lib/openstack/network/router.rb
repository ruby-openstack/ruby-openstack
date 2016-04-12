module OpenStack
module Network
  class Router

    attr_reader :id
    attr_reader :name
    attr_reader :admin_state_up
    attr_reader :status
    attr_reader :external_gateway_info
    attr_reader :tenant_id
    attr_reader :enable_snat
    attr_reader :admin_state_up

    def initialize(router_info={})
      @name = router_info['name']
      @status = router_info['status']
      @external_gateway_info = router_info['external_gateway_info']
      @admin_state_up = router_info['admin_state_up']
      @tenant_id = router_info['tenant_id']
      @id = router_info['id']
      @enable_snat = router_info['enable_snat']
    end
  end
end
end
