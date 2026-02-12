# frozen_string_literal: true

module FakeServer
  BASE_URL = "https://acme.graycrm.io/api/v1"

  # Stubs an API request. Uses regex URL matching to allow any query params.
  def stub_api(method, path, status: 200, body: {}, headers: {})
    url_pattern = %r{#{Regexp.escape(BASE_URL + path)}(\?.*)?$}
    response_body = body.is_a?(String) ? body : body.to_json
    stub_request(method, url_pattern)
      .to_return(
        status: status,
        body: response_body,
        headers: { "Content-Type" => "application/json" }.merge(headers)
      )
  end

  # Stubs with query matching — uses exact URL string (not regex) for WebMock compatibility.
  def stub_api_with_query(method, path, query:, status: 200, body: {})
    stub_request(method, "#{BASE_URL}#{path}")
      .with(query: hash_including(query))
      .to_return(
        status: status,
        body: body.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
