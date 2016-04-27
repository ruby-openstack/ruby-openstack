require File.dirname(__FILE__) + '/../test_helper'

class ImagesTest < Test::Unit::TestCase
  include TestConnection

  def setup
    @comp = get_test_connection
  end

  def test_list_images
    json_response = %{{
      "images": [
        {
            "OS-EXT-IMG-SIZE:size": "74185822",
            "created": "2011-01-01T01:02:03Z",
            "id": "70a599e0-31e7-49b7-b260-868f441e862b",
            "links": [
                {
                    "href": "http://openstack.example.com/v2.1/images/70a599e0-31e7-49b7-b260-868f441e862b",
                    "rel": "self"
                },
                {
                    "href": "http://openstack.example.com/images/70a599e0-31e7-49b7-b260-868f441e862b",
                    "rel": "bookmark"
                },
                {
                    "href": "http://glance.openstack.example.com/images/70a599e0-31e7-49b7-b260-868f441e862b",
                    "rel": "alternate",
                    "type": "application/vnd.openstack.image"
                }
            ],
            "metadata": {
                "architecture": "x86_64",
                "auto_disk_config": "True",
                "kernel_id": "nokernel",
                "ramdisk_id": "nokernel"
            },
            "minDisk": 0,
            "minRam": 0,
            "name": "fakeimage7",
            "progress": 100,
            "status": "ACTIVE",
            "updated": "2011-01-01T01:02:03Z"
        }
      ]
    }}
    response = mock()
    response.stubs(:code => "200", :body => json_response)
    @comp.connection.stubs(:csreq).returns(response)
    images = @comp.list_images(name: "fakeimage7")
    assert_equal images[0][:minDisk], 0
    assert_equal images[0][:minRam], 0
    assert_equal images[0][:name], 'fakeimage7'
    assert_equal images[0][:progress], 100
    assert_equal images[0][:status], 'ACTIVE'
    assert_equal images[0][:updated], '2011-01-01T01:02:03Z'
  end

end
