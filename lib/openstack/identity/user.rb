module OpenStack
  module Identity
    class User
      attr_reader :id
      attr_reader :name
      attr_reader :tenant_id
      attr_reader :enabled
      attr_reader :email

      def initialize(tenant_info = {})
        @id = tenant_info['id']
        @name = tenant_info['name']
        @tenant_id = tenant_info['tenant_id']
        @email = tenant_info['email']
        @enabled = tenant_info['enabled']
      end
    end
  end
end
