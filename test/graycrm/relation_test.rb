# frozen_string_literal: true

require "test_helper"

class GrayCRM::RelationTest < Minitest::Test
  include FakeServer

  def test_where_filters
    stub_api(:get, "/contacts",
      body: { data: [{ id: "1", first_name: "Jane" }], pagination: { total: 1 } })

    contacts = GrayCRM::Contact.where(first_name_cont: "Jane").to_a
    assert_equal 1, contacts.size
    assert_equal "Jane", contacts.first.first_name
  end

  def test_page_and_per
    stub = stub_api_with_query(:get, "/contacts",
      query: { "page" => "2", "per_page" => "10" },
      body: { data: [], pagination: { page: 2, per_page: 10, total: 50, total_pages: 5 } })

    collection = GrayCRM::Contact.page(2).per(10).collection
    assert_equal 0, collection.size
    assert_equal 50, collection.total
  end

  def test_cursor_pagination
    stub = stub_api_with_query(:get, "/contacts",
      query: { "cursor" => "abc123" },
      body: { data: [{ id: "1" }], pagination: { next_cursor: "def456", has_more: true } })

    collection = GrayCRM::Contact.cursor("abc123").collection
    assert_equal "def456", collection.next_cursor
    assert collection.has_more?
  end

  def test_flag_filter
    stub = stub_api_with_query(:get, "/contacts",
      query: { "flag_key" => "enrichment", "flag_value" => "pending" },
      body: { data: [], pagination: {} })

    GrayCRM::Contact.where(flag: { key: "enrichment", value: "pending" }).to_a
    assert_requested(stub)
  end

  def test_tag_filter
    stub = stub_api_with_query(:get, "/contacts",
      query: { "tag" => "vip,hot" },
      body: { data: [], pagination: {} })

    GrayCRM::Contact.where(tag: "vip,hot").to_a
    assert_requested(stub)
  end

  def test_enumerable
    stub_api_with_query(:get, "/contacts",
      query: {},
      body: { data: [{ id: "1" }, { id: "2" }], pagination: {} })

    ids = GrayCRM::Contact.all.map(&:id)
    assert_equal %w[1 2], ids
  end

  def test_chaining_is_immutable
    base = GrayCRM::Contact.where(first_name_cont: "Jane")
    filtered = base.where(company_eq: "Acme")

    refute_equal base.object_id, filtered.object_id
  end
end
