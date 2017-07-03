module OpenStack
  module Compute
    class Flavor
      attr_reader :id
      attr_reader :name
      attr_reader :ram
      attr_reader :disk
      attr_reader :vcpus
      attr_reader :disabled

      # This class provides an object for the "Flavor" of a server.  The Flavor can generally be taken as the server specification,
      # providing information on things like memory and disk space.
      #
      # The disk attribute is an integer representing the disk space in GB.  The memory attribute is an integer representing the RAM in MB.
      def initialize(flavor_info = {})
        @id = flavor_info['id']
        @name = flavor_info['name']
        @ram = flavor_info['ram']
        @disk = flavor_info['disk']
        @vcpus = flavor_info['vcpus']
        @disabled = flavor_info['OS-FLV-DISABLED:disabled']
       end
    end
  end
end
