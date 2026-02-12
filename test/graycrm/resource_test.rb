# frozen_string_literal: true

require "test_helper"

class GrayCRM::ResourceTest < Minitest::Test
  include FakeServer

  def test_find_returns_resource
    stub_api(:get, "/contacts/abc", body: {
      data: { id: "abc", first_name: "Jane", last_name: "Doe" }
    })

    contact = GrayCRM::Contact.find("abc")
    assert_equal "abc", contact.id
    assert_equal "Jane", contact.first_name
    assert_equal "Doe", contact.last_name
  end

  def test_create_posts_and_returns_resource
    stub_api(:post, "/contacts", status: 201, body: {
      data: { id: "new-1", first_name: "John", source: "api" }
    })

    contact = GrayCRM::Contact.create(first_name: "John")
    assert_equal "new-1", contact.id
    assert_equal "John", contact.first_name
    assert contact.persisted?
  end

  def test_update_patches_resource
    stub_api(:get, "/contacts/abc", body: {
      data: { id: "abc", first_name: "Jane" }
    })
    stub_api(:patch, "/contacts/abc", body: {
      data: { id: "abc", first_name: "Janet" }
    })

    contact = GrayCRM::Contact.find("abc")
    contact.update(first_name: "Janet")
    assert_equal "Janet", contact.first_name
  end

  def test_destroy_deletes_resource
    stub_api(:get, "/contacts/abc", body: { data: { id: "abc" } })
    stub_request(:delete, "https://acme.graycrm.io/api/v1/contacts/abc")
      .to_return(status: 204, body: "")

    contact = GrayCRM::Contact.find("abc")
    assert contact.destroy
  end

  def test_new_record_detection
    contact = GrayCRM::Contact.new(first_name: "Draft")
    assert contact.new_record?
    refute contact.persisted?

    contact = GrayCRM::Contact.new("id" => "abc")
    refute contact.new_record?
    assert contact.persisted?
  end

  def test_to_h
    contact = GrayCRM::Contact.new("id" => "abc", "first_name" => "Jane")
    hash = contact.to_h
    assert_equal "abc", hash["id"]
    assert_equal "Jane", hash["first_name"]
  end

  def test_inspect
    contact = GrayCRM::Contact.new("id" => "abc", "first_name" => "Jane")
    assert_match(/GrayCRM::Contact/, contact.inspect)
    assert_match(/abc/, contact.inspect)
  end

  def test_reload
    stub_api(:get, "/contacts/abc", body: {
      data: { id: "abc", first_name: "Jane", last_name: "Updated" }
    })

    contact = GrayCRM::Contact.new("id" => "abc", "first_name" => "Jane", "last_name" => "Old")
    contact.reload
    assert_equal "Updated", contact.last_name
  end
end
