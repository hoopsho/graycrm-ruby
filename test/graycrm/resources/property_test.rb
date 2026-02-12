# frozen_string_literal: true

require "test_helper"

class GrayCRM::PropertyTest < Minitest::Test
  include FakeServer

  def test_find
    stub_api(:get, "/properties/p1", body: {
      data: { id: "p1", name: "123 Main St", city: "Springfield" }
    })

    prop = GrayCRM::Property.find("p1")
    assert_equal "p1", prop.id
    assert_equal "123 Main St", prop.name
    assert_equal "Springfield", prop.city
  end

  def test_create
    stub_api(:post, "/properties", status: 201, body: {
      data: { id: "p2", name: "456 Oak Ave", source: "api" }
    })

    prop = GrayCRM::Property.create(name: "456 Oak Ave")
    assert_equal "p2", prop.id
  end

  def test_nested_tags
    stub_api(:get, "/properties/p1/taggings", body: {
      data: [{ id: "t1", name: "commercial" }],
      pagination: {}
    })

    prop = GrayCRM::Property.new("id" => "p1")
    tags = prop.tags.to_a
    assert_equal 1, tags.size
  end
end
