# frozen_string_literal: true

require "test_helper"

class GrayCRM::ContactTest < Minitest::Test
  include FakeServer

  def test_duplicates
    stub_api(:get, "/contacts/duplicates", body: {
      data: [
        {
          match_type: "email",
          match_detail: "jane@example.com",
          contacts: [
            { id: "1", first_name: "Jane" },
            { id: "2", first_name: "J." }
          ]
        }
      ]
    })

    groups = GrayCRM::Contact.duplicates
    assert_equal 1, groups.size
    assert_equal "email", groups.first[:match_type]
    assert_equal 2, groups.first[:contacts].size
    assert_kind_of GrayCRM::Contact, groups.first[:contacts].first
  end

  def test_merge
    stub_api(:get, "/contacts/winner-1", body: { data: { id: "winner-1", first_name: "Jane" } })
    stub_api(:post, "/contacts/winner-1/merge", body: {
      data: { id: "winner-1", first_name: "Jane", last_name: "Doe" }
    })

    contact = GrayCRM::Contact.find("winner-1")
    contact.merge(loser_id: "loser-1")
    assert_equal "Doe", contact.last_name
  end

  def test_nested_emails
    stub_api(:get, "/contacts/abc/contact_emails", body: {
      data: [{ id: "e1", email: "jane@example.com", label: "work", primary: true }],
      pagination: {}
    })

    contact = GrayCRM::Contact.new("id" => "abc")
    emails = contact.emails.to_a
    assert_equal 1, emails.size
    assert_equal "jane@example.com", emails.first.email
  end

  def test_nested_flags
    stub_api(:get, "/contacts/abc/flags", body: {
      data: [{ id: "f1", key: "enrichment", value: "pending" }],
      pagination: {}
    })

    contact = GrayCRM::Contact.new("id" => "abc")
    flags = contact.flags.to_a
    assert_equal "enrichment", flags.first.key
  end

  def test_create_nested_email
    stub_api(:post, "/contacts/abc/contact_emails", status: 201, body: {
      data: { id: "e2", email: "new@example.com", label: "home" }
    })

    contact = GrayCRM::Contact.new("id" => "abc")
    email = contact.emails.create(email: "new@example.com", label: "home")
    assert_equal "new@example.com", email.email
  end

  # --- Nested resource path context tests ---

  def test_nested_flag_retains_base_path
    stub_api(:get, "/contacts/abc/flags", body: {
      data: [{ id: "f1", key: "enrichment", value: "pending" }],
      pagination: {}
    })

    contact = GrayCRM::Contact.new("id" => "abc")
    flag = contact.flags.to_a.first
    assert_equal "/contacts/abc/flags", flag._base_path
  end

  def test_nested_flag_claim_uses_nested_path
    stub_api(:get, "/contacts/abc/flags", body: {
      data: [{ id: "f1", key: "enrichment", value: "pending" }],
      pagination: {}
    })
    claim_stub = stub_request(:post, "https://acme.graycrm.io/api/v1/contacts/abc/flags/f1/claim")
      .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://acme.graycrm.io/api/v1/contacts/abc/flags/f1")
      .to_return(status: 200, body: { data: { id: "f1", key: "enrichment", value: "claimed" } }.to_json,
                 headers: { "Content-Type" => "application/json" })

    contact = GrayCRM::Contact.new("id" => "abc")
    flag = contact.flags.to_a.first
    flag.claim!
    assert_requested(claim_stub)
    assert_equal "claimed", flag.value
  end

  def test_nested_flag_update_uses_nested_path
    stub_api(:get, "/contacts/abc/flags", body: {
      data: [{ id: "f1", key: "enrichment", value: "pending" }],
      pagination: {}
    })
    patch_stub = stub_request(:patch, "https://acme.graycrm.io/api/v1/contacts/abc/flags/f1")
      .to_return(status: 200, body: { data: { id: "f1", key: "enrichment", value: "completed" } }.to_json,
                 headers: { "Content-Type" => "application/json" })

    contact = GrayCRM::Contact.new("id" => "abc")
    flag = contact.flags.to_a.first
    flag.update(value: "completed")
    assert_requested(patch_stub)
  end

  def test_nested_flag_destroy_uses_nested_path
    stub_api(:get, "/contacts/abc/flags", body: {
      data: [{ id: "f1", key: "enrichment", value: "pending" }],
      pagination: {}
    })
    delete_stub = stub_request(:delete, "https://acme.graycrm.io/api/v1/contacts/abc/flags/f1")
      .to_return(status: 204, body: "", headers: { "Content-Type" => "application/json" })

    contact = GrayCRM::Contact.new("id" => "abc")
    flag = contact.flags.to_a.first
    flag.destroy
    assert_requested(delete_stub)
  end

  def test_created_nested_email_retains_base_path
    stub_api(:post, "/contacts/abc/contact_emails", status: 201, body: {
      data: { id: "e2", email: "new@example.com", label: "home" }
    })

    contact = GrayCRM::Contact.new("id" => "abc")
    email = contact.emails.create(email: "new@example.com", label: "home")
    assert_equal "/contacts/abc/contact_emails", email._base_path
  end
end
