module OpenStack
  module Identity
    module ConnectionV3
      def list_tenants
        response = @connection.req('GET', '/projects')
        tenants_hash = JSON.parse(response.body)['projects']
        tenants_hash.map { |res| OpenStack::Identity::Tenant.new(res) }
      end
      alias_method :tenants, :list_tenants

      # create_tenant(name: 'tenant1', description: 'description', enabled: true)
      #
      def create_tenant(options)
        options.merge!(domain_id: @connection.domain_id)
        req_body = JSON.generate('project' => options)
        response = @connection.req('POST', '/projects', data: req_body)
        OpenStack::Identity::Tenant.new(JSON.parse(response.body)['project'])
      end

      def find_tenant_by_name(name)
        response = @connection.req('GET', "/projects?name=#{name}")
        OpenStack::Identity::Tenant.new(JSON.parse(response.body)['project'])
      end

      def delete_tenant(id)
        @connection.req('DELETE', "/projects/#{id}")
        true
      end

      # create_user(name: 'user1', password: 'password1', email: 'email@mail.ru')
      #
      def create_user(options)
        options.merge!(domain_id: @connection.domain_id)
        req_body = JSON.generate('user' => options)
        response = @connection.req('POST', '/users', data: req_body)
        OpenStack::Identity::User.new(JSON.parse(response.body)['user'])
      end

      # update_user(1, {name: 'user1', password: 'password1', email: 'email@mail.ru'})
      def update_user(user_id, options)
        req_body = JSON.generate('user' => options)
        response = @connection.req('PATCH', "/users/#{user_id}", data: req_body)
        OpenStack::Identity::User.new(JSON.parse(response.body)['user'])
      end

      def add_user_to_tenant(options)
        @connection.req('PUT', "/projects/#{options[:tenant_id]}/users/#{options[:user_id]}/roles/#{options[:role_id]}")
        true
      end

      def list_roles
        response = @connection.req('GET', '/roles')
        OpenStack.symbolize_keys(JSON.parse(response.body)['roles'])
      end
      alias_method :roles, :list_roles
    end
  end
end
