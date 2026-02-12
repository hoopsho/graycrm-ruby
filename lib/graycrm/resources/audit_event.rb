# frozen_string_literal: true

module GrayCRM
  class AuditEvent < Resource
    self.resource_path = "/audit_events"

    attribute :id, :action, :auditable_type, :auditable_id,
              :changes, :performed_by_type, :performed_by_id, :created_at
  end
end
