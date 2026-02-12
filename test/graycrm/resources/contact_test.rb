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
end
