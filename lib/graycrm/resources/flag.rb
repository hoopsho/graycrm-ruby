# frozen_string_literal: true

module GrayCRM
  class Flag < Resource
    self.resource_path = "/flags"

    attribute :id, :key, :value, :claimed_at, :claimed_by_id,
              :flaggable_type, :flaggable_id, :created_at, :updated_at

    def claim!
      GrayCRM.client.post("#{instance_path}/claim")
      reload
    end
  end
end
