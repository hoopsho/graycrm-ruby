# frozen_string_literal: true

module GrayCRM
  class ContactProperty < Resource
    self.resource_path = "/contact_properties"

    attribute :id, :contact_id, :property_id, :role,
              :created_at, :updated_at
  end
end
