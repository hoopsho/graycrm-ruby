# frozen_string_literal: true

module GrayCRM
  class Flag < Resource
    self.resource_path = "/flags"

    attribute :id, :key, :value, :claimed_at, :claimed_by_id,
              :flaggable_type, :flaggable_id, :created_at, :updated_at

    def claim!
      # Expects to be accessed via nested path: /contacts/:id/flags/:id/claim
      # The caller must provide the full path context
      path = "#{self.class.resource_path}/#{id}/claim"
      GrayCRM.client.post(path)
      reload
    end
  end
end
