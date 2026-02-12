# frozen_string_literal: true

require "test_helper"

class GrayCRM::ExportTest < Minitest::Test
  include FakeServer

  def test_create_export
    stub_api(:post, "/exports", status: 201, body: {
      data: { id: "exp1", resource_type: "Contact", status: "pending", total_rows: 0 }
    })

    export = GrayCRM::Export.create(resource_type: "Contact")
    assert_equal "pending", export.status
    assert export.pending?
    refute export.completed?
  end

  def test_reload_for_status
    stub_api(:get, "/exports/exp1", body: {
      data: { id: "exp1", status: "completed", total_rows: 100, download_url: "https://example.com/dl" }
    })

    export = GrayCRM::Export.new("id" => "exp1", "status" => "processing")
    export.reload
    assert export.completed?
    assert_equal 100, export.total_rows
    assert_equal "https://example.com/dl", export.download_url
  end
end
