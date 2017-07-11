module OpenStack
  module Image
    class Image
      attr_reader :id
      attr_reader :name
      attr_reader :updated
      attr_reader :created
      attr_reader :status
      attr_reader :min_disk
      attr_reader :min_ram
      attr_reader :visibility
      attr_reader :tags
      attr_reader :size

      def initialize(net_info = {})
        @id = net_info['id']
        @name = net_info['name']
        @updated = net_info['updated_at']
        @created = net_info['created_at']
        @status = net_info['status']
        @min_disk = net_info['min_disk']
        @min_ram = net_info['min_ram']
        @visibility = net_info['visibility']
        @tags = net_info['tags']
        @size = net_info['size']
      end
    end
  end
end