# frozen_string_literal: true

require "test_helper"

class GrayCRM::SearchTest < Minitest::Test
  include FakeServer

  def test_global_search
    stub_api_with_query(:get, "/search",
      query: { "q" => "John" },
      body: {
        data: {
          contacts: [{ id: "c1", first_name: "John" }],
          properties: [],
          tags: []
        },
        meta: { query: "John", total_count: 1 }
      })

    result = GrayCRM::Search.query("John")
    assert_equal 1, result.contacts.size
    assert_kind_of GrayCRM::Contact, result.contacts.first
    assert_equal 1, result.total_count
  end
end
