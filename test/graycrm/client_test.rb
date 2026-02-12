# frozen_string_literal: true

require "test_helper"

class GrayCRM::ClientTest < Minitest::Test
  include FakeServer

  def test_get_with_auth_header
    stub_request(:get, /contacts/)
      .with(headers: {
        "Authorization" => "Bearer gcrm_live_test_token",
        "Accept" => "application/json"
      })
      .to_return(status: 200, body: { data: [] }.to_json, headers: { "Content-Type" => "application/json" })

    GrayCRM.client.get("/contacts")
  end

  def test_post_with_json_body
    stub = stub_api(:post, "/contacts", status: 201, body: { data: { id: "abc" } })

    result = GrayCRM.client.post("/contacts", body: { contact: { first_name: "Jane" } })

    assert_equal "abc", result["data"]["id"]
    assert_requested(stub)
  end

  def test_patch_request
    stub = stub_api(:patch, "/contacts/abc", body: { data: { id: "abc", first_name: "Janet" } })

    result = GrayCRM.client.patch("/contacts/abc", body: { contact: { first_name: "Janet" } })

    assert_equal "Janet", result["data"]["first_name"]
    assert_requested(stub)
  end

  def test_delete_request
    stub = stub_request(:delete, %r{contacts/abc})
      .to_return(status: 204, body: "")

    GrayCRM.client.delete("/contacts/abc")
    assert_requested(stub)
  end

  def test_raises_authentication_error_on_401
    stub_api(:get, "/contacts", status: 401, body: { error: { code: "unauthorized", message: "Invalid API key." } })

    assert_raises(GrayCRM::AuthenticationError) { GrayCRM.client.get("/contacts") }
  end

  def test_raises_forbidden_error_on_403
    stub_api(:get, "/contacts", status: 403, body: { error: { code: "forbidden", message: "Nope" } })

    assert_raises(GrayCRM::ForbiddenError) { GrayCRM.client.get("/contacts") }
  end

  def test_raises_not_found_on_404
    stub_api(:get, "/contacts/missing", status: 404, body: { error: { code: "not_found", message: "Not found" } })

    assert_raises(GrayCRM::NotFoundError) { GrayCRM.client.get("/contacts/missing") }
  end

  def test_raises_validation_error_on_422
    stub_api(:post, "/contacts", status: 422, body: {
      error: { code: "validation_failed", message: "Invalid", details: { first_name: ["can't be blank"] } }
    })

    error = assert_raises(GrayCRM::ValidationError) { GrayCRM.client.post("/contacts", body: {}) }
    assert_equal({ "first_name" => ["can't be blank"] }, error.validation_errors)
  end

  def test_raises_rate_limit_error_on_429
    stub_api(:get, "/contacts", status: 429,
      body: { error: { code: "rate_limit_exceeded", message: "Too fast" } },
      headers: { "Retry-After" => "60" })

    error = assert_raises(GrayCRM::RateLimitError) { GrayCRM.client.get("/contacts") }
    assert_equal 60, error.retry_after
  end

  def test_raises_server_error_on_500
    stub_api(:get, "/contacts", status: 500, body: { error: { message: "Internal error" } })

    assert_raises(GrayCRM::ServerError) { GrayCRM.client.get("/contacts") }
  end

  def test_raises_conflict_on_409
    stub_api(:post, "/contacts/abc/flags/f1/claim", status: 409,
      body: { error: { code: "conflict", message: "Already claimed" } })

    assert_raises(GrayCRM::ConflictError) { GrayCRM.client.post("/contacts/abc/flags/f1/claim") }
  end

  def test_get_with_query_params
    stub = stub_request(:get, "https://acme.graycrm.io/api/v1/contacts")
      .with(query: { "q[first_name_cont]" => "Jane" })
      .to_return(status: 200, body: { data: [] }.to_json, headers: { "Content-Type" => "application/json" })

    GrayCRM.client.get("/contacts", params: { "q[first_name_cont]" => "Jane" })
    assert_requested(stub)
  end

  def test_idempotency_key_header
    stub = stub_request(:post, /contacts/)
      .with(headers: { "Idempotency-Key" => "unique-123" })
      .to_return(status: 201, body: { data: { id: "abc" } }.to_json, headers: { "Content-Type" => "application/json" })

    GrayCRM.client.post("/contacts", body: { contact: {} }, headers: { "Idempotency-Key" => "unique-123" })
    assert_requested(stub)
  end
end
