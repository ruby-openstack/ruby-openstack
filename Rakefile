require 'rubygems'
require './lib/openstack.rb'
require 'rake/testtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "openstack"
    gemspec.summary = "OpenStack Ruby API"
    gemspec.description = "API Binding for OpenStack"
    gemspec.email = ["dprince@redhat.com","marios@redhat.com"]
    gemspec.homepage = "https://github.com/ruby-openstack/ruby-openstack"
    gemspec.authors = ["Dan Prince", "Marios Andreou"]
    gemspec.add_dependency 'json'
    gemspec.files = Dir.glob('lib/**/*.rb')
    gemspec.files << "README.rdoc"
    gemspec.files << "VERSION"
    gemspec.files << "COPYING"
    (gemspec.files << Dir.glob("test/*.rb")).flatten!
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end

  Rake::TestTask.new(:test) do |t|
    t.pattern = 'test/*_test.rb'
    t.verbose = true
  end
  Rake::Task['test'].comment = "Unit"
