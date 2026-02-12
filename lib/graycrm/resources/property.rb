# frozen_string_literal: true

module GrayCRM
  class Property < Resource
    self.resource_path = "/properties"

    attribute :id, :name, :street, :city, :state, :zip, :country,
              :latitude, :longitude, :source, :source_detail,
              :created_at, :updated_at

    has_many :contacts, class_name: "ContactProperty", path: "contact_properties"
    has_many :tags, class_name: "Tag", path: "taggings"
    has_many :flags, class_name: "Flag"
    has_many :notes, class_name: "Note"
    has_many :custom_attributes, class_name: "CustomAttribute"
    has_many :audit_events, class_name: "AuditEvent"
  end
end
