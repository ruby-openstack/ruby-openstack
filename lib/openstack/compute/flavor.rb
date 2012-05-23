module OpenStack
module Compute
  class Flavor

    attr_reader :id
    attr_reader :name
    attr_reader :ram
    attr_reader :disk
    attr_reader :vcpus

    # This class provides an object for the "Flavor" of a server.  The Flavor can generally be taken as the server specification,
    # providing information on things like memory and disk space.
    #
    # The disk attribute is an integer representing the disk space in GB.  The memory attribute is an integer representing the RAM in MB.
    #
    # This is called from the get_flavor method on a OpenStack::Compute::Connection object, returns a OpenStack::Compute::Flavor object, and will likely not be called directly.
    #
    #   >> flavor = cs.get_flavor(1)
    #   => #<OpenStack::Compute::Flavor:0x1014f8bc8 @name="256 server", @disk=10, @id=1, @ram=256>
    #   >> flavor.name
    #   => "256 server"
    def initialize(compute,id)
      response = compute.connection.csreq("GET",compute.connection.service_host,"#{compute.connection.service_path}/flavors/#{URI.escape(id.to_s)}",compute.connection.service_port,compute.connection.service_scheme)
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      data = JSON.parse(response.body)['flavor']
      @id   = data['id']
      @name = data['name']
      @ram  = data['ram']
      @disk = data['disk']
      @vcpus = data['vcpus']
    end

  end
end
end
