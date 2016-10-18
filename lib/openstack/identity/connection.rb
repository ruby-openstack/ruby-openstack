require 'openstack/identity/connection_v2'
require 'openstack/identity/connection_v3'

module OpenStack
  module Identity
    class Connection
      attr_accessor :connection

      def initialize(connection)
        @connection = connection
        OpenStack::Authentication.init(@connection)
        extend @connection.auth_path.match(/v3/) ? OpenStack::Identity::ConnectionV3 : OpenStack::Identity::ConnectionV2
      end

      def list_users
        response = @connection.req('GET', '/users')
        users_hash = JSON.parse(response.body)['users']
        users_hash.map { |res| OpenStack::Identity::User.new(res) }
      end
      alias_method :users, :list_users

      def delete_user(id)
        @connection.req('DELETE', "/users/#{id}")
        true
      end
    end
  end
end
