module OpenStack
module Compute

  class Metadata

    def initialize(compute, parent_url, metadata=nil)
      @compute = compute
      @base_url = "#{parent_url}/metadata"
      @metadata = metadata
    end

    def [](key)
      refresh if @metadata.nil?
      @metadata[key]
    end

    def []=(key, value)
      @metadata = {} if @metadata.nil?
      @metadata[key] = value
    end

    def store(key, value)
      @metadata = {} if @metadata.nil?
      @metadata[key] = value
    end

    def each_pair
      @metadata = {} if @metadata.nil?
      @metadata.each_pair do |k,v|
          yield k, v
      end
    end

    def size
      @metadata = {} if @metadata.nil?
      @metadata.size
    end

    def each
      refresh if @metadata.nil?
      @metadata.each
    end

    def save
      return if @metadata.nil?
      json = JSON.generate(:metadata => @metadata)
      response = @compute.connection.req('PUT', @base_url, :data => json)
      @metadata = JSON.parse(response.body)['metadata']
    end

    def update(keys=nil)
      return if @metadata.nil?
      if keys.nil?
        json = JSON.generate(:metadata => @metadata)
        response = @compute.connection.req('POST', @base_url, :data => json)
        @metadata = JSON.parse(response.body)['metadata']
      else
        keys.each { |key|
          next if not @metadata.has_key?(key)
          json = JSON.generate(:meta => { key => @metadata[key] })
          @compute.connection.req('PUT', "#{@base_url}/#{key}", :data => json)
        }
      end
    end

    def refresh(keys=nil)
      if keys.nil?
        response = @compute.connection.req('GET', @base_url)
        @metadata = JSON.parse(response.body)['metadata']
      else
        @metadata = {} if @metadata == nil
        keys.each { |key|
          response = @compute.connection.req('GET', "#{@base_url}/#{key}")
          next if response.code == "404"
          meta = JSON.parse(response.body)['meta']
          meta.each { |k, v| @metadata[k] = v }
        }
      end
    end

    def delete(keys)
      return if @metadata.nil?
      keys.each { |key|
        @metadata.delete(key)
      }
    end

    def delete!(keys)
      keys.each { |key|
        @compute.connection.req('DELETE', "#{@base_url}/#{key}")
        @metadata.delete(key) if not @metadata.nil?
      }
    end

    def clear
      if @metadata.nil?
        @metadata = {}
      else
        @metadata.clear
      end
    end

    def clear!
      clear
      save
    end

    def has_key?(key)
      return False if @metadata.nil?
      return @metadata.has_key?(key)
    end

  end

end
end
