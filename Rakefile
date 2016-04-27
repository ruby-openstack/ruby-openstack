require 'rubygems'
require './lib/openstack.rb'
require 'rake/testtask'

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gemspec|
    gemspec.name = 'openstack'
    gemspec.summary = 'OpenStack Ruby API'
    gemspec.description = 'API Bindings for OpenStack.'
    gemspec.homepage = 'https://github.com/ruby-openstack/ruby-openstack'

    gemspec.email = [
      'dprince@redhat.com',
      'marios@redhat.com',
      'naveedm9@gmail.com',
      'aaron.fischer@marbis.net',
      'alexander.birkner@marbis.net'
    ]
    gemspec.authors = [
      'Dan Prince',
      'Marios Andreou',
      'Naveed Massjouni',
      'Aaron Fischer',
      'Alexander Birkner'
    ]

    gemspec.add_dependency 'json'

    gemspec.files = Dir.glob('lib/**/*.rb')
    gemspec.files << 'README.rdoc'
    gemspec.files << 'VERSION'
    gemspec.files << 'COPYING'
    (gemspec.files << Dir.glob('test/*.rb')).flatten!
  end
rescue LoadError
  puts 'Jeweler not available. Install it with: sudo gem install jeweler'
end

Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/unit/*_test.rb'
  t.verbose = true
end

Rake::Task['test'].comment = 'Unit'
