module OpenStack
module Network
  class QoSBandwidthLimitRule

    attr_reader :id
    attr_reader :policy_id
    attr_reader :max_kbps
    attr_reader :max_burst_kbps

    def initialize(policy, rule_hash={})
      @policy = policy
      populate(rule_hash)
    end

    def populate(rule_hash=nil)
      if @id and not rule_hash
        response = @policy.connection.req("GET", "/qos/policies/#{@policy_id}/bandwidth_limit_rules/#{@id}")
        OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
        rule_hash = JSON.parse(response.body)["bandwidth_limit_rule"]
      end

      @id = rule_hash["id"]
      @policy_id = rule_hash["policy_id"] || @policy.id
      @max_kbps = rule_hash["max_kbps"]
      @max_burst_kbps = rule_hash["max_burst_kbps"]
    end

    def delete!
      response = @policy.connection.req('DELETE', "/qos/policies/#{@policy_id}/bandwidth_limit_rules/#{@id}")
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      true
    end

    def update(options)
      data = JSON.generate(:bandwidth_limit_rule => options)
      response = @policy.connection.req("PUT", "/qos/policies/#{@policy_id}/bandwidth_limit_rules/#{@id}", {:data => data})
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      populate(JSON.parse(response.body)["bandwidth_limit_rule"])
      true
    end

  end
end
end
