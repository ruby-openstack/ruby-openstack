module OpenStack
module Compute
  class Host

    attr_reader :host_name
    attr_reader :service
    attr_reader :zone

    def initialize(details_hash)
      @host_name = details_hash["host_name"]
      @service = details_hash["service"]
      @zone = details_hash["zone"]
    end

  end
end
end
