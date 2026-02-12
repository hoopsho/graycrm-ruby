# frozen_string_literal: true

module GrayCRM
  class Activity < Resource
    self.resource_path = "/activities"

    attribute :id, :activity_type, :subject, :body, :occurred_at,
              :activitable_type, :activitable_id, :created_at, :updated_at
  end
end
