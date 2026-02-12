# frozen_string_literal: true

module GrayCRM
  class Note < Resource
    self.resource_path = "/notes"

    attribute :id, :body, :notable_type, :notable_id, :author_id,
              :created_at, :updated_at
  end
end
