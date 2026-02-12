# frozen_string_literal: true

module GrayCRM
  class Tag < Resource
    self.resource_path = "/tags"

    attribute :id, :name, :created_at, :updated_at
  end
end
