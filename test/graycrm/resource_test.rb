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

  def test_create_returns_nil_on_validation_error
    stub_api(:post, "/contacts", status: 422, body: {
      error: { code: "validation_failed", message: "Invalid", details: { first_name: ["can't be blank"] } }
    })

    result = GrayCRM::Contact.create(first_name: "")
    assert_nil result
  end

  def test_create_bang_raises_on_validation_error
    stub_api(:post, "/contacts", status: 422, body: {
      error: { code: "validation_failed", message: "Invalid", details: { first_name: ["can't be blank"] } }
    })

    error = assert_raises(GrayCRM::ValidationError) { GrayCRM::Contact.create!(first_name: "") }
    assert_equal({ "first_name" => ["can't be blank"] }, error.validation_errors)
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

  def test_save_new_record
    stub_api(:post, "/contacts", status: 201, body: {
      data: { id: "new-2", first_name: "Alice" }
    })

    contact = GrayCRM::Contact.new("first_name" => "Alice")
    assert contact.new_record?
    result = contact.save
    assert_equal contact, result
    assert_equal "new-2", contact.id
    assert contact.persisted?
  end

  def test_save_returns_false_on_validation_error
    stub_api(:patch, "/contacts/abc", status: 422, body: {
      error: { code: "validation_failed", message: "Invalid", details: { first_name: ["can't be blank"] } }
    })

    contact = GrayCRM::Contact.new("id" => "abc", "first_name" => "Jane")
    contact.first_name = ""
    result = contact.save
    assert_equal false, result
  end

  def test_save_bang_raises_with_original_error_details
    stub_api(:patch, "/contacts/abc", status: 422, body: {
      error: { code: "validation_failed", message: "Invalid", details: { first_name: ["can't be blank"] } }
    })

    contact = GrayCRM::Contact.new("id" => "abc", "first_name" => "Jane")
    contact.first_name = ""
    error = assert_raises(GrayCRM::ValidationError) { contact.save! }
    assert_equal({ "first_name" => ["can't be blank"] }, error.validation_errors)
  end

  def test_update_bang_raises_with_original_error_details
    stub_api(:patch, "/contacts/abc", status: 422, body: {
      error: { code: "validation_failed", message: "Invalid", details: { company: ["too long"] } }
    })

    contact = GrayCRM::Contact.new("id" => "abc")
    error = assert_raises(GrayCRM::ValidationError) { contact.update!(company: "x" * 300) }
    assert_equal({ "company" => ["too long"] }, error.validation_errors)
  end

  # --- errors accessor ---

  def test_errors_returns_empty_hash_by_default
    contact = GrayCRM::Contact.new("id" => "abc")
    assert_equal({}, contact.errors)
  end

  def test_errors_returns_validation_details_after_failed_save
    stub_api(:patch, "/contacts/abc", status: 422, body: {
      error: { code: "validation_failed", message: "Invalid", details: { first_name: ["can't be blank"] } }
    })

    contact = GrayCRM::Contact.new("id" => "abc", "first_name" => "Jane")
    contact.first_name = ""
    contact.save
    assert_equal({ "first_name" => ["can't be blank"] }, contact.errors)
  end

  def test_errors_cleared_after_successful_save
    stub_api(:patch, "/contacts/abc", status: 422, body: {
      error: { code: "validation_failed", message: "Invalid", details: { first_name: ["can't be blank"] } }
    })

    contact = GrayCRM::Contact.new("id" => "abc", "first_name" => "Jane")
    contact.first_name = ""
    contact.save

    # Now stub a successful save
    stub_api(:patch, "/contacts/abc", body: {
      data: { id: "abc", first_name: "Janet" }
    })
    contact.first_name = "Janet"
    contact.save
    assert_equal({}, contact.errors)
  end

  # --- equality ---

  def test_equality_same_class_same_id
    a = GrayCRM::Contact.new("id" => "abc", "first_name" => "Jane")
    b = GrayCRM::Contact.new("id" => "abc", "first_name" => "Janet")
    assert_equal a, b
    assert a.eql?(b)
  end

  def test_equality_different_id
    a = GrayCRM::Contact.new("id" => "abc")
    b = GrayCRM::Contact.new("id" => "def")
    refute_equal a, b
  end

  def test_equality_nil_id_not_equal
    a = GrayCRM::Contact.new("first_name" => "Jane")
    b = GrayCRM::Contact.new("first_name" => "Jane")
    refute_equal a, b
  end

  def test_equality_different_class
    contact = GrayCRM::Contact.new("id" => "abc")
    property = GrayCRM::Property.new("id" => "abc")
    refute_equal contact, property
  end

  def test_hash_same_for_equal_objects
    a = GrayCRM::Contact.new("id" => "abc")
    b = GrayCRM::Contact.new("id" => "abc")
    assert_equal a.hash, b.hash

    # Works in a Set/Hash
    set = [a, b].uniq
    assert_equal 1, set.size
  end

  # --- to_param ---

  def test_to_param_returns_id
    contact = GrayCRM::Contact.new("id" => "abc-123")
    assert_equal "abc-123", contact.to_param
  end

  def test_to_param_returns_nil_for_new_record
    contact = GrayCRM::Contact.new("first_name" => "Jane")
    assert_nil contact.to_param
  end

  # --- find_by ---

  def test_find_by_returns_first_match
    stub_api(:get, "/contacts",
      body: { data: [{ id: "abc", first_name: "Jane" }], pagination: { total: 1 } })

    contact = GrayCRM::Contact.find_by(email_eq: "jane@example.com")
    assert_equal "abc", contact.id
    assert_equal "Jane", contact.first_name
  end

  def test_find_by_returns_nil_when_no_match
    stub_api(:get, "/contacts",
      body: { data: [], pagination: { total: 0 } })

    result = GrayCRM::Contact.find_by(email_eq: "nobody@example.com")
    assert_nil result
  end
end
