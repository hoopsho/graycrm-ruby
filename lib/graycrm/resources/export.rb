# frozen_string_literal: true

module GrayCRM
  class Export < Resource
    self.resource_path = "/exports"

    attribute :id, :resource_type, :status, :total_rows,
              :query_params, :download_url, :created_at, :updated_at

    def completed?
      status == "completed"
    end

    def failed?
      status == "failed"
    end

    def pending?
      status == "pending"
    end

    def processing?
      status == "processing"
    end
  end
end
