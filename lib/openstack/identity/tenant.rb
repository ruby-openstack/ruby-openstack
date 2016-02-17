module OpenStack
  module Identity
    class Tenant
      attr_reader :id
      attr_reader :name
      attr_reader :description
      attr_reader :enabled

      def initialize(tenant_info = {})
        @id = tenant_info['id']
        @name = tenant_info['name']
        @description = tenant_info['description']
        @enabled = tenant_info['enabled']
      end
    end
  end
end
