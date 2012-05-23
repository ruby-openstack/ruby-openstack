module OpenStack
module Compute
  class Image

    require 'openstack/compute/metadata'

    attr_reader :id
    attr_reader :name
    attr_reader :server
    attr_reader :updated
    attr_reader :created
    attr_reader :status
    attr_reader :minDisk
    attr_reader :minRam
    attr_reader :progress
    attr_reader :metadata

    # This class provides an object for the "Image" of a server.  The Image refers to the Operating System type and version.
    #
    # Returns the Image object identifed by the supplied ID number.  Called from the get_image instance method of OpenStack::Compute::Connection,
    # it will likely not be called directly from user code.
    #
    #   >> cs = OpenStack::Compute::Connection.new(USERNAME,API_KEY)
    #   >> image = cs.get_image(2)
    #   => #<OpenStack::Compute::Image:0x1015371c0 ...>
    #   >> image.name
    #   => "CentOS 5.2"
    def initialize(compute,id)
      @id = id
      @compute = compute
      populate
    end

    # Makes the HTTP call to load information about the provided image.  Can also be called directly on the Image object to refresh data.
    # Returns true if the refresh call succeeds.
    #
    #   >> image.populate
    #   => true
    def populate
      path = "/images/#{URI.escape(self.id.to_s)}"
      response = @compute.connection.req("GET", path)
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      data = JSON.parse(response.body)['image']
      @id = data['id']
      @name = data['name']
      @server = data['server']
      if data['updated'] then
         @updated = DateTime.parse(data['updated'])
      end
      @created = DateTime.parse(data['created'])
      @metadata = OpenStack::Compute::Metadata.new(@compute, path, data['metadata'])
      @status = data['status']
      @minDisk = data['minDisk']
      @minRam = data['minRam']
      @progress = data['progress']
      return true
    end
    alias :refresh :populate

    # Delete an image.  This should be returning invalid permissions when attempting to delete system images, but it's not.
    # Returns true if the deletion succeeds.
    #
    #   >> image.delete!
    #   => true
    def delete!
      response = @compute.connection.csreq("DELETE",@compute.connection.service_host,"#{@compute.connection.service_path}/images/#{URI.escape(self.id.to_s)}",@compute.connection.service_port,@compute.connection.service_scheme)
      OpenStack::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      true
    end

  end
end
end
