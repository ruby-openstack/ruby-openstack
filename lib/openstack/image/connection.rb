module OpenStack
module Image

  class Connection

    attr_accessor   :connection

    def initialize(connection)
      @connection = connection
      OpenStack::Authentication.init(@connection)
    end

    # Returns true if the authentication was successful and returns false otherwise.
    #
    #   cs.authok?
    #   => true
    def authok?
      @connection.authok
    end

    def list_images(options = {})
      path = options.empty? ? "/images" : "/images?#{options.to_query}"
      response = @connection.req("GET", path)
      nets_hash = JSON.parse(response.body)["images"]
      nets_hash.inject([]){|res, current| res << OpenStack::Image::Image.new(current); res}
    end
    alias :images :list_images

    def get_image(image_id)
      response = @connection.req("GET", "/images/#{image_id}")
      OpenStack::Image::Image.new(JSON.parse(response.body)["image"])
    end
    alias :image :get_image

    def delete_image(image_id)
      @connection.req("DELETE", "/images/#{image_id}")
      true
    end

  end

end
end
