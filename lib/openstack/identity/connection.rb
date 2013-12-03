module OpenStack
  module Identity
    class Connection
      def initialize(connection)
        @connection = connection
        OpenStack::Authentication.init(@connection)
      end

      def list_tenants
        response = @connection.req("GET", "/tenants", {:port => "35357"})
        tenants_hash = JSON.parse(response.body)["tenants"]
        tenants_hash.inject([]){|res, current| res << OpenStack::Identity::Tenant.new(current); res}
      end

      def create_tenant(options)
        req_body = JSON.generate({"tenant"=>{"name" => options[:name]}})
        response = @connection.req("POST", "/tenants", {:data => req_body, :port => "35357"})
        OpenStack::Identity::Tenant.new(JSON.parse(response.body)["tenant"])
      end

      def delete_tenant(id)
        @connection.req("DELETE", "/tenants/#{id}", {:port => "35357"})
        true
      end

      def list_users
        response = @connection.req("GET", "/users", {:port => "35357"})
        users_hash = JSON.parse(response.body)["users"]
        users_hash.inject([]){|res, current| res << OpenStack::Identity::User.new(current); res}
      end

      def create_user(options)
        req_body = JSON.generate({"user" => {"name" => options[:name], "password" => options[:password]}})
        response = @connection.req("POST", "/users", {:data => req_body, :port => "35357"})
        OpenStack::Identity::User.new(JSON.parse(response.body)["user"])
      end

      def delete_user(id)
        @connection.req("DELETE", "/users/#{id}", {:port => "35357"})
        true
      end

      def add_user_to_tenant(options)
        req_body = JSON.generate({"role"=>{"tenantId" => options[:tenant_id], "roleId" => options[:role_id]}})
        response = @connection.req("POST", "/users/#{options[:user_id]}/roleRefs", {:data => req_body, :port => "35357"})
        true
      end

      def list_roles
        response = @connection.req("GET", "/OS-KSADM/roles", {:port => "35357"})
        OpenStack.symbolize_keys(JSON.parse(response.body)["roles"])
      end     
    end
  end
end
