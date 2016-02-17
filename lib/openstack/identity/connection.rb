module OpenStack
  module Identity
    class Connection
      attr_accessor :connection

      def initialize(connection)
        @connection = connection
        OpenStack::Authentication.init(@connection)
      end

      def list_tenants
        response = @connection.req('GET', '/tenants')
        tenants_hash = JSON.parse(response.body)['tenants']
        tenants_hash.map { |res| OpenStack::Identity::Tenant.new(res) }
      end
      alias_method :tenants, :list_tenants

      # create_tenant(name: 'tenant1', description: 'description', enabled: true)
      #
      def create_tenant(options)
        req_body = JSON.generate('tenant' => options)
        response = @connection.req('POST', '/tenants', data: req_body)
        OpenStack::Identity::Tenant.new(JSON.parse(response.body)['tenant'])
      end

      def find_tenant_by_name(name)
        response = @connection.req('GET', "/tenants?name=#{name}")
        OpenStack::Identity::Tenant.new(JSON.parse(response.body)['tenant'])
      end

      def delete_tenant(id)
        @connection.req('DELETE', "/tenants/#{id}")
        true
      end

      def list_users
        response = @connection.req('GET', '/users')
        users_hash = JSON.parse(response.body)['users']
        users_hash.map { |res| OpenStack::Identity::User.new(res) }
      end
      alias_method :users, :list_users

      # create_user(name: 'user1', password: 'password1', email: 'email@mail.ru')
      #
      def create_user(options)
        req_body = JSON.generate('user' => options)
        response = @connection.req('POST', '/users', data: req_body)
        OpenStack::Identity::User.new(JSON.parse(response.body)['user'])
      end

      def delete_user(id)
        @connection.req('DELETE', "/users/#{id}")
        true
      end

      def add_user_to_tenant(options)
        req_body = JSON.generate('role' => { 'tenantId' => options[:tenant_id], 'roleId' => options[:role_id] })
        @connection.req('POST', "/users/#{options[:user_id]}/roleRefs", data: req_body)
        true
      end

      def list_roles
        response = @connection.req('GET', '/OS-KSADM/roles')
        OpenStack.symbolize_keys(JSON.parse(response.body)['roles'])
      end
      alias_method :roles, :list_roles
    end
  end
end
