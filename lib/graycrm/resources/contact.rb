# frozen_string_literal: true

module GrayCRM
  class Contact < Resource
    self.resource_path = "/contacts"

    attribute :id, :first_name, :last_name, :company,
              :source, :source_detail, :created_at, :updated_at

    has_many :emails, class_name: "ContactEmail", path: "contact_emails"
    has_many :phones, class_name: "ContactPhone", path: "contact_phones"
    has_many :tags, class_name: "Tag", path: "taggings"
    has_many :flags, class_name: "Flag"
    has_many :notes, class_name: "Note"
    has_many :activities, class_name: "Activity"
    has_many :custom_attributes, class_name: "CustomAttribute"
    has_many :properties, class_name: "ContactProperty", path: "contact_properties"
    has_many :audit_events, class_name: "AuditEvent"

    # Computed from nested resources — primary email/phone take precedence
    # over the raw API attributes (which may be nil).
    def email
      embedded = (@attributes["emails"] || []).find { |e| e["primary"] }
      embedded&.dig("email") || @attributes["email"]
    end

    def phone
      embedded = (@attributes["phones"] || []).find { |p| p["primary"] }
      embedded&.dig("phone") || @attributes["phone"]
    end

    def merge(loser_id:)
      response = GrayCRM.client.post("#{self.class.resource_path}/#{id}/merge",
        body: { merge: { loser_id: loser_id } })
      data = response.is_a?(Hash) && response["data"] ? response["data"] : response
      @attributes.merge!(data)
      self
    end

    def self.duplicates
      response = GrayCRM.client.get("#{resource_path}/duplicates")
      data = response["data"] || []
      data.map do |group|
        {
          match_type: group["match_type"],
          match_detail: group["match_detail"],
          contacts: (group["contacts"] || []).map { |c| new(c) }
        }
      end
    end
  end
end
