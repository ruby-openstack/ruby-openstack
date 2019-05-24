#!/usr/bin/env ruby

module OpenStack
  require 'net/http'
  require 'net/https'
  require 'uri'
  require 'rubygems'
  require 'json'
  require 'date'
  require 'securerandom'
  require 'logger'
  require 'thread'

  unless "".respond_to? :each_char
    require "jcode"
    $KCODE = 'u'
  end

  $:.unshift(File.dirname(__FILE__))
  require 'openstack/connection'
  require 'openstack/metering/connection'
  require 'openstack/compute/connection'
  require 'openstack/compute/server'
  require 'openstack/compute/image'
  require 'openstack/compute/flavor'
  require 'openstack/compute/address'
  require 'openstack/compute/personalities'
  require 'openstack/swift/connection'
  require 'openstack/swift/container'
  require 'openstack/swift/storage_object'
  require 'openstack/volume/connection'
  require 'openstack/volume/volume'
  require 'openstack/volume/snapshot'
  require 'openstack/image/connection'
  require 'openstack/network/connection'
  require 'openstack/network/network'
  require 'openstack/network/subnet'
  require 'openstack/network/router'
  require 'openstack/network/port'
  require 'openstack/network/qos_policy'
  require 'openstack/network/qos_bandwidth_limit_rule'
  require 'openstack/identity/connection'
  require 'openstack/identity/tenant'
  require 'openstack/identity/user'
  require 'openstack/core_ext/to_query'

  # Constants that set limits on server creation
  MAX_PERSONALITY_ITEMS = 5
  MAX_PERSONALITY_FILE_SIZE = 10240
  MAX_SERVER_PATH_LENGTH = 255

  # Helper method to recursively symbolize hash keys.
  def self.symbolize_keys(obj)
    case obj
    when Array
      obj.inject([]){|res, val|
        res << case val
        when Hash, Array
          symbolize_keys(val)
        else
          val
        end
        res
      }
    when Hash
      obj.inject({}){|res, (key, val)|
        nkey = case key
        when String
          key.to_sym
        else
          key
        end
        nval = case val
        when Hash, Array
          symbolize_keys(val)
        else
          val
        end
        res[nkey] = nval
        res
      }
    else
      obj
    end
  end

  def self.paginate(options = {})
    path_args = []
    path_args.push(URI.encode("limit=#{options[:limit]}")) if options[:limit]
    path_args.push(URI.encode("offset=#{options[:offset]}")) if options[:offset]
    path_args.join("&")
  end

  # e.g. keys = [:limit, :marker]
  # params = {:limit=>2, :marker="marios", :prefix=>"/"}
  # you want url = /container_name?limit=2&marker=marios
  def self.get_query_params(params, keys, url="")
    set_keys = params.inject([]){|res, (k,v)| res << k if keys.include?(k) and not v.nil?; res }
    return url if set_keys.empty?
    url = "#{url}?#{set_keys[0]}=#{params[set_keys[0]]}"
    set_keys.slice!(0)
    set_keys.each do |k|
      url = "#{url}&#{k}=#{params[set_keys[0]]}"
    end
    url
  end
end
