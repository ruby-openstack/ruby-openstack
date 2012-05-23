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
  end

end
end
