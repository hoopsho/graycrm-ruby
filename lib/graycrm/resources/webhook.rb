# frozen_string_literal: true

module GrayCRM
  class Webhook < Resource
    self.resource_path = "/webhooks"

    attribute :id, :url, :events, :active, :secret,
              :consecutive_failures, :created_at, :updated_at

    def test!
      GrayCRM.client.post("#{instance_path}/test")
      true
    end
  end
end
