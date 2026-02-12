# frozen_string_literal: true

require "test_helper"

class GrayCRM::WebhookTest < Minitest::Test
  include FakeServer

  def test_list
    stub_api(:get, "/webhooks", body: {
      data: [{ id: "w1", url: "https://example.com/hook", events: ["contact.created"], active: true }]
    })

    webhooks = GrayCRM::Webhook.all.to_a
    assert_equal 1, webhooks.size
    assert_equal "https://example.com/hook", webhooks.first.url
  end

  def test_create_returns_secret
    stub_api(:post, "/webhooks", status: 201, body: {
      data: { id: "w2", url: "https://new.example.com", secret: "whsec_abc123" }
    })

    webhook = GrayCRM::Webhook.create(url: "https://new.example.com", events: ["contact.created"])
    assert_equal "whsec_abc123", webhook.secret
  end

  def test_test_delivery
    stub_api(:post, "/webhooks/w1/test", status: 202, body: {})

    webhook = GrayCRM::Webhook.new("id" => "w1")
    assert webhook.test!
  end
end
