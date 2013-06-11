require 'ipaddr'
module OpenStack
module Compute

  class AddressList < Array
    def [](index)
      addresses = Array.new
      if index.class == Symbol then
        self.each do |address|
          if address.label == index.to_s then
            addresses << address
          end
        end
        addresses
      else
        super
      end
    end
  end

  class Address

    attr_reader :address
    attr_reader :label
    attr_reader :version

    def initialize(label, address, version = 4)
      @label = label
      if address.class == Hash then
        @address = address["addr"]
        @version = address["version"]
      else
        @address = address
        @version = version
      end
    end

    NON_ROUTABLE_ADDRESSES = [IPAddr.new("10.0.0.0/8"), IPAddr.new("192.168.0.0/16"), IPAddr.new("172.16.0.0/12")]

    def self.is_private?(address_string)
      NON_ROUTABLE_ADDRESSES.each do |no_route|
        return true if no_route.include?(address_string)
      end
      false
    end

    #IN:  { "private"=> [{"addr"=>"10.7.206.171", "version"=>4}, {"addr"=>"15.185.160.208", "version"=>4}]}
    #OUT: { "private"=> [{"addr"=>"10.7.206.171", "version"=>4}],
    #       "public"=>  [{"addr"=>"15.185.160.208", "version"=>4}] }
    def self.fix_labels(addresses_info)
      addresses_info.inject({"public"=>[], "private"=>[]}) do |res, (label,address_struct_list)|
        address_struct_list.each do |address_struct|
          if(address_struct["version"==6])#v6 addresses are all routable...
            res["public"] << address_struct
          else
            is_private?(address_struct["addr"])? res["private"] << address_struct : res["public"] << address_struct
          end
        end
        res
      end
    end

  end

  class FloatingIPAddress

    attr_reader :fixed_ip
    attr_reader :id
    attr_reader :instance_id
    attr_reader :ip
    attr_reader :pool

    def initialize(addr_hash)
      @fixed_ip = addr_hash["fixed_ip"]
      @id = addr_hash["id"]
      @instance_id = addr_hash["instance_id"]
      @ip = addr_hash["ip"]
      @pool = addr_hash["pool"]
    end


  end

end
end
