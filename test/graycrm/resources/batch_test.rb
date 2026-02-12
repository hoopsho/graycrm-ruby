# frozen_string_literal: true

require "test_helper"

class GrayCRM::BatchTest < Minitest::Test
  include FakeServer

  def test_execute_batch
    stub_api(:post, "/batch", body: {
      data: [
        { index: 0, status: 201, data: { id: "c1" } },
        { index: 1, status: 200, data: { id: "c2" } }
      ]
    })

    results = GrayCRM::Batch.execute([
      { method: "POST", resource: "contacts", body: { first_name: "John" } },
      { method: "PATCH", resource: "contacts", id: "c2", body: { company: "Acme" } }
    ])

    assert_equal 2, results.size
    assert_equal 201, results[0].status
    assert_equal "c1", results[0].data["id"]
  end
end
