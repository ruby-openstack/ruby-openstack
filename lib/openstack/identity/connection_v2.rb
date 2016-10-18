module OpenStack
  module Identity
    module ConnectionV2
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

      # create_user(name: 'user1', password: 'password1', email: 'email@mail.ru')
      #
      def create_user(options)
        req_body = JSON.generate('user' => options)
        response = @connection.req('POST', '/users', data: req_body)
        OpenStack::Identity::User.new(JSON.parse(response.body)['user'])
      end

      # update_user(1, {name: 'user1', password: 'password1', email: 'email@mail.ru'})
      def update_user(user_id, options)
        req_body = JSON.generate('user' => options)
        response = @connection.req('PUT', "/users/#{user_id}", data: req_body)
        OpenStack::Identity::User.new(JSON.parse(response.body)['user'])
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
