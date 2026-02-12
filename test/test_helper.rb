# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "graycrm"
require "minitest/autorun"
require "webmock/minitest"
require_relative "support/fake_server"

GrayCRM.configure do |c|
  c.host = "acme.graycrm.io"
  c.api_key = "gcrm_live_test_token"
end

WebMock.disable_net_connect!
