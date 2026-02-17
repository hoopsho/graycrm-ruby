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

    base_filters = base.instance_variable_get(:@filters)
    filtered_filters = filtered.instance_variable_get(:@filters)

    assert_equal({ first_name_cont: "Jane" }, base_filters)
    assert_equal({ first_name_cont: "Jane", company_eq: "Acme" }, filtered_filters)
    refute_equal base_filters.object_id, filtered_filters.object_id
  end

  # --- per_page not sent when unset ---

  def test_per_page_not_sent_when_unset
    stub = stub_request(:get, "https://acme.graycrm.io/api/v1/contacts")
      .with { |req| !req.uri.query&.include?("per_page") }
      .to_return(
        status: 200,
        body: { data: [{ id: "1" }], pagination: {} }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    GrayCRM::Contact.all.to_a
    assert_requested(stub)
  end

  def test_per_page_sent_when_explicitly_set
    stub = stub_api_with_query(:get, "/contacts",
      query: { "per_page" => "10" },
      body: { data: [], pagination: {} })

    GrayCRM::Contact.per(10).to_a
    assert_requested(stub)
  end

  # --- Auto-pagination tests ---

  def test_next_page_with_cursor
    stub_api_with_query(:get, "/contacts",
      query: { "cursor" => "page1" },
      body: { data: [{ id: "1" }], pagination: { next_cursor: "page2", has_more: true } })

    stub_api_with_query(:get, "/contacts",
      query: { "cursor" => "page2" },
      body: { data: [{ id: "2" }], pagination: { next_cursor: nil, has_more: false } })

    page1 = GrayCRM::Contact.cursor("page1").collection
    assert_equal %w[1], page1.map(&:id)
    assert page1.has_more?

    page2 = page1.next_page
    assert_equal %w[2], page2.map(&:id)
    refute page2.has_more?

    assert_nil page2.next_page
  end

  def test_next_page_with_offset
    stub_api_with_query(:get, "/contacts",
      query: { "page" => "1", "per_page" => "2" },
      body: { data: [{ id: "1" }, { id: "2" }], pagination: { page: 1, per_page: 2, total: 4, total_pages: 2 } })

    stub_api_with_query(:get, "/contacts",
      query: { "page" => "2", "per_page" => "2" },
      body: { data: [{ id: "3" }, { id: "4" }], pagination: { page: 2, per_page: 2, total: 4, total_pages: 2 } })

    page1 = GrayCRM::Contact.page(1).per(2).collection
    assert_equal %w[1 2], page1.map(&:id)

    page2 = page1.next_page
    assert_equal %w[3 4], page2.map(&:id)

    assert_nil page2.next_page
  end

  def test_each_page_iterates_all_pages
    stub_api_with_query(:get, "/contacts",
      query: { "cursor" => "start" },
      body: { data: [{ id: "1" }], pagination: { next_cursor: "mid", has_more: true } })

    stub_api_with_query(:get, "/contacts",
      query: { "cursor" => "mid" },
      body: { data: [{ id: "2" }], pagination: { next_cursor: "end", has_more: true } })

    stub_api_with_query(:get, "/contacts",
      query: { "cursor" => "end" },
      body: { data: [{ id: "3" }], pagination: { next_cursor: nil, has_more: false } })

    all_ids = []
    GrayCRM::Contact.cursor("start").collection.each_page do |page|
      all_ids.concat(page.map(&:id))
    end

    assert_equal %w[1 2 3], all_ids
  end

  def test_each_page_returns_enumerator
    stub_api_with_query(:get, "/contacts",
      query: { "cursor" => "only" },
      body: { data: [{ id: "1" }], pagination: { next_cursor: nil, has_more: false } })

    enum = GrayCRM::Contact.cursor("only").collection.each_page
    assert_kind_of Enumerator, enum
  end
end
