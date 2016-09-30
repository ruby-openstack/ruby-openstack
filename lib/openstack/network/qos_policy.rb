module OpenStack
module Network
  class QoSPolicy

    attr_reader :connection
    attr_reader :tenant_id
    attr_reader :id
    attr_reader :name
    attr_reader :description
    attr_reader :shared

    def initialize(connection, qos_hash={})
      @connection = connection
      populate(qos_hash)
    end

    def populate(qos_hash=nil)
      if @id and not qos_hash
        response = @connection.req("GET", "/qos/policies/#{@id}")
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
        qos_hash = JSON.parse(response.body)["policy"]
      end

      @id = qos_hash["id"]
      @tenant_id = qos_hash["tenant_id"]
      @name = qos_hash["name"]
      @description = qos_hash["description"]
      @shared = qos_hash["shared"]
    end

    def delete!
      response = @connection.req('DELETE', "/qos/policies/#{@id}")
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      true
    end

    def update(options)
      data = JSON.generate(:policy => options)
      response = @connection.req("PUT", "/qos/policies/#{@id}", {:data => data})
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      populate(JSON.parse(response.body)["policy"])
    end

    def get_bandwidth_limit_rules
      response = @connection.req("GET", "/qos/policies/#{@id}/bandwidth_limit_rules")
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      rules_hash = JSON.parse(response.body)["bandwidth_limit_rules"]
      rules_hash.inject([]){|res, current| res << OpenStack::Network::QoSBandwidthLimitRule.new(self, current); res}
    end

    def get_bandwidth_limit_rule(rule_id)
      response = @connection.req("GET", "/qos/policies/#{@id}/bandwidth_limit_rules/#{rule_id}")
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      OpenStack::Network::QoSBandwidthLimitRule.new(self, JSON.parse(response.body)["bandwidth_limit_rule"])
    end

    def create_bandwidth_limit_rule(options)
      data = JSON.generate(:bandwidth_limit_rule => options)
      response = @connection.req("POST", "/qos/policies/#{@id}/bandwidth_limit_rules", {:data => data})
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      OpenStack::Network::QoSBandwidthLimitRule.new(self, JSON.parse(response.body)["bandwidth_limit_rule"])
    end

    def add_port_id(port_id)
        data = JSON.generate(:port => {:qos_policy_id => @id})
        response = @connection.req("PUT", "/ports/#{port_id}", {:data => data})
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
        true
    end

    def remove_port_id(port_id)
      data = JSON.generate(:port => {:qos_policy_id => nil})
      response = @connection.req("PUT", "/ports/#{port_id}", {:data => data})
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      true
    end

  end
end
end
