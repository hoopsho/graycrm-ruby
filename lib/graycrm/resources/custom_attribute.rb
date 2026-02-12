# frozen_string_literal: true

module GrayCRM
  class CustomAttribute < Resource
    self.resource_path = "/custom_attributes"

    attribute :id, :key, :value, :attributable_type, :attributable_id,
              :created_at, :updated_at
  end
end
