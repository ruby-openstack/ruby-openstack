#!/usr/bin/env ruby

BASEPATH = File.dirname(__FILE__)

require BASEPATH + '/test_helper.rb'

Dir.glob('./unit/*_test.rb').each do |file|
  puts "Load #{file} ..."
  require BASEPATH + '/' + file
end
