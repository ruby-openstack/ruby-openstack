# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "openstack"
  s.version = "1.0.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dan Prince", "Marios Andreou"]
  s.date = "2013-01-23"
  s.description = "API Binding for OpenStack"
  s.email = ["dprince@redhat.com", "marios@redhat.com"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "COPYING",
    "README.rdoc",
    "VERSION",
    "lib/openstack.rb",
    "lib/openstack/compute/address.rb",
    "lib/openstack/compute/connection.rb",
    "lib/openstack/compute/flavor.rb",
    "lib/openstack/compute/image.rb",
    "lib/openstack/compute/metadata.rb",
    "lib/openstack/compute/personalities.rb",
    "lib/openstack/compute/server.rb",
    "lib/openstack/connection.rb",
    "lib/openstack/image/connection.rb",
    "lib/openstack/swift/connection.rb",
    "lib/openstack/swift/container.rb",
    "lib/openstack/swift/storage_object.rb",
    "lib/openstack/volume/connection.rb",
    "lib/openstack/volume/snapshot.rb",
    "lib/openstack/volume/volume.rb",
    "test/authentication_test.rb",
    "test/connection_test.rb",
    "test/exception_test.rb",
    "test/metadata_test.rb",
    "test/servers_test.rb",
    "test/test_helper.rb"
  ]
  s.homepage = "https://github.com/ruby-openstack/ruby-openstack"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "OpenStack Ruby API"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<test-unit>, [">= 0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
    else
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<test-unit>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
    end
  else
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<test-unit>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
  end
end

