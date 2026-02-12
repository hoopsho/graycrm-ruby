# frozen_string_literal: true

module GrayCRM
  class ContactEmail < Resource
    self.resource_path = "/contact_emails"

    attribute :id, :email, :label, :primary, :contact_id,
              :created_at, :updated_at
  end
end
