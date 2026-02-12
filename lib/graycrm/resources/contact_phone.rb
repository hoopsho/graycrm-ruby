# frozen_string_literal: true

module GrayCRM
  class ContactPhone < Resource
    self.resource_path = "/contact_phones"

    attribute :id, :phone, :label, :primary, :contact_id,
              :created_at, :updated_at
  end
end
