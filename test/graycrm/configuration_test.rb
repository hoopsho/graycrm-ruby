# frozen_string_literal: true

require "test_helper"

class GrayCRM::ConfigurationTest < Minitest::Test
  def setup
    GrayCRM.reset!
  end

  def teardown
    GrayCRM.configure do |c|
      c.host = "acme.graycrm.io"
      c.api_key = "gcrm_live_test_token"
    end
  end

  def test_configure_sets_host_and_api_key
    GrayCRM.configure do |c|
      c.host = "test.graycrm.io"
      c.api_key = "gcrm_live_abc123"
    end

    assert_equal "test.graycrm.io", GrayCRM.configuration.host
    assert_equal "gcrm_live_abc123", GrayCRM.configuration.api_key
  end

  def test_base_url
    GrayCRM.configure do |c|
      c.host = "demo.graycrm.io"
      c.api_key = "gcrm_live_test"
    end

    assert_equal "https://demo.graycrm.io/api/v1", GrayCRM.configuration.base_url
  end

  def test_validate_raises_without_host
    GrayCRM.configure do |c|
      c.api_key = "gcrm_live_test"
    end

    assert_raises(GrayCRM::ConfigurationError) { GrayCRM.configuration.validate! }
  end

  def test_validate_raises_without_api_key
    GrayCRM.configure do |c|
      c.host = "test.graycrm.io"
    end

    assert_raises(GrayCRM::ConfigurationError) { GrayCRM.configuration.validate! }
  end

  def test_defaults
    config = GrayCRM::Configuration.new
    assert_equal 30, config.timeout
    assert_equal 10, config.open_timeout
    assert_equal 25, config.per_page
    assert_nil config.logger
  end

  def test_with_config_overrides_thread_local
    GrayCRM.configure do |c|
      c.host = "original.graycrm.io"
      c.api_key = "gcrm_live_original"
    end

    GrayCRM.with_config(host: "override.graycrm.io", api_key: "gcrm_live_override") do
      config = Thread.current[:graycrm_config]
      assert_equal "override.graycrm.io", config.host
      assert_equal "gcrm_live_override", config.api_key
    end

    # Verify cleanup
    assert_nil Thread.current[:graycrm_config]
  end
end
