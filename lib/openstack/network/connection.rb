module OpenStack
module Network

  class Connection

    attr_accessor   :connection

    def initialize(connection)
      @connection = connection
      OpenStack::Authentication.init(@connection)
    end

    # Returns true if the authentication was successful and returns false otherwise.
    #
    #   cs.authok?
    #   => true
    def authok?
      @connection.authok
    end

    def list_networks
      response = @connection.req("GET", "/networks")
      nets_hash = JSON.parse(response.body)["networks"]
      nets_hash.inject([]){|res, current| res << OpenStack::Network::Network.new(current); res}
    end
    alias :networks :list_networks

    def get_network(network_id)
      response = @connection.req("GET", "/networks/#{network_id}")
      OpenStack::Network::Network.new(JSON.parse(response.body)["network"])
    end
    alias :network :get_network

    def create_network(name)
      req_body = JSON.generate({"network"=>{"name"=>name}})
      response = @connection.req("POST", "/networks", {:data=>req_body})
      OpenStack::Network::Network.new(JSON.parse(response.body)["network"])
    end

    def delete_network(id)
      @connection.req("DELETE", "/networks/#{id}")
      true
    end

    def list_subnets
      response = @connection.req("GET", "/subnets")
      nets_hash = JSON.parse(response.body)["subnets"]
      nets_hash.inject([]){|res, current| res << OpenStack::Network::Subnet.new(current); res}
    end
    alias :subnets :list_subnets

    def get_subnet(subnet_id)
      response = @connection.req("GET", "/subnets/#{subnet_id}")
      OpenStack::Network::Subnet.new(JSON.parse(response.body)["subnet"])
    end
    alias :subnet :get_subnet

    def create_subnet(network_id, cidr, ip_version="4", opts={})
      body_hash = {"subnet"=>{"network_id"=> network_id, "cidr"=>cidr, "ip_version"=>ip_version}}
      body_hash["subnet"].merge!(opts) #fixme - validation?
      req_body = JSON.generate(body_hash)
      response = @connection.req("POST", "/subnets", {:data=>req_body})
      OpenStack::Network::Subnet.new(JSON.parse(response.body)["subnet"])
    end

    def delete_subnet(id)
      @connection.req("DELETE", "/subnets/#{id}")
      true
    end

    def list_ports
      response = @connection.req("GET", "/ports")
      ports_hash = JSON.parse(response.body)["ports"]
      ports_hash.inject([]){|res, current| res << OpenStack::Network::Port.new(current); res}
    end
    alias :ports :list_ports

    def get_port(port_id)
      response = @connection.req("GET", "/ports/#{port_id}")
      OpenStack::Network::Port.new(JSON.parse(response.body)["port"])
    end
    alias :port :get_port

    def create_port(network_id, opts={})
      body_hash = {"port"=>{"network_id"=> network_id}}
      body_hash["port"].merge!(opts) #fixme - validation?
      req_body = JSON.generate(body_hash)
      response = @connection.req("POST", "/ports", {:data=>req_body})
      OpenStack::Network::Port.new(JSON.parse(response.body)["port"])
    end

    def delete_port(id)
      @connection.req("DELETE", "/ports/#{id}")
      true
    end

  end

end
end
