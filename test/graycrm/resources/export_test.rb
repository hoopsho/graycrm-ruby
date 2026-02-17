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

  # --- wait_until_complete! ---

  def test_wait_until_complete_returns_on_completed
    call_count = 0
    stub_request(:get, /exports\/exp1/)
      .to_return do |_request|
        call_count += 1
        status = call_count >= 2 ? "completed" : "processing"
        {
          status: 200,
          body: { data: { id: "exp1", status: status, total_rows: 50, download_url: "https://example.com/dl" } }.to_json,
          headers: { "Content-Type" => "application/json" }
        }
      end

    export = GrayCRM::Export.new("id" => "exp1", "status" => "pending")
    result = export.wait_until_complete!(timeout: 10, interval: 0)
    assert_same export, result
    assert export.completed?
    assert_equal 2, call_count
  end

  def test_wait_until_complete_returns_on_failed
    stub_api(:get, "/exports/exp1", body: {
      data: { id: "exp1", status: "failed", total_rows: 0 }
    })

    export = GrayCRM::Export.new("id" => "exp1", "status" => "processing")
    result = export.wait_until_complete!(timeout: 10, interval: 0)
    assert_same export, result
    assert export.failed?
  end

  def test_wait_until_complete_raises_on_timeout
    stub_api(:get, "/exports/exp1", body: {
      data: { id: "exp1", status: "processing", total_rows: 0 }
    })

    export = GrayCRM::Export.new("id" => "exp1", "status" => "pending")
    error = assert_raises(GrayCRM::Error) { export.wait_until_complete!(timeout: 0, interval: 0) }
    assert_match(/timed out/, error.message)
  end
end
